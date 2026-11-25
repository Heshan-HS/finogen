import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/workspace_provider.dart';

class TimetableView extends ConsumerWidget {
  final DateTime selectedDay;

  const TimetableView({super.key, required this.selectedDay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(workspaceProvider.notifier).getTimetableForDate(selectedDay);
    // Since getTimetableForDate isn't directly observable, we need to read state.timetable to rebuild.
    ref.watch(workspaceProvider.select((state) => state.timetable)); 
    final updatedEvents = ref.read(workspaceProvider.notifier).getTimetableForDate(selectedDay);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Timetable', style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: Icon(LucideIcons.plus, color: AppColors.accentFg(context), size: 16),
                label: Text('Add Event', style: TextStyle(color: AppColors.accentFg(context))),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent(context), foregroundColor: AppColors.accentFg(context)),
                onPressed: () {
                  try {
                    _showAddEventDialog(context, ref);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: updatedEvents.isEmpty
                ? Center(
                    child: Text(
                      'No schedule for ${selectedDay.day}/${selectedDay.month}',
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                  )
                : ListView.builder(
                    itemCount: updatedEvents.length,
                    itemBuilder: (context, index) {
                      final event = updatedEvents[index];
                      final timeStr = '${event.scheduledTime.hour.toString().padLeft(2, '0')}:${event.scheduledTime.minute.toString().padLeft(2, '0')}';
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(timeStr, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(event.title, style: TextStyle(color: AppColors.text(context))),
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            ref.read(workspaceProvider.notifier).deleteTimetableEvent(event.id);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBg(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text('Add Event', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: TextStyle(color: AppColors.text(context)),
                    decoration: InputDecoration(
                      hintText: 'Event Title',
                      hintStyle: TextStyle(color: AppColors.muted(context)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Time: ${selectedTime.format(context)}', style: TextStyle(color: AppColors.text(context))),
                      TextButton(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setState(() => selectedTime = time);
                          }
                        },
                        child: Text('Change', style: TextStyle(color: AppColors.accent(context), fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      ref.read(workspaceProvider.notifier).addTimetableEvent(selectedDay, controller.text, selectedTime);
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add Alarm', style: TextStyle(color: AppColors.accent(context), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
