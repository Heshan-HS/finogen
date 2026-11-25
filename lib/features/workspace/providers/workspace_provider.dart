import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import '../../../core/services/notification_service.dart';
import 'dart:convert';

// --- MODELS ---

class WorkspaceNote {
  final String dateKey; // format: yyyy-mm-dd
  final String content;
  final DateTime updatedAt;

  WorkspaceNote({required this.dateKey, required this.content, required this.updatedAt});
}

class WorkspaceTask {
  final String id;
  final String dateKey;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  WorkspaceTask({required this.id, required this.dateKey, required this.title, this.isCompleted = false, required this.createdAt});

  WorkspaceTask copyWith({bool? isCompleted}) {
    return WorkspaceTask(
      id: id, 
      dateKey: dateKey, 
      title: title, 
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
    );
  }
}

class WorkspaceTimetableEvent {
  final String id;
  final String dateKey;
  final String title;
  final DateTime scheduledTime;

  WorkspaceTimetableEvent({required this.id, required this.dateKey, required this.title, required this.scheduledTime});
}

// --- STATE ---

class WorkspaceState {
  final Map<String, WorkspaceNote> notes; // dateKey -> content
  final List<WorkspaceTask> tasks;
  final List<WorkspaceTimetableEvent> timetable;

  WorkspaceState({this.notes = const {}, this.tasks = const [], this.timetable = const []});

  WorkspaceState copyWith({Map<String, WorkspaceNote>? notes, List<WorkspaceTask>? tasks, List<WorkspaceTimetableEvent>? timetable}) {
    return WorkspaceState(
      notes: notes ?? this.notes,
      tasks: tasks ?? this.tasks,
      timetable: timetable ?? this.timetable,
    );
  }
}

// --- NOTIFIER ---

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  Box? _notesBox;
  Box? _tasksBox;
  Box? _timetableBox;
  final _uuid = const Uuid();

  @override
  WorkspaceState build() {
    _initBoxes();
    return WorkspaceState();
  }

  Future<void> _initBoxes() async {
    _notesBox = await Hive.openBox('workspace_notes');
    _tasksBox = await Hive.openBox('workspace_tasks');
    _timetableBox = await Hive.openBox('workspace_timetable');
    _loadData();
  }

  void _loadData() {
    if (_notesBox == null || _tasksBox == null || _timetableBox == null) return;

    final Map<String, WorkspaceNote> loadedNotes = {};
    for (var key in _notesBox!.keys) {
      final val = _notesBox!.get(key);
      if (val is String) {
        try {
          final map = jsonDecode(val);
          loadedNotes[key.toString()] = WorkspaceNote(
            dateKey: map['dateKey'] ?? key.toString(),
            content: map['content'] ?? '',
            updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : DateTime.now(),
          );
        } catch (e) {
          loadedNotes[key.toString()] = WorkspaceNote(dateKey: key.toString(), content: val, updatedAt: DateTime.now());
        }
      } else if (val is Map) {
        loadedNotes[key.toString()] = WorkspaceNote(
          dateKey: val['dateKey'] ?? key.toString(),
          content: val['content'] ?? '',
          updatedAt: val['updatedAt'] != null ? DateTime.parse(val['updatedAt']) : DateTime.now(),
        );
      }
    }

    final List<WorkspaceTask> loadedTasks = [];
    for (var key in _tasksBox!.keys) {
      final data = _tasksBox!.get(key) as Map;
      loadedTasks.add(WorkspaceTask(
        id: data['id'],
        dateKey: data['dateKey'],
        title: data['title'],
        isCompleted: data['isCompleted'] ?? false,
        createdAt: data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now(),
      ));
    }

    final List<WorkspaceTimetableEvent> loadedTimetable = [];
    for (var key in _timetableBox!.keys) {
      final data = _timetableBox!.get(key) as Map;
      loadedTimetable.add(WorkspaceTimetableEvent(
        id: data['id'],
        dateKey: data['dateKey'],
        title: data['title'],
        scheduledTime: DateTime.parse(data['scheduledTime']),
      ));
    }

    state = state.copyWith(notes: loadedNotes, tasks: loadedTasks, timetable: loadedTimetable);
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // --- NOTES API ---
  void saveNote(DateTime date, String content) {
    if (_notesBox == null) return;
    final key = _getDateKey(date);
    final now = DateTime.now();
    
    _notesBox!.put(key, jsonEncode({
      'dateKey': key,
      'content': content,
      'updatedAt': now.toIso8601String(),
    }));
    
    final newNotes = Map<String, WorkspaceNote>.from(state.notes);
    newNotes[key] = WorkspaceNote(dateKey: key, content: content, updatedAt: now);
    state = state.copyWith(notes: newNotes);
  }

  WorkspaceNote? getNote(DateTime date) {
    return state.notes[_getDateKey(date)];
  }

  // --- TASKS API ---
  void addTask(DateTime date, String title) {
    if (_tasksBox == null) return;
    final id = _uuid.v4();
    final key = _getDateKey(date);
    final now = DateTime.now();
    
    final task = WorkspaceTask(id: id, dateKey: key, title: title, createdAt: now);
    _tasksBox!.put(id, {'id': id, 'dateKey': key, 'title': title, 'isCompleted': false, 'createdAt': now.toIso8601String()});
    
    state = state.copyWith(tasks: [...state.tasks, task]);
  }

  void toggleTask(String id) {
    if (_tasksBox == null) return;
    
    final index = state.tasks.indexWhere((t) => t.id == id);
    if (index >= 0) {
      final task = state.tasks[index];
      final updated = task.copyWith(isCompleted: !task.isCompleted);
      
      _tasksBox!.put(id, {
        'id': id, 
        'dateKey': task.dateKey, 
        'title': task.title, 
        'isCompleted': updated.isCompleted,
        'createdAt': task.createdAt.toIso8601String()
      });
      
      final newTasks = List<WorkspaceTask>.from(state.tasks);
      newTasks[index] = updated;
      state = state.copyWith(tasks: newTasks);
    }
  }

  void deleteTask(String id) {
    if (_tasksBox == null) return;
    _tasksBox!.delete(id);
    state = state.copyWith(tasks: state.tasks.where((t) => t.id != id).toList());
  }

  List<WorkspaceTask> getTasksForDate(DateTime date) {
    final key = _getDateKey(date);
    return state.tasks.where((t) => t.dateKey == key).toList();
  }

  // --- TIMETABLE API ---
  Future<void> addTimetableEvent(DateTime date, String title, TimeOfDay time) async {
    if (_timetableBox == null) return;
    
    final scheduledTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final id = _uuid.v4();
    final key = _getDateKey(date);
    
    final event = WorkspaceTimetableEvent(id: id, dateKey: key, title: title, scheduledTime: scheduledTime);
    _timetableBox!.put(id, {
      'id': id, 
      'dateKey': key, 
      'title': title, 
      'scheduledTime': scheduledTime.toIso8601String()
    });
    
    state = state.copyWith(timetable: [...state.timetable, event]);

    // Setup Notification Alarm!
    final notificationId = id.hashCode; 
    try {
      await NotificationService().scheduleNotification(
        id: notificationId,
        title: 'Workspace Reminder',
        body: title,
        scheduledTime: scheduledTime,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  void deleteTimetableEvent(String id) {
    if (_timetableBox == null) return;
    _timetableBox!.delete(id);
    state = state.copyWith(timetable: state.timetable.where((t) => t.id != id).toList());
    
    // Cancel notification
    NotificationService().cancelNotification(id.hashCode);
  }

  List<WorkspaceTimetableEvent> getTimetableForDate(DateTime date) {
    final key = _getDateKey(date);
    final events = state.timetable.where((t) => t.dateKey == key).toList();
    events.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return events;
  }
}

final workspaceProvider = NotifierProvider<WorkspaceNotifier, WorkspaceState>(() {
  return WorkspaceNotifier();
});
