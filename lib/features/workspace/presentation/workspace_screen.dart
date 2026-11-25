import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/timetable_view.dart';
import 'widgets/notes_card.dart';
import 'widgets/tasks_list.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Productivity Workspace',
                style: TextStyle(
                  color: AppColors.text(context),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage your time, notes, and tasks effectively.',
                style: TextStyle(color: AppColors.muted(context), fontSize: 14),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Col 1: Calendar & Notes
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildCalendarCard(),
                          const SizedBox(height: 24),
                          Expanded(child: NotesCard(selectedDay: _selectedDay ?? _focusedDay)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Col 2: Timetable & Tasks
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TimetableView(selectedDay: _selectedDay ?? _focusedDay),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            flex: 1,
                            child: TasksList(selectedDay: _selectedDay ?? _focusedDay),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor(context)),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          defaultTextStyle: TextStyle(color: AppColors.text(context)),
          weekendTextStyle: TextStyle(color: AppColors.muted(context)),
          selectedDecoration: BoxDecoration(
            color: AppColors.accent(context),
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.accentTint(context),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(color: AppColors.text(context), fontSize: 16, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(LucideIcons.chevronLeft, color: AppColors.text(context)),
          rightChevronIcon: Icon(LucideIcons.chevronRight, color: AppColors.text(context)),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: AppColors.muted(context)),
          weekendStyle: TextStyle(color: AppColors.muted(context).withOpacity(0.7)),
        ),
      ),
    );
  }
}
