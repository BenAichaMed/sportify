import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MatchScreen extends StatefulWidget {
  final String challengeId;
  final int poolIndex;
  final String creatorId;

  const MatchScreen({required this.challengeId, required this.poolIndex, required this.creatorId});

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  List<MatchEntry> matches = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => isLoading = true);

    try {
      final matchSnapshot = await FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challengeId)
          .collection('pools')
          .doc(widget.poolIndex.toString())
          .collection('matches')
          .get();

      setState(() {
        matches = matchSnapshot.docs.map((doc) {
          return MatchEntry(
            id: doc.id,
            dateTime: doc['dateTime'] != null ? (doc['dateTime'] as Timestamp).toDate() : null,
            player1Name: doc['player1Name'],
            player2Name: doc['player2Name'],
            sets: (doc['sets'] as List<dynamic>).map((set) {
              return SetEntry(
                player1Score: set['player1Score'],
                player2Score: set['player2Score'],
              );
            }).toList(),
          );
        }).toList();
      });
    } catch (e) {
      print('Error loading matches: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveMatches() async {
    setState(() => isLoading = true);

    try {
      final poolDoc = FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challengeId)
          .collection('pools')
          .doc(widget.poolIndex.toString());

      for (var match in matches) {
        final matchDoc = poolDoc.collection('matches').doc(match.id);
        await matchDoc.set({
          'dateTime': match.dateTime,
          'player1Name': match.player1Controller.text,
          'player2Name': match.player2Controller.text,
          'sets': match.sets.map((set) {
            return {
              'player1Score': set.player1ScoreController.text,
              'player2Score': set.player2ScoreController.text,
            };
          }).toList(),
        });
        match.id = matchDoc.id;
        match.isSaved = true;
      }
    } catch (e) {
      print('Error saving matches: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _addMatch() {
    setState(() {
      matches.add(MatchEntry(id: DateTime.now().millisecondsSinceEpoch.toString()));
    });
  }

  void _removeMatch(int index) async {
    final match = matches[index];
    if (match.id != null) {
      try {
        final poolDoc = FirebaseFirestore.instance
            .collection('challenges')
            .doc(widget.challengeId)
            .collection('pools')
            .doc(widget.poolIndex.toString());
        await poolDoc.collection('matches').doc(match.id).delete();
      } catch (e) {
        print('Error deleting match: $e');
      }
    }
    setState(() {
      matches.removeAt(index);
    });
  }

  Future<void> _selectDateTime(BuildContext context, MatchEntry match) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          match.dateTime = DateTime(
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
      appBar: AppBar(
        title: Text('Matches'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveMatches,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addMatch,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return _buildMatchEntry(matches[index], index);
        },
      ),
    );
  }

  Widget _buildMatchEntry(MatchEntry match, int matchIndex) {
    return Card(
      color: Colors.grey[200],
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _selectDateTime(context, match),
                  child: Container(
                    padding: EdgeInsets.all(9.0),
                    width: MediaQuery.of(context).size.width - 80,
                    child: Text(
                      match.dateTime != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(match.dateTime!)
                          : 'Click to select Date & Time',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.highlight_remove),
                  onPressed: () => _removeMatch(matchIndex),
                  color: Colors.white,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 100,
                      child: TextField(
                        decoration: InputDecoration(labelText: 'Player 1 Name'),
                        controller: match.player1Controller,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: 100,
                      child: TextField(
                        decoration: InputDecoration(labelText: 'Player 2 Name'),
                        controller: match.player2Controller,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 45),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...match.sets.asMap().entries.map((entry) {
                          int index = entry.key;
                          SetEntry set = entry.value;
                          return Container(
                            margin: EdgeInsets.only(right: 3, top: 10),
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    controller: set.player1ScoreController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Container(
                                  width: 40,
                                  child: TextField(
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    controller: set.player2ScoreController,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove_circle),
                                  onPressed: () {
                                    setState(() {
                                      match.removeSet(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              match.addSet();
                            });
                          },
                          icon: Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MatchEntry {
  String? id;
  DateTime? dateTime;
  final player1Controller = TextEditingController();
  final player2Controller = TextEditingController();
  List<SetEntry> sets = [SetEntry()];
  bool isSaved = false;

  MatchEntry({
    required this.id,
    this.dateTime,
    String? player1Name,
    String? player2Name,
    List<SetEntry>? sets,
  }) {
    if (player1Name != null) player1Controller.text = player1Name;
    if (player2Name != null) player2Controller.text = player2Name;
    if (sets != null) this.sets = sets;
  }

  void addSet() {
    sets.add(SetEntry());
  }

  void removeSet(int index) {
    if (sets.length > 1) {
      sets.removeAt(index);
    }
  }
}

class SetEntry {
  final player1ScoreController = TextEditingController();
  final player2ScoreController = TextEditingController();

  SetEntry({
    String? player1Score,
    String? player2Score,
  }) {
    if (player1Score != null) player1ScoreController.text = player1Score;
    if (player2Score != null) player2ScoreController.text = player2Score;
  }
}
