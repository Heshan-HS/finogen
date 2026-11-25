import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/workspace_provider.dart';
import 'dart:async';

class NotesCard extends ConsumerStatefulWidget {
  final DateTime selectedDay;
  const NotesCard({super.key, required this.selectedDay});

  @override
  ConsumerState<NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends ConsumerState<NotesCard> {
  late TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didUpdateWidget(NotesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay) {
      _loadNote();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadNote();
  }

  void _loadNote() {
    final note = ref.read(workspaceProvider.notifier).getNote(widget.selectedDay);
    if (_controller.text != (note?.content ?? '')) {
      _controller.text = note?.content ?? '';
    }
  }

  void _onTextChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      ref.read(workspaceProvider.notifier).saveNote(widget.selectedDay, value);
    });
  }

  void _saveNoteManually() {
    ref.read(workspaceProvider.notifier).saveNote(widget.selectedDay, _controller.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Note Saved Successfully!'), duration: Duration(seconds: 1)),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<WorkspaceState>(workspaceProvider, (previous, next) {
      final String dateKey = '${widget.selectedDay.year}-${widget.selectedDay.month.toString().padLeft(2, '0')}-${widget.selectedDay.day.toString().padLeft(2, '0')}';
      final note = next.notes[dateKey];
      final previousNote = previous?.notes[dateKey];
      
      if (note?.content != previousNote?.content) {
        if (_controller.text != (note?.content ?? '')) {
          _controller.text = note?.content ?? '';
        }
      }
    });

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
              Text('Quick Notes', style: TextStyle(color: AppColors.accent(context), fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(workspaceProvider);
                      final String dateKey = '${widget.selectedDay.year}-${widget.selectedDay.month.toString().padLeft(2, '0')}-${widget.selectedDay.day.toString().padLeft(2, '0')}';
                      final note = state.notes[dateKey];
                      if (note == null) return Text('${widget.selectedDay.day}/${widget.selectedDay.month}  ', style: TextStyle(color: AppColors.muted(context)));
                      return Text(
                        'Last saved: ${note.updatedAt.hour.toString().padLeft(2, '0')}:${note.updatedAt.minute.toString().padLeft(2, '0')}  ',
                        style: TextStyle(color: AppColors.muted(context), fontSize: 11),
                      );
                    }
                  ),
                  ElevatedButton.icon(
                    icon: Icon(LucideIcons.save, color: AppColors.accentFg(context), size: 16),
                    label: Text('Save', style: TextStyle(color: AppColors.accentFg(context))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: AppColors.accentFg(context),
                      minimumSize: const Size(80, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: _saveNoteManually,
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              style: TextStyle(color: AppColors.text(context), height: 1.5),
              decoration: InputDecoration(
                hintText: 'Write down your thoughts...',
                hintStyle: TextStyle(color: AppColors.muted(context).withOpacity(0.5)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _onTextChanged,
            ),
          ),
        ],
      ),
    );
  }
}
