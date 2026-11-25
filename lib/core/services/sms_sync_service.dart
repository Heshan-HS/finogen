import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../repositories/account_repository.dart';
import '../repositories/transaction_repository.dart';
import 'notification_service.dart';
import 'sms_parser_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsSyncState {
  final bool isSyncing;
  final bool hasPermission;
  final int lastSyncedCount;
  final String? lastStatusMessage;
  final DateTime? lastSyncTime;
  final String deviceWallet; // 'dialog' or 'airtel'
  final String deviceWalletSetting; // 'auto', 'dialog', or 'airtel'
  final String deviceModel;

  SmsSyncState({
    this.isSyncing = false,
    this.hasPermission = false,
    this.lastSyncedCount = 0,
    this.lastStatusMessage,
    this.lastSyncTime,
    this.deviceWallet = 'dialog',
    this.deviceWalletSetting = 'auto',
    this.deviceModel = '',
  });

  SmsSyncState copyWith({
    bool? isSyncing,
    bool? hasPermission,
    int? lastSyncedCount,
    String? lastStatusMessage,
    DateTime? lastSyncTime,
    String? deviceWallet,
    String? deviceWalletSetting,
    String? deviceModel,
  }) {
    return SmsSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      hasPermission: hasPermission ?? this.hasPermission,
      lastSyncedCount: lastSyncedCount ?? this.lastSyncedCount,
      lastStatusMessage: lastStatusMessage ?? this.lastStatusMessage,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      deviceWallet: deviceWallet ?? this.deviceWallet,
      deviceWalletSetting: deviceWalletSetting ?? this.deviceWalletSetting,
      deviceModel: deviceModel ?? this.deviceModel,
    );
  }
}

class SmsSyncNotifier extends Notifier<SmsSyncState> {
  static const MethodChannel _channel = MethodChannel('com.example.nova_finance/sms');
  bool _initialized = false;

  Future<void> refreshDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final setting = prefs.getString('ez_cash_device_wallet') ?? 'auto';
    String detected = 'dialog';
    String modelName = '';

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _channel.invokeMethod<Map>('getDeviceInfo');
        if (info != null) {
          final manufacturer = (info['manufacturer'] ?? '').toString().toUpperCase();
          final brand = (info['brand'] ?? '').toString().toUpperCase();
          final model = (info['model'] ?? '').toString().toUpperCase();
          final sim = (info['simOperator'] ?? '').toString().toUpperCase();
          modelName = '${info['manufacturer'] ?? ''} ${info['model'] ?? ''}'.trim();

          debugPrint('[SmsSyncService] Auto-detect device -> Mfr: $manufacturer, Model: $model, Brand: $brand, SIM: $sim');

          if (manufacturer.contains('INFINIX') || brand.contains('INFINIX') || model.contains('INFINIX') || sim.contains('AIRTEL')) {
            detected = 'airtel';
          } else if (manufacturer.contains('HUAWEI') || brand.contains('HUAWEI') || model.contains('PPA-LX2') || sim.contains('DIALOG')) {
            detected = 'dialog';
          }
        }
      }
    } catch (e) {
      debugPrint('[SmsSyncService] refreshDeviceInfo error: $e');
    }

    final active = (setting == 'dialog' || setting == 'airtel') ? setting : detected;
    state = state.copyWith(
      deviceWallet: active,
      deviceWalletSetting: setting,
      deviceModel: modelName.isNotEmpty ? modelName : (defaultTargetPlatform == TargetPlatform.android ? 'Android Device' : 'Desktop/Web'),
    );
  }

  Future<void> setDeviceWalletSetting(String newSetting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ez_cash_device_wallet', newSetting);
    await refreshDeviceInfo();
    await reconcileAccounts();
  }

  Future<String> getActiveDeviceWalletType() async {
    if (state.deviceWallet.isNotEmpty) {
      return state.deviceWallet;
    }
    await refreshDeviceInfo();
    return state.deviceWallet.isNotEmpty ? state.deviceWallet : 'dialog';
  }

  @override
  SmsSyncState build() {
    Future.delayed(const Duration(milliseconds: 2500), () => init());
    return SmsSyncState();
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      _channel.setMethodCallHandler(_handleNativeCall);
      final hasPerm = await checkPermission();
      state = state.copyWith(hasPermission: hasPerm);

      await refreshDeviceInfo();
      await reconcileAccounts();

      if (hasPerm) {
        await processPendingQueue();
        await syncPastSms(days: 180, limit: 500);
      }
    } catch (e) {
      debugPrint('[SmsSyncService] init error: $e');
    }
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onSmsReceived') {
      try {
        final args = Map<String, dynamic>.from(call.arguments);
        final sender = args['sender']?.toString() ?? '';
        final body = args['body']?.toString() ?? '';
        final ts = args['timestamp'] as int?;
        final date = ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : DateTime.now();

        await processSingleSms(sender: sender, body: body, timestamp: date, notify: true);
      } catch (e) {
        debugPrint('[SmsSyncService] onSmsReceived error: $e');
      }
    }
  }

  Future<bool> checkPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final res = await _channel.invokeMethod<bool>('checkPermission');
      final granted = res ?? false;
      state = state.copyWith(hasPermission: granted);
      return granted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      final res = await _channel.invokeMethod<bool>('requestPermission');
      final granted = res ?? false;
      state = state.copyWith(hasPermission: granted);
      if (granted) {
        await processPendingQueue();
      }
      return granted;
    } catch (_) {
      return false;
    }
  }

  /// Cleans up old accounts and ensures:
  /// 1. "Ez Cash Dialog New" (Primary SIM 1)
  /// 2. "Ez Cash (076 916 9810)" (Secondary Dialog SIM 2)
  /// 3. "Nations trust bank" (personal account)
  /// 4. "Nations Trust Bank Fathers Sallery" (Rs. 70,000 base + future Rs. 10,000 monthly standing instructions)
  Future<void> reconcileAccounts() async {
    try {
      final accRepo = ref.read(accountRepositoryProvider);
      final txRepo = ref.read(transactionRepositoryProvider);

      final accounts = await accRepo.getUserAccounts().first;
      if (accounts.isEmpty) return;

      // Locate "Nations Trust Bank Fathers Sallery"
      AccountModel? fathersSalaryAcc = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && (
          a.name.toLowerCase().contains('father') ||
          a.name.toLowerCase().contains('sallery') ||
          a.name.toLowerCase().contains('salary')
        ),
        orElse: () => null,
      );

      // Locate "Nations trust bank" (strictly personal account, excluding fathers salary)
      AccountModel? nationsAcc = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && (
          a.name.toLowerCase().contains('nation') || a.name.toLowerCase().contains('ntb')
        ) && !a.name.toLowerCase().contains('father') &&
            !a.name.toLowerCase().contains('sall') &&
            !a.name.toLowerCase().contains('sala'),
        orElse: () => null,
      );

      // Locate "Ez Cash (Airtel)" (Secondary SIM / Airtel)
      AccountModel? ezCashSim2Acc = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && (
          a.name.toLowerCase().contains('airtel') ||
          a.name.contains('769169810') ||
          a.name.contains('076 916 9810') ||
          a.name.toLowerCase().contains('sim 2') ||
          a.name.toLowerCase().contains('sim2')
        ),
        orElse: () => null,
      );

      // Locate "Ez Cash (Dialog)" (Primary SIM / Dialog)
      AccountModel? ezCashDialogNewAcc = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && (
          a.name.toLowerCase().contains('dialog') ||
          a.name.toLowerCase() == 'ez cash dialog' ||
          a.name.toLowerCase() == 'ez cash dialog new'
        ),
        orElse: () => null,
      );
      if (ezCashDialogNewAcc == null) {
        ezCashDialogNewAcc = accounts.cast<AccountModel?>().firstWhere(
          (a) => a != null && a.name.toLowerCase().contains('ez') &&
                 !a.name.contains('769169810') &&
                 !a.name.contains('076 916 9810') &&
                 !a.name.toLowerCase().contains('sim 2') &&
                 !a.name.toLowerCase().contains('airtel') &&
                 !a.name.toLowerCase().contains('old'),
          orElse: () => null,
        );
      }

      // 1. Ensure Fathers Sallery strictly has base balance of Rs. 70,000.0 (covering past 7 months up to Oct 10, 2026)
      if (fathersSalaryAcc == null) {
        fathersSalaryAcc = AccountModel(
          id: const Uuid().v4(),
          userId: 'guest',
          name: 'Nations Trust Bank Fathers Sallery',
          type: AccountType.bank,
          balance: 70000.0,
          colorValue: 0xFF00D9A8,
          isEnabled: true,
        );
        await accRepo.addAccount(fathersSalaryAcc);
      } else {
        if (fathersSalaryAcc.balance != 70000.0 || !fathersSalaryAcc.isEnabled || fathersSalaryAcc.name != 'Nations Trust Bank Fathers Sallery') {
          fathersSalaryAcc = fathersSalaryAcc.copyWith(
            name: 'Nations Trust Bank Fathers Sallery',
            balance: 70000.0,
            isEnabled: true,
          );
          await accRepo.updateAccount(fathersSalaryAcc);
        }
      }

      // 2. Ensure Nations trust bank exists and is enabled
      if (nationsAcc == null) {
        nationsAcc = AccountModel(
          id: const Uuid().v4(),
          userId: 'guest',
          name: 'Nations trust bank',
          type: AccountType.bank,
          balance: 69504.99,
          colorValue: 0xFF007BFF,
          isEnabled: true,
        );
        await accRepo.addAccount(nationsAcc);
      }

      // 3. Ensure Ez Cash (Dialog) exists and is enabled
      if (ezCashDialogNewAcc == null) {
        ezCashDialogNewAcc = AccountModel(
          id: const Uuid().v4(),
          userId: 'guest',
          name: 'Ez Cash (Dialog)',
          type: AccountType.cash,
          balance: 548.0,
          colorValue: 0xFFFF9900,
          isEnabled: true,
        );
        await accRepo.addAccount(ezCashDialogNewAcc);
      } else {
        if (!ezCashDialogNewAcc.isEnabled || ezCashDialogNewAcc.name != 'Ez Cash (Dialog)') {
          ezCashDialogNewAcc = ezCashDialogNewAcc.copyWith(
            name: 'Ez Cash (Dialog)',
            isEnabled: true,
          );
          await accRepo.updateAccount(ezCashDialogNewAcc);
        }
      }

      // 4. Ensure Ez Cash (Airtel) exists and is enabled
      if (ezCashSim2Acc == null) {
        ezCashSim2Acc = AccountModel(
          id: const Uuid().v4(),
          userId: 'guest',
          name: 'Ez Cash (Airtel)',
          type: AccountType.cash,
          balance: 120.0,
          colorValue: 0xFF26A69A,
          isEnabled: true,
        );
        await accRepo.addAccount(ezCashSim2Acc);
      } else {
        // Guard: If corrupted by bank leak (> Rs 10,000), reset base to 120.0
        final double safeSim2Bal = ezCashSim2Acc.balance > 10000.0 ? 120.0 : ezCashSim2Acc.balance;
        if (!ezCashSim2Acc.isEnabled || ezCashSim2Acc.name != 'Ez Cash (Airtel)' || ezCashSim2Acc.balance != safeSim2Bal) {
          ezCashSim2Acc = ezCashSim2Acc.copyWith(
            name: 'Ez Cash (Airtel)',
            balance: safeSim2Bal,
            isEnabled: true,
          );
          await accRepo.updateAccount(ezCashSim2Acc);
        }
      }

      // Locate "GF BOC (Holding)"
      AccountModel? gfBocAcc = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && (
          a.name.toLowerCase().contains('boc') ||
          (a.name.toLowerCase().contains('gf') && a.name.toLowerCase().contains('holding'))
        ),
        orElse: () => null,
      );
      if (gfBocAcc == null) {
        gfBocAcc = AccountModel(
          id: const Uuid().v4(),
          userId: 'guest',
          name: 'GF BOC (Holding)',
          type: AccountType.bank,
          balance: 0.0,
          creditLimit: 0.0,
          colorValue: 0xFFFFB300,
          isEnabled: true,
          excludeFromTotal: true,
        );
        await accRepo.addAccount(gfBocAcc);
      }

      final preservedIds = {
        fathersSalaryAcc.id,
        nationsAcc.id,
        ezCashDialogNewAcc.id,
        ezCashSim2Acc.id,
        gfBocAcc.id,
      };

      // 5. Clean up only known old test accounts (NEVER delete GF BOC Holding or user accounts)
      for (var acc in accounts) {
        final lower = acc.name.toLowerCase();
        final isGfHolding = acc.excludeFromTotal || lower.contains('boc') || lower.contains('gf') || lower.contains('holding');
        if (isGfHolding) continue; // Absolutely protect GF BOC Holding account

        if (lower == 'airtel old' || lower == 'test dummy') {
          debugPrint('[SmsSyncService] Deleting obsolete test account: ${acc.name} (${acc.id})');
          await accRepo.deleteAccount(acc.id);
        }
      }

      // 6. Clean up transactions:
      final allTx = await txRepo.getUserTransactions().first;
      for (var tx in allTx) {
        if (tx.accountId == fathersSalaryAcc.id) {
          // Keep all Standing Instructions as historical income transactions
        } else if (tx.accountId == ezCashSim2Acc.id) {
          if (tx.note.toLowerCase().contains('test') ||
              tx.note.toLowerCase().contains('div') ||
              tx.note.toLowerCase().contains('ntb') ||
              tx.note.toLowerCase().contains('nations') ||
              tx.amount > 10000.0) {
            await txRepo.deleteTransaction(tx.id);
          }
        } else if (tx.accountId == gfBocAcc.id || tx.note.contains('(GF BOC)') || tx.note.toLowerCase().contains('gf boc')) {
          // Clean up old unreferenced October BOC entries to ensure the exact 3 verified Netcup clients are recorded
          if (tx.date.year == 2026 && tx.date.month == 10 && !(tx.externalRefId?.startsWith('BOC_202610') ?? false)) {
            await txRepo.deleteTransaction(tx.id);
          }
        } else if (!preservedIds.contains(tx.accountId)) {
          // Never delete transactions belonging to GF BOC Holding or holding payments
          final isGfTx = tx.note.contains('(GF BOC)') || tx.note.toLowerCase().contains('gf boc') || tx.categoryId == 'business_income';
          if (!isGfTx) {
            // Keep safe without indiscriminate deletion
          }
        }
      }

      // Ensure all incoming NTB/eZ Cash transactions after cutoff (except Father's salary) are categorized as NovaGen SpeedNet
      final DateTime novagenCutoffDate = DateTime(2026, 10, 17, 16, 0);
      for (var tx in allTx) {
        final noteLower = tx.note.toLowerCase();
        final bool isFather = tx.categoryId == 'inc_salary' ||
            noteLower.contains('father') ||
            noteLower.contains('standing instruction') ||
            (tx.amount - 10000.0).abs() < 1.0;

        // Re-tag past incoming transfers that were wrongly saved as inc_transfer
        if (tx.isIncome && tx.categoryId == 'inc_transfer' && !tx.note.toLowerCase().contains('self transfer')) {
          final isSalary = tx.note.toLowerCase().contains('standing instruction') || (tx.amount - 10000.0).abs() < 1.0;
          final updatedTx = tx.copyWith(
            categoryId: isSalary ? 'inc_salary' : 'inc_novagen',
          );
          await txRepo.updateTransaction(updatedTx);
          continue;
        }

        // Re-tag self-transfer of Rs 13,900 from eZ Cash to NTB as an internal transfer
        if (tx.amount == 13900.0) {
          final targetCat = tx.isIncome ? 'inc_transfer' : 'exp_transfer';
          final targetNote = tx.isIncome ? 'Self Transfer - eZ Cash to NTB' : 'Self Transfer - Out to NTB';
          if (tx.categoryId != targetCat) {
            final updatedTx = tx.copyWith(
              categoryId: targetCat,
              note: targetNote,
            );
            await txRepo.updateTransaction(updatedTx);
          }
          continue;
        }

        // Re-tag ATM Cash Withdrawals as internal transfer (not a real expense)
        final bool isAtm = !tx.isIncome && (
          noteLower.contains('atm') ||
          noteLower.contains('cash withdrawal')
        );
        if (isAtm) {
          if (tx.categoryId != 'exp_transfer') {
            final updatedTx = tx.copyWith(
              categoryId: 'exp_transfer',
              note: tx.note.startsWith('ATM Cash Withdrawal') ? tx.note : 'ATM Cash Withdrawal - ' + tx.note,
            );
            await txRepo.updateTransaction(updatedTx);
          }
          continue;
        }

        // Re-tag internal funds transfers between user accounts as exp_transfer
        final bool isInternalTransferOut = !tx.isIncome && (
          noteLower.contains('funds transfer') ||
          noteLower.contains('fund transfer') ||
          noteLower.contains('mudal yaweema to') ||
          noteLower.contains('self transfer')
        );
        if (isInternalTransferOut && tx.categoryId != 'exp_transfer') {
          final updatedTx = tx.copyWith(
            categoryId: 'exp_transfer',
          );
          await txRepo.updateTransaction(updatedTx);
          continue;
        }

        // Only real client packages (strictly <= Rs 600) are SpeedNet revenue
        if (!isFather && tx.isIncome && tx.amount <= 600.0 && tx.date.isAfter(novagenCutoffDate)) {
          if (tx.categoryId != 'inc_novagen' || !tx.note.startsWith('NovaGen SpeedNet')) {
            final updatedTx = tx.copyWith(
              categoryId: 'inc_novagen',
              note: tx.note.startsWith('NovaGen SpeedNet')
                  ? tx.note
                  : 'NovaGen SpeedNet - ' + tx.note,
            );
            await txRepo.updateTransaction(updatedTx);
          }
        }

        // Ensure Netcup Server VPS expenses (e.g. NTB MASTER DR CARD FOREIGN POS or Netcup) are categorized as exp_novagen_server
        final bool isNetcupServer = !tx.isIncome && (
          tx.categoryId == 'exp_novagen_server' ||
          noteLower.contains('foreign pos') ||
          noteLower.contains('netcup')
        );

        if (isNetcupServer) {
          final String targetNote = tx.note.startsWith('Netcup Server VPS Renewal')
              ? tx.note
              : 'Netcup Server VPS Renewal - ${tx.note}';
          if (tx.categoryId != 'exp_novagen_server' || tx.note != targetNote) {
            final updatedTx = tx.copyWith(
              categoryId: 'exp_novagen_server',
              note: targetNote,
            );
            await txRepo.updateTransaction(updatedTx);
          }
        }
      }

      // Ensure all 7 verified October eZ Cash client payments are recorded in the database
      final verifiedEzCashPayments = [
        {'date': DateTime(2026, 10, 2, 12, 0), 'amount': 270.0, 'note': 'NovaGen SpeedNet - eZ Cash (0771222852)', 'ref': 'EZC_20261002_270'},
        {'date': DateTime(2026, 10, 4, 12, 0), 'amount': 140.0, 'note': 'NovaGen SpeedNet - eZ Cash (Mega Pay)', 'ref': 'EZC_20261004_140'},
        {'date': DateTime(2026, 10, 7, 12, 0), 'amount': 490.0, 'note': 'NovaGen SpeedNet - eZ Cash (X YTEQ Comm)', 'ref': 'EZC_20261007_490'},
        {'date': DateTime(2026, 10, 7, 14, 0), 'amount': 520.0, 'note': 'NovaGen SpeedNet - eZ Cash (0771222852)', 'ref': 'EZC_20261007_520'},
        {'date': DateTime(2026, 10, 15, 12, 0), 'amount': 270.0, 'note': 'NovaGen SpeedNet - eZ Cash (Mega Pay)', 'ref': 'EZC_20261015_270'},
        {'date': DateTime(2026, 10, 15, 14, 0), 'amount': 540.0, 'note': 'NovaGen SpeedNet - eZ Cash (HHA.COM)', 'ref': 'EZC_20261015_540'},
        {'date': DateTime(2026, 10, 19, 12, 0), 'amount': 240.0, 'note': 'NovaGen SpeedNet - eZ Cash (Mega Pay)', 'ref': 'EZC_20261019_240'},
      ];

      for (var ep in verifiedEzCashPayments) {
        final amt = ep['amount'] as double;
        final d = ep['date'] as DateTime;
        final refId = ep['ref'] as String;
        final bool exists = allTx.any((t) => t.externalRefId == refId || ((t.amount - amt).abs() < 0.01 && t.date.year == d.year && t.date.month == d.month && t.date.day == d.day && t.isIncome));
        if (!exists) {
          final newEzTx = TransactionModel(
            id: const Uuid().v4(),
            userId: 'guest',
            accountId: ezCashDialogNewAcc.id,
            amount: amt,
            categoryId: 'inc_novagen',
            note: ep['note'] as String,
            date: d,
            isIncome: true,
            externalRefId: refId,
          );
          await txRepo.addTransaction(newEzTx);
        }
      }

      // Ensure all 3 verified October BOC client payments from Netcup are recorded under GF BOC Holding
      final verifiedBocPayments = [
        {'date': DateTime(2026, 10, 2, 12, 0), 'amount': 300.0, 'note': 'Client Payment (GF BOC) - sahan_0701075482', 'ref': 'BOC_20261002_300'},
        {'date': DateTime(2026, 10, 11, 12, 0), 'amount': 500.0, 'note': 'Client Payment (GF BOC) - Nisran 0773396788', 'ref': 'BOC_20261011_500'},
        {'date': DateTime(2026, 10, 16, 12, 0), 'amount': 500.0, 'note': 'Client Payment (GF BOC) - Linal_297_T_0724906656', 'ref': 'BOC_20261016_500'},
      ];

      final refreshedTxForBoc = await txRepo.getUserTransactions().first;
      for (var bp in verifiedBocPayments) {
        final amt = bp['amount'] as double;
        final d = bp['date'] as DateTime;
        final refId = bp['ref'] as String;
        final bool exists = refreshedTxForBoc.any((t) => t.externalRefId == refId);
        if (!exists) {
          final newBocTx = TransactionModel(
            id: const Uuid().v4(),
            userId: 'guest',
            accountId: gfBocAcc.id,
            amount: amt,
            categoryId: 'business_income',
            note: bp['note'] as String,
            date: d,
            isIncome: true,
            externalRefId: refId,
          );
          await txRepo.addTransaction(newBocTx);
        }
      }

      final String activeWallet = await getActiveDeviceWalletType();
      debugPrint('[SmsSyncService] Reconciling accounts on active device wallet: $activeWallet');

      // 7. Dynamically extract the latest known balances from SMS inbox
      double? latestNationsBankTotal;
      double? latestEzCashBalance;
      double? latestEzCashSim2Balance;

      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final rawList = await _channel.invokeListMethod<Map>('getInboxSms', {
            'limit': 100,
            'days': 60,
          });
          if (rawList != null) {
            for (var item in rawList) {
              final m = Map<String, dynamic>.from(item);
              final sender = m['sender']?.toString() ?? '';
              final body = m['body']?.toString() ?? '';
              final parsed = SmsParserService.parse(sender, body);
              if (parsed != null && parsed.currentBalance != null) {
                final normSender = sender.replaceAll(RegExp(r'[^0-9]'), '');
                final bool hasExplicitAirtel = normSender.contains('769169810') || sender.contains('769169810') || body.contains('769169810') || parsed.accountName.contains('769169810') || parsed.uniqueRefId.contains('SIM2') || sender.contains('9010');
                final bool isAirtelSms = activeWallet == 'airtel' || hasExplicitAirtel;

                final bool isNations = parsed.sender.toUpperCase().contains('NATIONS') ||
                                       parsed.sender.toUpperCase().contains('NTB') ||
                                       parsed.accountName.toLowerCase().contains('nation');

                final bool isEzCash = parsed.sender.toUpperCase().contains('EZ') ||
                                      parsed.sender.toUpperCase().contains('CASH') ||
                                      parsed.accountName.toLowerCase().contains('ez') ||
                                      parsed.rawSms.toLowerCase().contains('ez cash') ||
                                      hasExplicitAirtel;

                if (isNations) {
                  if (latestNationsBankTotal == null) {
                    latestNationsBankTotal = parsed.currentBalance;
                  }
                } else if (isEzCash) {
                  if (isAirtelSms && latestEzCashSim2Balance == null) {
                    latestEzCashSim2Balance = parsed.currentBalance;
                  } else if (!isAirtelSms && latestEzCashBalance == null) {
                    latestEzCashBalance = parsed.currentBalance;
                  }
                }
              }
              if (latestNationsBankTotal != null && (activeWallet == 'dialog' ? latestEzCashBalance != null : latestEzCashSim2Balance != null)) break;
            }
          }
        } catch (e) {
          debugPrint('[SmsSyncService] Querying latest inbox balance error: $e');
        }
      }

      final refreshedTx = await txRepo.getUserTransactions().first;

      // Compute current total Father's Money (70,000 base + any future standing instructions)
      final fathersTx = refreshedTx.where((t) => t.accountId == fathersSalaryAcc!.id);
      double fathersTxSum = 0;
      for (var t in fathersTx) {
        fathersTxSum += t.isIncome ? t.amount : -t.amount;
      }
      final double totalFathersMoney = fathersSalaryAcc.balance + fathersTxSum;

      // Personal Nations Money = latest bank total - total Father's money
      if (latestNationsBankTotal != null) {
        final double targetNationsDerived = (latestNationsBankTotal - totalFathersMoney).clamp(0.0, double.infinity);
        final nationsTx = refreshedTx.where((t) => t.accountId == nationsAcc!.id);
        double nationsTxSum = 0;
        for (var t in nationsTx) {
          nationsTxSum += t.isIncome ? t.amount : -t.amount;
        }
        final double calibratedNationsBase = targetNationsDerived - nationsTxSum;
        nationsAcc = nationsAcc.copyWith(
          name: 'Nations trust bank',
          balance: calibratedNationsBase,
          isEnabled: true,
        );
        await accRepo.updateAccount(nationsAcc);
      }

      // Calibrate Ez Cash (Dialog) base balance if Dialog is active on this device (e.g. Huawei)
      if (activeWallet == 'dialog') {
        final double targetEzDerived = latestEzCashBalance ?? 548.0;
        final ezTx = refreshedTx.where((t) => t.accountId == ezCashDialogNewAcc!.id);
        double ezTxSum = 0;
        for (var t in ezTx) {
          ezTxSum += t.isIncome ? t.amount : -t.amount;
        }
        final double calibratedEzBase = targetEzDerived - ezTxSum;
        ezCashDialogNewAcc = ezCashDialogNewAcc.copyWith(
          name: 'Ez Cash (Dialog)',
          balance: calibratedEzBase,
          isEnabled: true,
        );
        await accRepo.updateAccount(ezCashDialogNewAcc);
      }

      // Calibrate Ez Cash (Airtel) base balance ONLY if Airtel is active on this device (e.g. Infinix)
      if (activeWallet == 'airtel') {
        final double targetSim2 = (latestEzCashSim2Balance != null && latestEzCashSim2Balance < 10000.0)
            ? latestEzCashSim2Balance
            : 120.0;
        final sim2Tx = refreshedTx.where((t) => t.accountId == ezCashSim2Acc!.id);
        double sim2TxSum = 0;
        for (var t in sim2Tx) {
          sim2TxSum += t.isIncome ? t.amount : -t.amount;
        }
        final double calibratedSim2Base = targetSim2 - sim2TxSum;
        ezCashSim2Acc = ezCashSim2Acc.copyWith(
          name: 'Ez Cash (Airtel)',
          balance: calibratedSim2Base,
          isEnabled: true,
        );
        await accRepo.updateAccount(ezCashSim2Acc);
      }

      debugPrint('[SmsSyncService] Reconciled balances -> Nations Personal: ${nationsAcc.balance}, eZ Cash Dialog: ${ezCashDialogNewAcc.balance}, eZ Cash Airtel: ${ezCashSim2Acc.balance}, Fathers Total: $totalFathersMoney');
    } catch (e) {
      debugPrint('[SmsSyncService] reconcileAccounts error: $e');
    }
  }

  Future<void> processPendingQueue() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final list = await _channel.invokeListMethod<Map>('getPendingSms');
      if (list != null && list.isNotEmpty) {
        int added = 0;
        for (var item in list) {
          final m = Map<String, dynamic>.from(item);
          final sender = m['sender']?.toString() ?? '';
          final body = m['body']?.toString() ?? '';
          final ts = m['timestamp'] as int?;
          final date = ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : DateTime.now();

          final success = await processSingleSms(sender: sender, body: body, timestamp: date, notify: true);
          if (success) added++;
        }
        if (added > 0) {
          state = state.copyWith(
            lastSyncedCount: added,
            lastStatusMessage: 'Auto-detected $added transaction(s) while away',
            lastSyncTime: DateTime.now(),
          );
        }
      }
    } catch (e) {
      debugPrint('[SmsSyncService] processPendingQueue error: $e');
    }
  }

  Future<int> syncPastSms({int days = 180, int limit = 500}) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      state = state.copyWith(lastStatusMessage: 'SMS sync is only supported on Android devices');
      return 0;
    }

    final hasPerm = await requestPermission();
    if (!hasPerm) {
      state = state.copyWith(lastStatusMessage: 'SMS permission was denied');
      return 0;
    }

    state = state.copyWith(isSyncing: true, lastStatusMessage: 'Reconciling accounts & scanning SMS...');

    // Reconcile and clean up accounts first
    await reconcileAccounts();

    int addedCount = 0;
    try {
      final rawList = await _channel.invokeListMethod<Map>('getInboxSms', {
        'limit': limit,
        'days': days,
      });

      if (rawList == null || rawList.isEmpty) {
        state = state.copyWith(
          isSyncing: false,
          lastSyncedCount: 0,
          lastStatusMessage: 'No NationsSMS or eZ Cash messages found in last $days days',
          lastSyncTime: DateTime.now(),
        );
        return 0;
      }

      for (var item in rawList) {
        final m = Map<String, dynamic>.from(item);
        final sender = m['sender']?.toString() ?? '';
        final body = m['body']?.toString() ?? '';
        final ts = m['timestamp'] as int?;
        final date = ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : DateTime.now();

        final added = await processSingleSms(
          sender: sender,
          body: body,
          timestamp: date,
          notify: false,
        );
        if (added) {
          addedCount++;
        }
      }

      // Reconcile and calibrate all accounts accurately AFTER all transactions are in place
      await reconcileAccounts();

      state = state.copyWith(
        isSyncing: false,
        lastSyncedCount: addedCount,
        lastStatusMessage: addedCount > 0
            ? 'Successfully imported $addedCount new transaction(s)'
            : 'All bank & eZ Cash transactions are already up to date',
        lastSyncTime: DateTime.now(),
      );

      if (addedCount > 0) {
        await NotificationService().showInstantNotification(
          id: 9999,
          title: 'FinoGen SMS Sync Complete',
          body: 'Imported $addedCount new transaction(s) from NationsSMS & eZ Cash',
        );
      }
    } catch (e) {
      debugPrint('[SmsSyncService] syncPastSms error: $e');
      state = state.copyWith(
        isSyncing: false,
        lastStatusMessage: 'Error scanning SMS: $e',
      );
    }

    return addedCount;
  }

  Future<bool> processSingleSms({
    required String sender,
    required String body,
    DateTime? timestamp,
    bool notify = true,
  }) async {
    final parsed = SmsParserService.parse(sender, body, smsTimestamp: timestamp);
    if (parsed == null) return false;

    final txRepo = ref.read(transactionRepositoryProvider);
    final accRepo = ref.read(accountRepositoryProvider);

    final existingTxList = await txRepo.getUserTransactions().first;
    final isDuplicate = existingTxList.any((tx) {
      if (tx.externalRefId != null && tx.externalRefId == parsed.uniqueRefId) {
        return true;
      }
      if ((tx.amount - parsed.amount).abs() < 0.01 &&
          tx.isIncome == parsed.isIncome &&
          tx.date.difference(parsed.date).inMinutes.abs() <= 2) {
        return true;
      }
      return false;
    });

    if (isDuplicate) {
      debugPrint('[SmsSyncService] Skipping duplicate transaction refId: ${parsed.uniqueRefId}');
      return false;
    }

    final accounts = await accRepo.getUserAccounts().first;
    AccountModel? targetAccount;

    final String activeWallet = await getActiveDeviceWalletType();
    final bool isNations = parsed.sender.toUpperCase().contains('NATIONS') || parsed.sender.toUpperCase().contains('NTB');
    final normSender = sender.replaceAll(RegExp(r'[^0-9]'), '');
    final bool hasExplicitAirtel = normSender.contains('769169810') || sender.contains('769169810') || body.contains('769169810') || parsed.accountName.contains('769169810') || parsed.uniqueRefId.contains('SIM2') || sender.contains('9010');
    final bool isSim2 = activeWallet == 'airtel' || hasExplicitAirtel;
    
    // Automatic Detection Rule: Monthly Standing Instruction of Rs. 10,000 from Father
    final bool isFathersSalary = isNations &&
        (parsed.rawSms.toUpperCase().contains('STANDING INSTRUCTIONS') || parsed.note.toUpperCase().contains('STANDING INSTRUCTIONS')) &&
        (parsed.amount - 10000.0).abs() < 1.0 &&
        parsed.isIncome;

    if (isFathersSalary) {
      // Accurately record standing instructions as monthly salary income

      // Route strictly to "Nations Trust Bank Fathers Sallery"!
      targetAccount = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && (
          a.name.toLowerCase().contains('father') ||
          a.name.toLowerCase().contains('sallery') ||
          a.name.toLowerCase().contains('salary')
        ),
        orElse: () => null,
      );
      if (targetAccount == null) {
        targetAccount = AccountModel(
          id: const Uuid().v4(),
          userId: 'guest',
          name: 'Nations Trust Bank Fathers Sallery',
          type: AccountType.bank,
          balance: 70000.0,
          colorValue: 0xFF00D9A8,
          isEnabled: true,
        );
        await accRepo.addAccount(targetAccount);
      }
    } else if (isNations) {
      // Route to personal "Nations trust bank"
      targetAccount = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && (
          a.name.toLowerCase().contains('nation') || a.name.toLowerCase().contains('ntb')
        ) && !a.name.toLowerCase().contains('father') &&
            !a.name.toLowerCase().contains('sall') &&
            !a.name.toLowerCase().contains('sala'),
        orElse: () => null,
      );
      if (targetAccount == null) {
        targetAccount = AccountModel(
          id: const Uuid().v4(),
          userId: 'guest',
          name: 'Nations trust bank',
          type: AccountType.bank,
          balance: 69504.99,
          colorValue: 0xFF007BFF,
          isEnabled: true,
        );
        await accRepo.addAccount(targetAccount);
      }
    } else if (isSim2) {
      // Route strictly to "Ez Cash (Airtel)"!
      targetAccount = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && (
          a.name.toLowerCase().contains('airtel') ||
          a.name.contains('769169810') ||
          a.name.contains('076 916 9810') ||
          a.name.toLowerCase().contains('sim 2') ||
          a.name.toLowerCase().contains('sim2')
        ),
        orElse: () => null,
      );
      if (targetAccount == null) {
        targetAccount = AccountModel(
          id: const Uuid().v4(),
          userId: 'guest',
          name: 'Ez Cash (Airtel)',
          type: AccountType.cash,
          balance: 120.0,
          colorValue: 0xFF26A69A,
          isEnabled: true,
        );
        await accRepo.addAccount(targetAccount);
      }
    } else {
      // Route strictly to "Ez Cash (Dialog)"
      targetAccount = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && (
          a.name.toLowerCase().contains('dialog') ||
          a.name.toLowerCase() == 'ez cash dialog' ||
          a.name.toLowerCase() == 'ez cash (dialog)' ||
          a.name.toLowerCase() == 'ez cash dialog new'
        ),
        orElse: () => null,
      );
      if (targetAccount == null) {
        targetAccount = accounts.cast<AccountModel?>().firstWhere(
          (a) => a != null && a.name.toLowerCase().contains('ez') &&
                 !a.name.contains('769169810') &&
                 !a.name.contains('076 916 9810') &&
                 !a.name.toLowerCase().contains('sim 2') &&
                 !a.name.toLowerCase().contains('airtel') &&
                 !a.name.toLowerCase().contains('old'),
          orElse: () => null,
        );
      }
      if (targetAccount == null) {
        targetAccount = AccountModel(
          id: const Uuid().v4(),
          userId: 'guest',
          name: 'Ez Cash (Dialog)',
          type: AccountType.cash,
          balance: 548.0,
          colorValue: 0xFFFF9900,
          isEnabled: true,
        );
        await accRepo.addAccount(targetAccount);
      }
    }

    final bool isSpeedNetIncome = !isFathersSalary && parsed.isIncome && parsed.amount <= 600.0;
    final bool isNetcupServerExpense = !parsed.isIncome && (
        parsed.note.toLowerCase().contains('netcup') ||
        body.toLowerCase().contains('netcup') ||
        parsed.note.toLowerCase().contains('foreign pos') ||
        body.toLowerCase().contains('foreign pos')
    );
    final bool isAtmOrCashWithdrawal = !parsed.isIncome && (
        parsed.note.toLowerCase().contains('atm') ||
        body.toLowerCase().contains('atm') ||
        parsed.note.toLowerCase().contains('cash withdrawal') ||
        body.toLowerCase().contains('cash withdrawal')
    );
    final bool isFundsTransfer = !parsed.isIncome && (
        parsed.note.toLowerCase().contains('funds transfer') ||
        parsed.note.toLowerCase().contains('fund transfer') ||
        body.toLowerCase().contains('funds transfer') ||
        parsed.note.toLowerCase().contains('mudal yaweema to')
    );

    final String categoryId = isFathersSalary
        ? 'inc_salary'
        : (isSpeedNetIncome
            ? 'inc_novagen'
            : (isNetcupServerExpense
                ? 'exp_novagen_server'
                : (isAtmOrCashWithdrawal || isFundsTransfer
                    ? 'exp_transfer'
                    : (parsed.isIncome ? 'inc_novagen' : 'exp_bills'))));

    final String txNote = isFathersSalary
        ? "Father's Monthly Allowance (Standing Instruction)"
        : (isSpeedNetIncome
            ? (parsed.note.startsWith('NovaGen SpeedNet') ? parsed.note : "NovaGen SpeedNet - ${parsed.note}")
            : (isNetcupServerExpense
                ? (parsed.note.startsWith('Netcup Server VPS Renewal')
                    ? parsed.note
                    : "Netcup Server VPS Renewal - ${parsed.note}")
                : parsed.note));

    final newTx = TransactionModel(
      id: const Uuid().v4(),
      userId: 'guest',
      accountId: targetAccount.id,
      amount: parsed.amount,
      categoryId: categoryId,
      note: txNote,
      date: parsed.date,
      isIncome: parsed.isIncome,
      externalRefId: parsed.uniqueRefId,
    );

    await txRepo.addTransaction(newTx);

    // If live SMS has current balance, calibrate the account base balance accurately (except Fathers Salary which grows by transactions)
    // For batch/historical sync (notify == false), reconcileAccounts() at the end will calibrate
    // to the single newest SMS balance, avoiding older SMS overwriting newer ones!
    if (notify && parsed.currentBalance != null && !isFathersSalary) {
      double totalFathersMoney = 70000.0;
      final fathersAcc = accounts.cast<AccountModel?>().firstWhere(
        (a) => a != null && (a.name.toLowerCase().contains('father') || a.name.toLowerCase().contains('sall')),
        orElse: () => null,
      );
      if (fathersAcc != null) {
        final allTx = await txRepo.getUserTransactions().first;
        final fTx = allTx.where((t) => t.accountId == fathersAcc.id);
        double fSum = 0;
        for (var t in fTx) {
          fSum += t.isIncome ? t.amount : -t.amount;
        }
        totalFathersMoney = fathersAcc.balance + fSum;
      }

      double targetDerived = parsed.currentBalance!;
      if (targetAccount.name.toLowerCase().contains('nation')) {
        targetDerived = (parsed.currentBalance! - totalFathersMoney).clamp(0.0, double.infinity);
      }

      final updatedTxList = await txRepo.getUserTransactions().first;
      final accTx = updatedTxList.where((t) => t.accountId == targetAccount!.id);
      double txSum = 0;
      for (var t in accTx) {
        txSum += t.isIncome ? t.amount : -t.amount;
      }
      final updatedAccount = targetAccount.copyWith(
        balance: targetDerived - txSum,
      );
      await accRepo.updateAccount(updatedAccount);
    }

    if (notify) {
      final notifId = parsed.uniqueRefId.hashCode.abs();
      if (isFathersSalary) {
        await NotificationService().showInstantNotification(
          id: notifId,
          title: "Father's Salary Received: + LKR 10,000.00",
          body: "Nations Trust Bank Fathers Sallery • Added to Savings",
        );
      } else if (isSpeedNetIncome) {
        await NotificationService().showInstantNotification(
          id: notifId,
          title: 'NovaGen SpeedNet: + LKR ${parsed.amount.toStringAsFixed(2)}',
          body: '${parsed.accountName} • ${parsed.note}',
        );
      } else if (isSim2) {
        final sign = parsed.isIncome ? '+' : '-';
        final action = parsed.isIncome ? 'Income' : 'Expense';
        await NotificationService().showInstantNotification(
          id: notifId,
          title: 'Ez Cash (076 916 9810) $action: $sign LKR ${parsed.amount.toStringAsFixed(2)}',
          body: '${parsed.note} • Bal: LKR ${parsed.currentBalance?.toStringAsFixed(2) ?? "--"}',
        );
      } else {
        final sign = parsed.isIncome ? '+' : '-';
        final action = parsed.isIncome ? 'Income' : 'Expense';

        await NotificationService().showInstantNotification(
          id: notifId,
          title: '$action Added: $sign LKR ${parsed.amount.toStringAsFixed(2)}',
          body: '${parsed.accountName} • ${parsed.note}',
        );
      }
    }

    return true;
  }
}

final smsSyncServiceProvider = NotifierProvider<SmsSyncNotifier, SmsSyncState>(SmsSyncNotifier.new);
