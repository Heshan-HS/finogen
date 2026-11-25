import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/bill_model.dart';
import 'notification_service.dart';

class BillNotificationScheduler {
  static final BillNotificationScheduler _instance = BillNotificationScheduler._internal();
  factory BillNotificationScheduler() => _instance;
  BillNotificationScheduler._internal();

  /// Deterministic notification ID generation based on bill ID and alert stage.
  /// Stage 1 = Advance (1 day before at 9:00 AM)
  /// Stage 2 = Due day morning (at 9:00 AM)
  /// Stage 3 = Due day evening (at 6:00 PM)
  static int _getNotificationId(String billId, int stage) {
    final baseHash = billId.hashCode.abs() % 10000;
    return (baseHash * 10) + stage;
  }

  /// Cancels all scheduled reminder stages for a bill.
  static Future<void> cancelBillReminders(String billId) async {
    final notif = NotificationService();
    for (int stage = 1; stage <= 3; stage++) {
      await notif.cancelNotification(_getNotificationId(billId, stage));
    }
    debugPrint('[BillScheduler] Cancelled all reminders for bill: $billId');
  }

  /// Schedules 3 reminder stages for a bill:
  /// 1. 1 Day Before at 09:00 AM
  /// 2. Due Date at 09:00 AM
  /// 3. Due Date at 06:00 PM (18:00)
  static Future<void> scheduleBillReminders(BillModel bill) async {
    if (bill.isPaid) {
      await cancelBillReminders(bill.id);
      return;
    }

    final notif = NotificationService();
    final effectiveDue = bill.effectiveDueDate;
    final now = DateTime.now();
    final currencyFormat = NumberFormat('#,##0.00');
    final amountStr = 'Rs ${currencyFormat.format(bill.amount)}';
    final dateStr = DateFormat('MMM dd, yyyy').format(effectiveDue);

    // Cancel previous alarms first to prevent stale duplicates
    await cancelBillReminders(bill.id);

    // Stage 1: 1 Day Before at 09:00 AM
    final alert1Time = DateTime(effectiveDue.year, effectiveDue.month, effectiveDue.day - 1, 9, 0);
    if (alert1Time.isAfter(now)) {
      await notif.scheduleBillNotification(
        id: _getNotificationId(bill.id, 1),
        title: '⚠️ Bill Due Tomorrow: ${bill.name}',
        body: '$amountStr for ${bill.name} is due tomorrow ($dateStr). Ensure your payment is arranged in advance!',
        scheduledTime: alert1Time,
      );
      debugPrint('[BillScheduler] Scheduled Stage 1 for ${bill.name} at $alert1Time');
    }

    // Stage 2: Due Date Morning at 09:00 AM
    final alert2Time = DateTime(effectiveDue.year, effectiveDue.month, effectiveDue.day, 9, 0);
    if (alert2Time.isAfter(now)) {
      await notif.scheduleBillNotification(
        id: _getNotificationId(bill.id, 2),
        title: '🔔 Bill Due Today: ${bill.name}',
        body: '$amountStr for ${bill.name} is due today! Tap to view details or mark as paid.',
        scheduledTime: alert2Time,
      );
      debugPrint('[BillScheduler] Scheduled Stage 2 for ${bill.name} at $alert2Time');
    }

    // Stage 3: Due Date Evening at 06:00 PM (18:00)
    final alert3Time = DateTime(effectiveDue.year, effectiveDue.month, effectiveDue.day, 18, 0);
    if (alert3Time.isAfter(now)) {
      await notif.scheduleBillNotification(
        id: _getNotificationId(bill.id, 3),
        title: '⏳ Final Reminder: ${bill.name} Due Today!',
        body: 'Final hours left today! Complete your payment of $amountStr for ${bill.name} before midnight to avoid downtime.',
        scheduledTime: alert3Time,
      );
      debugPrint('[BillScheduler] Scheduled Stage 3 for ${bill.name} at $alert3Time');
    }
  }

  /// Automatically synchronizes and schedules all upcoming bills.
  static Future<void> syncAllBills(List<BillModel> bills) async {
    for (final bill in bills) {
      if (bill.isPaid) {
        await cancelBillReminders(bill.id);
      } else {
        await scheduleBillReminders(bill);
      }
    }
  }

  /// Fires an instant test push notification right now on the phone for testing!
  static Future<void> triggerTestAlert(BillModel bill) async {
    final currencyFormat = NumberFormat('#,##0.00');
    final amountStr = 'Rs ${currencyFormat.format(bill.amount)}';
    final effectiveDue = bill.effectiveDueDate;
    final dateStr = DateFormat('MMM dd').format(effectiveDue);

    await NotificationService().showBillNotificationNow(
      id: 999901,
      title: '🔔 [Smart Reminder Active] ${bill.name}',
      body: 'Verified: $amountStr due on $dateStr. Smart alerts configured for 1-day advance & final hours reminder!',
    );
  }
}
