import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class MatchScreen extends StatefulWidget {
  final String challengeId;
  final int poolIndex;
  final String creatorId;

  const MatchScreen({super.key, required this.challengeId, required this.poolIndex, required this.creatorId});

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  List<MatchEntry> matches = [];
  bool isLoading = false;
  bool isCreator = false;

  @override
  void initState() {
    super.initState();
    _checkIfCreator();
    _loadMatches();
  }

  Future<void> _checkIfCreator() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        isCreator = user.uid == widget.creatorId;
      });
    }
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text('Match Tracker'),
        actions: isCreator
            ? [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveMatches,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addMatch,
          ),
        ]
            : null,
      ),
      body: Stack(
        children: [
          // Background Image with full screen height
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height, // Ensure full screen height
            child: Image.asset(
              'assets/match_back.jpeg',
              fit: BoxFit.cover, // This ensures the image covers the entire area
            ),
          ),
          // Scrollable content
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Informative text
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Here you can track your match score. Don\'t forget to save!',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ...matches.asMap().entries.map((entry) {
                  return _buildMatchEntry(entry.value, entry.key);
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMatchEntry(MatchEntry match, int matchIndex) {
    return Card(
      color: Colors.grey[200],
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.deepOrangeAccent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10.0),
                topRight: Radius.circular(10.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: isCreator
                      ? () => _selectDateTime(context, match)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(9.0),
                    width: MediaQuery.of(context).size.width - 80,
                    child: Text(
                      match.dateTime != null
                          ? DateFormat('dd MMM yyyy, HH:mm').format(match.dateTime!)
                          : 'Click to select Date & Time',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (isCreator)
                  IconButton(
                    icon: const Icon(Icons.highlight_remove),
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
                    SizedBox(
                      width: 100,
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Player 1 Name'),
                        controller: match.player1Controller,
                        readOnly: !isCreator,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Player 2 Name'),
                        controller: match.player2Controller,
                        readOnly: !isCreator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 45),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...match.sets.asMap().entries.map((entry) {
                          int index = entry.key;
                          SetEntry set = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(right: 3, top: 10),
                            child: Column(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    controller: set.player1ScoreController,
                                    readOnly: !isCreator,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: 40,
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    controller: set.player2ScoreController,
                                    readOnly: !isCreator,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                if (isCreator)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle),
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
                        if (isCreator)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                match.addSet();
                              });
                            },
                            icon: const Icon(Icons.add),
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

  Future<void> _saveMatches() async {
    setState(() => isLoading = true);

    try {
      final poolDoc = FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challengeId)
          .collection('pools')
          .doc(widget.poolIndex.toString());

      for (var match in matches) {
        final matchData = {
          'dateTime': match.dateTime != null ? Timestamp.fromDate(match.dateTime!) : null,
          'player1Name': match.player1Controller.text,
          'player2Name': match.player2Controller.text,
          'sets': match.sets.map((set) {
            return {
              'player1Score': set.player1ScoreController.text,
              'player2Score': set.player2ScoreController.text,
            };
          }).toList(),
        };

        if (match.id != null) {
          await poolDoc.collection('matches').doc(match.id).set(matchData);
        } else {
          final newDoc = await poolDoc.collection('matches').add(matchData);
          match.id = newDoc.id;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Matches saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save matches: $e')),
      );
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