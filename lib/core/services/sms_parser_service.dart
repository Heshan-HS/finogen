class ParsedBankTransaction {
  final String rawSms;
  final String sender;
  final String accountName;
  final String accountNumber;
  final double amount;
  final bool isIncome;
  final String categoryName;
  final String note;
  final DateTime date;
  final String uniqueRefId;
  final double? currentBalance;
  final double? fee;

  ParsedBankTransaction({
    required this.rawSms,
    required this.sender,
    required this.accountName,
    required this.accountNumber,
    required this.amount,
    required this.isIncome,
    required this.categoryName,
    required this.note,
    required this.date,
    required this.uniqueRefId,
    this.currentBalance,
    this.fee,
  });

  @override
  String toString() {
    return 'ParsedBankTransaction(account: $accountName, type: ${isIncome ? "Income" : "Expense"}, amount: $amount, refId: $uniqueRefId)';
  }
}

class SmsParserService {
  static ParsedBankTransaction? parse(String sender, String body, {DateTime? smsTimestamp}) {
    final cleanSender = sender.trim().toUpperCase();
    final cleanBody = body.trim();
    final normalizedDigits = sender.replaceAll(RegExp(r'[^0-9]'), '');
    final bool isSecondarySim = normalizedDigits.contains('769169810') ||
                                cleanSender.contains('769169810') ||
                                cleanBody.contains('769169810') || cleanSender.contains('9010');

    if (cleanSender.contains('NATIONS') || cleanSender.contains('NTB')) {
      return _parseNationsSms(cleanBody, smsTimestamp: smsTimestamp);
    } else if (cleanSender.contains('EZ') && cleanSender.contains('CASH')) {
      return _parseEzCashSms(cleanBody, smsTimestamp: smsTimestamp, isSecondarySim: isSecondarySim);
    }

    if (isSecondarySim) {
      return _parseEzCashSms(cleanBody, smsTimestamp: smsTimestamp, isSecondarySim: true);
    }

    if (cleanBody.contains('NationsSMS') || cleanBody.contains('Account No. 2005')) {
      return _parseNationsSms(cleanBody, smsTimestamp: smsTimestamp);
    } else if (cleanBody.contains('eZ Cash') ||
               cleanBody.contains('RN:20') ||
               cleanBody.contains('recharge kara etha') ||
               cleanBody.contains('Sheshaya:') ||
               cleanBody.contains('Current Balance:')) {
      return _parseEzCashSms(cleanBody, smsTimestamp: smsTimestamp, isSecondarySim: false);
    }

    return null;
  }

  static ParsedBankTransaction? _parseNationsSms(String body, {DateTime? smsTimestamp}) {
    final amountReg = RegExp(
      r'for\s+LKR\s*([0-9,]+(?:\.[0-9]{1,2})?)\s*(CR|DR)\.?',
      caseSensitive: false,
    );
    final amountMatch = amountReg.firstMatch(body);
    if (amountMatch == null) return null;

    final amountStr = amountMatch.group(1)!.replaceAll(',', '');
    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    final typeStr = amountMatch.group(2)!.toUpperCase();
    final isIncome = typeStr == 'CR';

    final accReg = RegExp(r'Account\s+No\.?\s*([0-9a-zA-Z]+)', caseSensitive: false);
    final accMatch = accReg.firstMatch(body);
    final accNo = accMatch != null ? accMatch.group(1)! : '2005xxxx0951';

    final balReg = RegExp(r'Current\s+Bal(?:ance)?\s+LKR\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
    final balMatch = balReg.firstMatch(body);
    final currentBal = balMatch != null ? double.tryParse(balMatch.group(1)!.replaceAll(',', '')) : null;

    final descReg = RegExp(r'^([A-Z0-9\s\/\-_]+?)\s+was\s+performed', caseSensitive: false);
    final descMatch = descReg.firstMatch(body);
    String noteDesc = descMatch != null ? descMatch.group(1)!.trim() : (isIncome ? "Deposit / Transfer" : "Withdrawal / Payment");

    final effectiveDate = smsTimestamp ?? DateTime.now();

    final idString = 'NTB_${accNo}_${amount.toStringAsFixed(2)}_${typeStr}_${currentBal?.toStringAsFixed(2) ?? ""}_${effectiveDate.year}${effectiveDate.month.toString().padLeft(2, '0')}${effectiveDate.day.toString().padLeft(2, '0')}${effectiveDate.hour.toString().padLeft(2, '0')}${effectiveDate.minute.toString().padLeft(2, '0')}';
    final refId = _generateHash(idString);

    return ParsedBankTransaction(
      rawSms: body,
      sender: 'NationsSMS',
      accountName: 'Nations Trust Bank',
      accountNumber: accNo,
      amount: amount,
      isIncome: isIncome,
      categoryName: isIncome ? 'Income' : 'General',
      note: 'NTB: $noteDesc',
      date: effectiveDate,
      uniqueRefId: refId,
      currentBalance: currentBal,
    );
  }

  static ParsedBankTransaction? _parseEzCashSms(String body, {DateTime? smsTimestamp, bool isSecondarySim = false}) {
    final rnReg = RegExp(r'RN:\s*([0-9a-zA-Z]+)', caseSensitive: false);
    final rnMatch = rnReg.firstMatch(body);
    final rn = rnMatch?.group(1);

    final dateReg = RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})\s+(\d{1,2}):(\d{2})');
    final dateMatch = dateReg.firstMatch(body);
    DateTime effectiveDate = smsTimestamp ?? DateTime.now();
    if (dateMatch != null) {
      final day = int.tryParse(dateMatch.group(1)!);
      final month = int.tryParse(dateMatch.group(2)!);
      final year = int.tryParse(dateMatch.group(3)!);
      final hour = int.tryParse(dateMatch.group(4)!);
      final minute = int.tryParse(dateMatch.group(5)!);
      if (day != null && month != null && year != null && hour != null && minute != null) {
        effectiveDate = DateTime(year, month, day, hour, minute);
      }
    }

    final feeReg = RegExp(r'sewa\s+gasthu(?:wa)?:\s*Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
    final feeMatch = feeReg.firstMatch(body);
    final fee = feeMatch != null ? double.tryParse(feeMatch.group(1)!.replaceAll(',', '')) : 0.0;

    final balReg = RegExp(r'(?:Current\s+Bal(?:ance)?|Sheshaya):\s*Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
    final balMatch = balReg.firstMatch(body);
    final currentBal = balMatch != null ? double.tryParse(balMatch.group(1)!.replaceAll(',', '')) : null;

    final lowerBody = body.toLowerCase();
    final prefix = isSecondarySim ? 'EZCASH_SIM2_' : 'EZCASH_';
    final accountName = isSecondarySim ? 'Ez Cash (076 916 9810)' : 'eZ Cash';
    final accountNumber = isSecondarySim ? '076 916 9810' : 'eZ Cash Wallet';
    final senderLabel = isSecondarySim ? '076 916 9810' : 'eZ Cash';

    // 1. Recharge / Inward reload
    if (lowerBody.contains('recharge') || lowerBody.contains('labunu mudala') || lowerBody.contains('reload')) {
      final netReg = RegExp(r'Labunu\s+mudala:\s*Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
      final netMatch = netReg.firstMatch(body);

      double? amount;
      if (netMatch != null) {
        amount = double.tryParse(netMatch.group(1)!.replaceAll(',', ''));
      }
      if (amount == null || amount <= 0) {
        final recReg = RegExp(r'Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)\s+recharge', caseSensitive: false);
        final recMatch = recReg.firstMatch(body);
        if (recMatch != null) {
          amount = double.tryParse(recMatch.group(1)!.replaceAll(',', ''));
        }
      }
      if (amount == null || amount <= 0) {
        final anyRsReg = RegExp(r'Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
        final anyRsMatch = anyRsReg.firstMatch(body);
        if (anyRsMatch != null) {
          amount = double.tryParse(anyRsMatch.group(1)!.replaceAll(',', ''));
        }
      }
      if (amount == null || amount <= 0) return null;

      final shopReg = RegExp(r'\(([^)]+)\)');
      final shopMatch = shopReg.firstMatch(body);
      final shopName = shopMatch != null ? shopMatch.group(1)!.trim() : 'eZ Cash Agent';

      final refId = rn != null ? '$prefix$rn' : _generateHash('${prefix}RECHARGE_${amount}_${effectiveDate.millisecondsSinceEpoch}');

      return ParsedBankTransaction(
        rawSms: body,
        sender: senderLabel,
        accountName: accountName,
        accountNumber: accountNumber,
        amount: amount,
        isIncome: true,
        categoryName: 'eZ Cash',
        note: isSecondarySim ? 'eZ Cash (SIM 2) Reload: $shopName' : 'eZ Cash Reload: $shopName',
        date: effectiveDate,
        uniqueRefId: refId,
        currentBalance: currentBal,
        fee: fee,
      );
    }

    // 2. Received money / Transfer in (Check this BEFORE Sent Money because Dialog prefixes alerts with a promotional "Mudal yaweema" header!)
    if (lowerBody.contains('received from') ||
        lowerBody.contains('net received') ||
        lowerBody.contains('labi atha') ||
        lowerBody.contains('received') ||
        lowerBody.contains('labeema') ||
        lowerBody.contains('labunu bawa')) {
      final fromReg = RegExp(r'Received\s+from\s+([0-9a-zA-Z]+)', caseSensitive: false);
      final fromMatch = fromReg.firstMatch(body);
      final senderParty = fromMatch != null ? fromMatch.group(1)!.trim() : '';

      final netRecvReg = RegExp(r'Net\s+Received:\s*Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
      final netRecvMatch = netRecvReg.firstMatch(body);
      double? amount;
      if (netRecvMatch != null) {
        amount = double.tryParse(netRecvMatch.group(1)!.replaceAll(',', ''));
      }
      if (amount == null || amount <= 0) {
        final recReg = RegExp(r'Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)\s+Current\s+Bal', caseSensitive: false);
        final recMatch = recReg.firstMatch(body);
        if (recMatch != null) {
          amount = double.tryParse(recMatch.group(1)!.replaceAll(',', ''));
        }
      }
      if (amount == null || amount <= 0) {
        final recvAmtReg = RegExp(r'\d{2}:\d{2}\s+Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
        final recvAmtMatch = recvAmtReg.firstMatch(body);
        if (recvAmtMatch != null) {
          amount = double.tryParse(recvAmtMatch.group(1)!.replaceAll(',', ''));
        }
      }
      if (amount == null || amount <= 0) {
        final bodyWithoutPromo = body.replaceAll(RegExp(r'Dan obata Commercial Bank.*?(?=\n\n|$)', dotAll: true), '');
        final amtReg = RegExp(r'Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
        final amtMatch = amtReg.firstMatch(bodyWithoutPromo);
        if (amtMatch != null) {
          amount = double.tryParse(amtMatch.group(1)!.replaceAll(',', ''));
        }
      }
      if (amount != null && amount > 0) {
        final refId = rn != null ? '$prefix$rn' : _generateHash('${prefix}RECV_${amount}_${effectiveDate.millisecondsSinceEpoch}');

        final String noteText = senderParty.isNotEmpty
            ? (isSecondarySim ? 'eZ Cash (SIM 2): Received from $senderParty' : 'eZ Cash: Received from $senderParty')
            : (isSecondarySim ? 'eZ Cash (SIM 2): Received Money' : 'eZ Cash: Mudal labunu bawa');

        return ParsedBankTransaction(
          rawSms: body,
          sender: senderLabel,
          accountName: accountName,
          accountNumber: accountNumber,
          amount: amount,
          isIncome: true,
          categoryName: 'eZ Cash',
          note: noteText,
          date: effectiveDate,
          uniqueRefId: refId,
          currentBalance: currentBal,
          fee: fee,
        );
      }
    }

    // 3. Sent money / Payment / Withdrawal
    if (lowerBody.contains('mudal yaweema') || lowerBody.contains('geweema') || lowerBody.contains('cash out') || lowerBody.contains('payment') || lowerBody.contains('bill geweem')) {
      final recReg = RegExp(r'Geweema:\s*([0-9]+)', caseSensitive: false);
      final recMatch = recReg.firstMatch(body);
      final recipient = recMatch != null ? recMatch.group(1)!.trim() : 'Recipient';

      final netReg = RegExp(r'Shuddha\s+geweema:\s*Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
      final netMatch = netReg.firstMatch(body);

      double? amount;
      if (netMatch != null) {
        amount = double.tryParse(netMatch.group(1)!.replaceAll(',', ''));
      }
      if (amount == null || amount <= 0) {
        final gewReg = RegExp(r'Geweema:\s*Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
        final gewMatch = gewReg.firstMatch(body);
        if (gewMatch != null) {
          amount = double.tryParse(gewMatch.group(1)!.replaceAll(',', ''));
        }
      }
      if (amount == null || amount <= 0) {
        // Strip out the promotional ATM text before looking for any Rs amount
        final bodyWithoutPromo = body.replaceAll(RegExp(r'Dan obata Commercial Bank.*?(?=\n\n|$)', dotAll: true), '');
        final amtReg = RegExp(r'Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
        final amtMatch = amtReg.firstMatch(bodyWithoutPromo);
        if (amtMatch != null) {
          amount = double.tryParse(amtMatch.group(1)!.replaceAll(',', ''));
        }
      }
      if (amount == null || amount <= 0) return null;

      final refId = rn != null ? '$prefix$rn' : _generateHash('${prefix}PAY_${amount}_${effectiveDate.millisecondsSinceEpoch}');

      return ParsedBankTransaction(
        rawSms: body,
        sender: senderLabel,
        accountName: accountName,
        accountNumber: accountNumber,
        amount: amount,
        isIncome: false,
        categoryName: 'Transfer',
        note: isSecondarySim ? 'eZ Cash (SIM 2): Payment to $recipient' : 'eZ Cash: Mudal yaweema to $recipient',
        date: effectiveDate,
        uniqueRefId: refId,
        currentBalance: currentBal,
        fee: fee,
      );
    }

    // 4. Fallback for secondary SIM forwarded messages with balance or amount
    if (isSecondarySim || lowerBody.contains('ez cash')) {
      final amtReg = RegExp(r'Rs\.?\s*([0-9,]+(?:\.[0-9]{1,2})?)', caseSensitive: false);
      final amtMatch = amtReg.firstMatch(body);
      if (amtMatch != null) {
        final amount = double.tryParse(amtMatch.group(1)!.replaceAll(',', ''));
        if (amount != null && amount > 0) {
          final bool isIncome = !lowerBody.contains('dr') &&
                                !lowerBody.contains('debit') &&
                                !lowerBody.contains('paid') &&
                                !lowerBody.contains('sent') &&
                                !lowerBody.contains('geweema');
          final refId = rn != null ? '$prefix$rn' : _generateHash('${prefix}GEN_${amount}_${effectiveDate.millisecondsSinceEpoch}');

          return ParsedBankTransaction(
            rawSms: body,
            sender: senderLabel,
            accountName: accountName,
            accountNumber: accountNumber,
            amount: amount,
            isIncome: isIncome,
            categoryName: isIncome ? 'eZ Cash' : 'Transfer',
            note: isSecondarySim ? 'eZ Cash (SIM 2) Transaction' : 'eZ Cash Transaction',
            date: effectiveDate,
            uniqueRefId: refId,
            currentBalance: currentBal,
            fee: fee,
          );
        }
      }
    }

    return null;
  }

  static String _generateHash(String input) {
    int hash = 5381;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) + hash) + input.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
