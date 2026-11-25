import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/repositories/bill_repository.dart';
import '../../../../core/models/bill_model.dart';
import '../../../../core/providers/notification_providers.dart';
import '../../../../core/models/notification_model.dart';
import '../../../../core/services/bill_notification_scheduler.dart';
import 'package:intl/intl.dart';

class AddBillSheet extends ConsumerStatefulWidget {
  final BillModel? bill;
  const AddBillSheet({super.key, this.bill});

  static Future<void> show(BuildContext context, {BillModel? bill}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBillSheet(bill: bill),
    );
  }

  @override
  ConsumerState<AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends ConsumerState<AddBillSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  String _selectedCategory = 'Utility';
  String _selectedIcon = 'zap';
  bool _isPaid = false;
  bool _isRecurring = true;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Utility', 'icon': 'zap', 'iconData': LucideIcons.zap},
    {'name': 'Streaming', 'icon': 'monitor', 'iconData': LucideIcons.monitor},
    {'name': 'Music', 'icon': 'music', 'iconData': LucideIcons.music},
    {'name': 'Internet', 'icon': 'wifi', 'iconData': LucideIcons.wifi},
    {'name': 'Other', 'icon': 'receipt', 'iconData': LucideIcons.receipt},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.bill != null) {
      _nameController.text = widget.bill!.name;
      _amountController.text = widget.bill!.amount.toString();
      _dueDate = widget.bill!.dueDate;
      _selectedCategory = widget.bill!.category;
      _selectedIcon = widget.bill!.iconId;
      _isPaid = widget.bill!.isPaid;
      _isRecurring = widget.bill!.isRecurring;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _applyPreset(String name, double amount, int dueDay, String category, String icon) {
    setState(() {
      _nameController.text = name;
      _amountController.text = amount.toStringAsFixed(0);
      _selectedCategory = category;
      _selectedIcon = icon;
      _isRecurring = true;

      final now = DateTime.now();
      int year = now.year;
      int month = now.month;
      if (now.day > dueDay) {
        month += 1;
        if (month > 12) {
          month = 1;
          year += 1;
        }
      }
      final maxDays = DateTime(year, month + 1, 0).day;
      final targetDay = dueDay > maxDays ? maxDays : dueDay;
      _dueDate = DateTime(year, month, targetDay);
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: AppColors.isDark(context) ? Brightness.dark : Brightness.light,
              primary: AppColors.accent(context),
              onPrimary: AppColors.accentFg(context),
              secondary: AppColors.accent(context),
              onSecondary: AppColors.accentFg(context),
              error: Colors.redAccent,
              onError: Colors.white,
              surface: AppColors.cardBg(context),
              onSurface: AppColors.text(context),
            ),
            dialogBackgroundColor: AppColors.cardBg(context),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final repo = ref.read(billRepositoryProvider);
      
      BillModel savedBill;
      if (widget.bill != null) {
        savedBill = widget.bill!.copyWith(
          name: _nameController.text.trim(),
          category: _selectedCategory,
          amount: amount,
          dueDate: _dueDate,
          isPaid: _isPaid,
          iconId: _selectedIcon,
          isRecurring: _isRecurring,
        );
        await repo.updateBill(savedBill);
      } else {
        savedBill = BillModel(
          id: '',
          userId: '',
          name: _nameController.text.trim(),
          category: _selectedCategory,
          amount: amount,
          dueDate: _dueDate,
          isPaid: _isPaid,
          iconId: _selectedIcon,
          isRecurring: _isRecurring,
        );
        await repo.addBill(savedBill);
        
        final notifRepo = ref.read(notificationRepositoryProvider);
        notifRepo.addNotification(NotificationModel(
          id: '',
          title: 'Upcoming Bill Scheduled',
          message: '${savedBill.name} is due on ${DateFormat('MMM dd').format(savedBill.effectiveDueDate)}.',
          type: 'reminder',
          isRead: false,
          createdAt: DateTime.now(),
        ));
      }

      // Schedule smart multi-stage reminders
      await BillNotificationScheduler.scheduleBillReminders(savedBill);
      
      if (mounted) Navigator.pop(context);
    }
  }
  
  Future<void> _delete() async {
    if (widget.bill != null) {
      await BillNotificationScheduler.cancelBillReminders(widget.bill!.id);
      final repo = ref.read(billRepositoryProvider);
      await repo.deleteBill(widget.bill!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currency = ref.watch(currencySymbolProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.bill == null ? 'New Bill/Subscription' : 'Edit Bill',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.text(context)),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.cardBg(context), shape: BoxShape.circle),
                      child: Icon(LucideIcons.x, size: 20, color: AppColors.muted(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick Presets
              if (widget.bill == null) ...[
                Text('Quick Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted(context))),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _presetChip('⚡ Netcup Server', 'Netcap Server', 2519.0, 22, 'Utility', 'zap'),
                      _presetChip('📱 Airtel Data', 'Airtel Data Pckge', 270.0, 18, 'Internet', 'wifi'),
                      _presetChip('🎬 Netflix', 'Netflix Subscription', 2200.0, 15, 'Streaming', 'monitor'),
                      _presetChip('🌐 Home Fiber', 'Dialog Home Fiber', 3500.0, 28, 'Internet', 'wifi'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              TextFormField(
                controller: _nameController,
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  labelText: 'Bill Name (e.g. Netcup Server, Airtel Data)',
                  labelStyle: TextStyle(color: AppColors.muted(context)),
                  filled: true,
                  fillColor: AppColors.cardBg(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppColors.text(context)),
                decoration: InputDecoration(
                  labelText: 'Amount ($currency)',
                  labelStyle: TextStyle(color: AppColors.muted(context)),
                  filled: true,
                  fillColor: AppColors.cardBg(context),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Invalid amount' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.calendar, color: AppColors.accent(context), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Due Date: ${DateFormat('MMM dd, yyyy').format(_dueDate)} (Day ${_dueDate.day})',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.text(context)),
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, size: 16, color: AppColors.muted(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recurring Switch
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: Text('Monthly Recurring Bill', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _isRecurring 
                        ? 'Repeats every month on day ${_dueDate.day}. Auto-schedules 1d-before & due-day alerts.'
                        : 'One-time bill only',
                    style: TextStyle(color: AppColors.muted(context), fontSize: 12),
                  ),
                  value: _isRecurring,
                  activeColor: AppColors.accent(context),
                  onChanged: (val) => setState(() => _isRecurring = val),
                  secondary: Icon(LucideIcons.repeat, color: _isRecurring ? AppColors.accent(context) : AppColors.muted(context)),
                ),
              ),

              const SizedBox(height: 24),
              Text('Category', style: TextStyle(fontSize: 14, color: AppColors.muted(context))),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat['name'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat['name'];
                          _selectedIcon = cat['icon'];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent(context).withOpacity(0.15) : AppColors.cardBg(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.accent(context) : AppColors.borderColor(context)),
                        ),
                        child: Row(
                          children: [
                            Icon(cat['iconData'] as IconData, size: 16, color: isSelected ? AppColors.accent(context) : AppColors.muted(context)),
                            const SizedBox(width: 8),
                            Text(cat['name'] as String, style: TextStyle(color: isSelected ? AppColors.accent(context) : AppColors.text(context), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              if (widget.bill != null) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBg(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SwitchListTile(
                    title: Text('Mark as Paid', style: TextStyle(color: AppColors.text(context))),
                    value: _isPaid,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _isPaid = val),
                    secondary: Icon(_isPaid ? LucideIcons.checkCircle2 : LucideIcons.circle, color: _isPaid ? AppColors.accent(context) : AppColors.muted(context)),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              // Test Notification Button
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    final amount = double.tryParse(_amountController.text) ?? (widget.bill?.amount ?? 2500.0);
                    final dummy = BillModel(
                      id: widget.bill?.id ?? 'preview_id',
                      userId: '',
                      name: _nameController.text.isNotEmpty ? _nameController.text.trim() : 'Server / Data Bill',
                      category: _selectedCategory,
                      amount: amount,
                      dueDate: _dueDate,
                      iconId: _selectedIcon,
                      isRecurring: _isRecurring,
                    );
                    await BillNotificationScheduler.triggerTestAlert(dummy);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🔔 Test push notification sent to your phone!'),
                          backgroundColor: Color(0xFF00D09E),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(LucideIcons.bellRing, size: 16),
                  label: const Text('Test Notification Alert Now', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.accent(context)),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  if (widget.bill != null) ...[
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _delete,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF5252),
                            side: const BorderSide(color: Color(0xFFFF5252)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Icon(LucideIcons.trash2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent(context),
                          foregroundColor: AppColors.accentFg(context),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(widget.bill == null ? 'Add Bill & Schedule Alerts' : 'Save Changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _presetChip(String label, String name, double amount, int dueDay, String category, String icon) {
    return GestureDetector(
      onTap: () => _applyPreset(name, amount, dueDay, category, icon),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor(context)),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.text(context))),
      ),
    );
  }
}
