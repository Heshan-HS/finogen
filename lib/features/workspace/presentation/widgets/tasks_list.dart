import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/workspace_provider.dart';

class TasksList extends ConsumerWidget {
  final DateTime selectedDay;

  const TasksList({super.key, required this.selectedDay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(workspaceProvider);
    final notifier = ref.read(workspaceProvider.notifier);
    
    // Create a key for the date to filter tasks
    final key = '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
    final tasksForDay = state.tasks.where((t) => t.dateKey == key).toList();

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
              Text('Tasks', style: TextStyle(color: AppColors.text(context), fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: Icon(LucideIcons.plus, color: AppColors.accentFg(context), size: 16),
                label: Text('Add Task', style: TextStyle(color: AppColors.accentFg(context))),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent(context), foregroundColor: AppColors.accentFg(context)),
                onPressed: () {
                  try {
                    _showAddTaskDialog(context, ref);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: tasksForDay.isEmpty
                ? Center(
                    child: Text(
                      'No tasks for ${selectedDay.day}/${selectedDay.month}',
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                  )
                : ListView.builder(
                    itemCount: tasksForDay.length,
                    itemBuilder: (context, index) {
                      final task = tasksForDay[index];
                      return ListTile(
                        leading: Checkbox(
                          value: task.isCompleted,
                          onChanged: (val) {
                            notifier.toggleTask(task.id);
                          },
                          activeColor: AppColors.primary,
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            color: task.isCompleted ? AppColors.muted(context) : AppColors.text(context),
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                          onPressed: () {
                            notifier.deleteTask(task.id);
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

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardBg(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add Task', style: TextStyle(color: AppColors.text(context), fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: AppColors.text(context)),
            decoration: InputDecoration(
              hintText: 'Task Title',
              hintStyle: TextStyle(color: AppColors.muted(context)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.muted(context))),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  ref.read(workspaceProvider.notifier).addTask(selectedDay, controller.text);
                  Navigator.pop(context);
                }
              },
              child: Text('Add', style: TextStyle(color: AppColors.accent(context), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
