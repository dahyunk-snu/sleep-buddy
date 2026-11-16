import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sleepy/src/core/models/problematic_event.dart';

/// 이상행동 리스트 에디터
class EventEditorList extends StatelessWidget {
  const EventEditorList({
    super.key,
    required this.events,
    required this.baseDate,
    required this.onChanged,
    required this.hhmm,
  });

  final List<ProblematicEvent> events;
  final DateTime baseDate;
  final ValueChanged<List<ProblematicEvent>> onChanged;
  final DateFormat hhmm;

  @override
  Widget build(BuildContext context) {
    final list = List<ProblematicEvent>.from(events);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (list.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('추가된 이상행동이 없습니다.'),
          ),
        ...list.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_note),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<ProblematicEventType>(
                          value: e.type,
                          isExpanded: true,
                          items: ProblematicEventType.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.displayName),
                                ),
                              )
                              .toList(),
                          onChanged: (t) {
                            if (t == null) return;
                            list[i] = ProblematicEvent(
                              type: t,
                              time: e.time,
                              note: e.note,
                            );
                            onChanged(List.of(list));
                          },
                          decoration: const InputDecoration(
                            labelText: '이상행동 종류',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        fit: FlexFit.loose,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: e.time != null
                                    ? TimeOfDay.fromDateTime(e.time!)
                                    : TimeOfDay.now(),
                                initialEntryMode: TimePickerEntryMode.dial,
                              );
                              if (picked != null && context.mounted) {
                                final dt = DateTime(
                                  baseDate.year,
                                  baseDate.month,
                                  baseDate.day,
                                  picked.hour,
                                  picked.minute,
                                );
                                list[i] = ProblematicEvent(
                                  type: e.type,
                                  time: dt,
                                  note: e.note,
                                );
                                onChanged(List.of(list));
                              }
                            },
                            icon: const Icon(Icons.schedule),
                            label: Text(
                              e.time != null ? hhmm.format(e.time!) : '시간 선택',
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ), // ⬅️ 컴팩트
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: e.note ?? '',
                    onChanged: (v) {
                      list[i] = ProblematicEvent(
                        type: e.type,
                        time: e.time,
                        note: v,
                      );
                      onChanged(List.of(list));
                    },
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: '메모(선택 입력)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        list.removeAt(i);
                        onChanged(List.of(list));
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('삭제'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            list.add(const ProblematicEvent(type: ProblematicEventType.noise));
            onChanged(List.of(list));
          },
          icon: const Icon(Icons.add),
          label: const Text('이상행동 추가'),
        ),
      ],
    );
  }
}
