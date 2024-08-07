import 'package:flutter/material.dart';

class ScheduleScreen extends StatefulWidget {
  final Map<int, List<Map<String, dynamic>>> pools;

  const ScheduleScreen({required this.pools});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  Map<int, List<Map<String, dynamic>>> matches = {};

  @override
  void initState() {
    super.initState();
    _generateMatches();
  }

  void _generateMatches() {
    widget.pools.forEach((poolId, participants) {
      matches[poolId] = [];
      for (int i = 0; i < participants.length; i++) {
        for (int j = i + 1; j < participants.length; j++) {
          matches[poolId]!.add({
            'player1': participants[i]['name'],
            'player2': participants[j]['name'],
            'date': DateTime.now(),
          });
        }
      }
    });
  }

  Future<void> _pickDateTime(BuildContext context, int poolId, int matchIndex) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          matches[poolId]![matchIndex]['date'] = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Schedule')),
      body: SingleChildScrollView(
        child: Column(
          children: matches.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pool ${entry.key + 1}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Table(
                  border: TableBorder.all(),
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Player 1', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Player 2', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...entry.value.map((match) {
                      int matchIndex = entry.value.indexOf(match);
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(match['player1']),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(match['player2']),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: GestureDetector(
                              onTap: () => _pickDateTime(context, entry.key, matchIndex),
                              child: Text(
                                '${match['date'].day}/${match['date'].month}/${match['date'].year} at ${match['date'].hour}:${match['date'].minute}',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}