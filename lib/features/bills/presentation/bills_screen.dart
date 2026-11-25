import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/bill_providers.dart';
import '../../../core/repositories/bill_repository.dart';
import '../../../core/models/bill_model.dart';
import '../../../core/services/bill_notification_scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'widgets/add_bill_sheet.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  String get currency => ref.watch(currencySymbolProvider);
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    // Automatically schedule and synchronize all active reminders in the background
    ref.listen<AsyncValue<List<BillModel>>>(billsStreamProvider, (prev, next) {
      next.whenData((bills) {
        BillNotificationScheduler.syncAllBills(bills);
      });
    });

    final billsAsync = ref.watch(billsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // Ambient glow
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.2,
                    colors: [
                      AppColors.primary.withOpacity(0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(context),
                const SizedBox(height: 8),
                _smartAlarmsInfoBanner(),
                const SizedBox(height: 12),
                _dateStrip(),
                const SizedBox(height: 16),
                Expanded(
                  child: billsAsync.when(
                    data: (bills) {
                      if (bills.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.bellOff, size: 48, color: AppColors.muted(context)),
                              const SizedBox(height: 12),
                              Text('No bills scheduled yet.', style: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text('Tap + above to add Netcup Server, SIM Data, etc.', style: TextStyle(color: AppColors.muted(context), fontSize: 13)),
                            ],
                          ),
                        );
                      }
                      
                      // Auto-sort by active effective due date
                      final sorted = List<BillModel>.from(bills);
                      sorted.sort((a, b) => a.effectiveDueDate.compareTo(b.effectiveDueDate));

                      var upcoming = sorted.where((b) => !b.isPaid).toList();
                      if (_selectedDate != null) {
                        upcoming = upcoming.where((b) {
                          final due = b.effectiveDueDate;
                          return due.year == _selectedDate!.year && 
                                 due.month == _selectedDate!.month && 
                                 due.day == _selectedDate!.day;
                        }).toList();
                      }
                      final paid = sorted.where((b) => b.isPaid).toList();
                      
                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          if (upcoming.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Upcoming & Recurring', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context))),
                                Text('${upcoming.length} active', style: TextStyle(fontSize: 12, color: AppColors.muted(context))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...upcoming.map((b) => _billItem(b)),
                            const SizedBox(height: 24),
                          ],
                          if (paid.isNotEmpty) ...[
                            Text('Paid / Completed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text(context))),
                            const SizedBox(height: 12),
                            ...paid.map((b) => _billItem(b)),
                          ]
                        ],
                      );
                    },
                    loading: () => Center(child: CircularProgressIndicator(color: AppColors.accent(context))),
                    error: (e, s) => Center(child: Text('Error loading bills: $e', style: const TextStyle(color: Colors.red))),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: AppCard(
              padding: const EdgeInsets.all(10),
              isDark: true,
              borderRadius: 12,
              child: Icon(LucideIcons.arrowLeft, color: AppColors.text(context), size: 20),
            ),
          ),
          Text(
            'Bills & Subscriptions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.text(context)),
          ),
          GestureDetector(
            onTap: () => AddBillSheet.show(context),
            child: AppCard(
              padding: const EdgeInsets.all(10),
              isDark: true,
              borderRadius: 12,
              child: Icon(LucideIcons.plus, color: AppColors.text(context), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smartAlarmsInfoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent(context).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent(context).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.accent(context).withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.bellRing, size: 16, color: AppColors.accent(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Phone Push Alarms Active',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                ),
                Text(
                  '1 day before (9 AM), due day morning (9 AM) & evening (6 PM)',
                  style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateStrip() {
    final now = DateTime.now();
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 7,
        itemBuilder: (context, i) {
          final date = now.add(Duration(days: i));
          final active = _selectedDate != null && 
                         date.year == _selectedDate!.year && 
                         date.month == _selectedDate!.month && 
                         date.day == _selectedDate!.day;
          return GestureDetector(
            onTap: () {
              setState(() {
                if (active) {
                  _selectedDate = null;
                } else {
                  _selectedDate = date;
                }
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: active ? AppColors.accent(context) : AppColors.elevated(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: active ? AppColors.accent(context) : AppColors.borderColor(context)),
                boxShadow: active ? [BoxShadow(color: AppColors.accentGlow(context), blurRadius: 15, offset: const Offset(0, 4))] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('EEE').format(date), style: TextStyle(fontSize: 12, color: active ? AppColors.accentFg(context) : AppColors.muted(context))),
                  const SizedBox(height: 4),
                  Text(DateFormat('dd').format(date), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: active ? AppColors.accentFg(context) : AppColors.text(context))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForId(String id) {
    switch (id) {
      case 'zap': return LucideIcons.zap;
      case 'monitor': return LucideIcons.monitor;
      case 'music': return LucideIcons.music;
      case 'wifi': return LucideIcons.wifi;
      case 'receipt': return LucideIcons.receipt;
      default: return LucideIcons.fileText;
    }
  }

  String _getStatusMsg(BillModel bill) {
    if (bill.isPaid) {
      return 'Paid';
    }
    final effectiveDue = bill.effectiveDueDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(effectiveDue.year, effectiveDue.month, effectiveDue.day);
    final diff = dueDay.difference(today).inDays;

    if (diff == 0) return 'Due today';
    if (diff == 1) return 'Due tomorrow';
    if (diff > 1) return 'Due in $diff days';
    return 'Overdue by ${diff.abs()} days';
  }

  Widget _billItem(BillModel bill) {
    final effectiveDue = bill.effectiveDueDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(effectiveDue.year, effectiveDue.month, effectiveDue.day);
    final diff = dueDay.difference(today).inDays;
    final bool isOverdue = diff < 0 && !bill.isPaid;
    final bool isDueToday = diff == 0 && !bill.isPaid;

    final iconColor = bill.isPaid 
        ? AppColors.primary 
        : isOverdue 
            ? const Color(0xFFFF5252) 
            : isDueToday 
                ? const Color(0xFFFF9100) 
                : AppColors.accent(context);
    final rate = ref.watch(currencyRateProvider);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => AddBillSheet.show(context, bill: bill),
        child: AppCard(
          isDark: true,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: iconColor.withOpacity(0.2)),
                    ),
                    child: Icon(_getIconForId(bill.iconId), color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                bill.name,
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (bill.isRecurring) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent(context).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Monthly',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent(context)),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.calendar, size: 12, color: isOverdue ? Colors.red : AppColors.muted(context)),
                            const SizedBox(width: 4),
                            Text(
                              'Due ${DateFormat('MMM dd').format(effectiveDue)} (${_getStatusMsg(bill)})',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOverdue ? Colors.red : isDueToday ? const Color(0xFFFF9100) : AppColors.muted(context),
                                fontWeight: (isOverdue || isDueToday) ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currency${NumberFormat('#,##0.00').format(bill.amount * rate)}',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text(context)),
                      ),
                      const SizedBox(height: 6),
                      if (!bill.isPaid)
                        GestureDetector(
                          onTap: () => _confirmMarkPaid(bill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent(context).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.accent(context).withOpacity(0.3)),
                            ),
                            child: Text(
                              'Mark Paid',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent(context)),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00D09E).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Paid ✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00D09E))),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.borderColor(context)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.bell, size: 13, color: AppColors.accent(context)),
                      const SizedBox(width: 6),
                      Text(
                        '1d Before (9AM) · Due Day (9AM & 6PM)',
                        style: TextStyle(fontSize: 11, color: AppColors.muted(context)),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      await BillNotificationScheduler.triggerTestAlert(bill);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('🔔 Sent test push notification for ${bill.name}!'),
                            backgroundColor: const Color(0xFF00D09E),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.elevated(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderColor(context)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.bellRing, size: 12, color: AppColors.accent(context)),
                          const SizedBox(width: 4),
                          Text('Test Alert', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent(context))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmMarkPaid(BillModel bill) {
    final nextCycle = bill.nextCycleDueDate;
    final nextFormatted = DateFormat('MMM dd, yyyy').format(nextCycle);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Mark ${bill.name} as Paid?', style: TextStyle(color: AppColors.text(context))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: $currency${NumberFormat('#,##0.00').format(bill.amount)}',
              style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (bill.isRecurring)
              Text(
                'This is a recurring bill. Would you like to advance the schedule to next month ($nextFormatted)?',
                style: TextStyle(color: AppColors.muted(context), fontSize: 13),
              )
            else
              Text(
                'Are you sure you want to mark this bill as paid?',
                style: TextStyle(color: AppColors.muted(context), fontSize: 13),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
          ),
          if (bill.isRecurring)
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(billRepositoryProvider);
                // Advance cycle to next month and keep active
                final updated = bill.copyWith(
                  dueDate: nextCycle,
                  isPaid: false,
                );
                await repo.updateBill(updated);
                await BillNotificationScheduler.scheduleBillReminders(updated);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Paid! Next cycle scheduled for $nextFormatted.'),
                      backgroundColor: const Color(0xFF00D09E),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent(context), foregroundColor: AppColors.accentFg(context)),
              child: const Text('Paid & Advance to Next Month'),
            )
          else
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(billRepositoryProvider);
                await repo.updateBill(bill.copyWith(isPaid: true));
                await BillNotificationScheduler.cancelBillReminders(bill.id);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent(context), foregroundColor: AppColors.accentFg(context)),
              child: const Text('Confirm Paid'),
            ),
        ],
      ),
    );
  }
}
