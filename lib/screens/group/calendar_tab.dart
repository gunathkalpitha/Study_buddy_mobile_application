
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';

class CalendarTab extends ConsumerStatefulWidget {
  final String groupId;

  const CalendarTab({super.key, required this.groupId});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<EventModel> _getEventsForDay(List<EventModel> allEvents, DateTime day) {
    return allEvents.where((event) {
      return isSameDay(event.date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(groupEventsProvider(widget.groupId));

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context, ref),
        child: const Icon(Icons.event),
      ),
      body: eventsAsync.when(
        data: (events) {
          final selectedEvents = _getEventsForDay(events, _selectedDay!);

          return Column(
            children: [
              TableCalendar<EventModel>(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                eventLoader: (day) => _getEventsForDay(events, day),
                calendarStyle: CalendarStyle(
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedEvents.length,
                  itemBuilder: (context, index) {
                    final event = selectedEvents[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          event.type == 'exam' ? Icons.assignment_late : Icons.menu_book,
                          color: event.type == 'exam' ? Colors.red : Colors.blue,
                        ),
                        title: Text(event.title),
                        subtitle: Text(event.description),
                        trailing: Text(DateFormat.jm().format(event.date)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Event'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Event Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Time: '),
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
                      child: Text(selectedTime.format(context)),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  if (titleController.text.isNotEmpty) {
                    final user = ref.read(currentUserProvider);
                    if (user != null) {
                      final date = DateTime(
                        _selectedDay!.year,
                        _selectedDay!.month,
                        _selectedDay!.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                      
                      final newEvent = EventModel(
                        id: const Uuid().v4(),
                        title: titleController.text,
                        description: descController.text,
                        date: date,
                        type: 'study',
                        createdBy: user.id,
                      );
                      
                      await ref.read(repositoryProvider).addEvent(widget.groupId, newEvent);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }
}
