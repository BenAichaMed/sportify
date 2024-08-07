import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportify1/screens/match_screen.dart';

class PoolsListScreen extends StatelessWidget {
  final String challengeId;
  final String creatorId;

  const PoolsListScreen({required this.challengeId, required this.creatorId});

  bool _isCreator(String userId) {
    return userId == creatorId;
  }

  Future<Map<int, List<Map<String, dynamic>>>> _fetchPools() async {
    final challengeDoc = FirebaseFirestore.instance.collection('challenges').doc(challengeId);
    final docSnapshot = await challengeDoc.get();

    if (docSnapshot.exists) {
      final poolsData = docSnapshot['pools'] as Map<String, dynamic>;
      final pools = poolsData.map((key, value) {
        return MapEntry(int.parse(key), (value as List<dynamic>).map((id) => {'id': id}).toList());
      });

      for (var pool in pools.entries) {
        for (var participant in pool.value) {
          final participantDoc = await challengeDoc.collection('participants').doc(participant['id']).get();
          participant['name'] = participantDoc['name'];
          participant['score'] = participantDoc['score']; // Assuming score is part of participant data
        }
      }

      // Sort participants within each pool by score in descending order
      pools.forEach((key, value) {
        value.sort((a, b) => b['score'].compareTo(a['score']));
      });

      return pools;
    } else {
      return {};
    }
  }

  Future<void> _updateScore(String participantId, int newScore) async {
    final challengeDoc = FirebaseFirestore.instance.collection('challenges').doc(challengeId);
    final participantDoc = challengeDoc.collection('participants').doc(participantId);

    await participantDoc.update({'score': newScore});
  }

  void _navigateToMatchScreen(BuildContext context, int poolIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MatchScreen(challengeId: challengeId, poolIndex: poolIndex, creatorId: creatorId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Pools List')),
      body: FutureBuilder<Map<int, List<Map<String, dynamic>>>>(
        future: _fetchPools(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No pools found.'));
          }

          final pools = snapshot.data!;
          return ListView.builder(
            itemCount: pools.keys.length,
            itemBuilder: (context, index) {
              final poolIndex = pools.keys.elementAt(index);
              final poolParticipants = pools[poolIndex] ?? [];

              return GestureDetector(
                onTap: () => _navigateToMatchScreen(context, poolIndex),
                child: Card(
                  margin: EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pool ${poolIndex + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 3),
                        Table(
                          columnWidths: {
                            0: FixedColumnWidth(49.0),
                            1: FlexColumnWidth(),
                            2: FixedColumnWidth(55.0),
                          },
                          border: TableBorder.all(),
                          children: [
                            TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            ...poolParticipants.asMap().entries.map((entry) {
                              final rank = entry.key + 1;
                              final participant = entry.value;
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(rank.toString()),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(participant['name']),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: _isCreator(userId!)
                                        ? TextField(
                                      controller: TextEditingController(text: participant['score'].toString()),
                                      keyboardType: TextInputType.number,
                                      onSubmitted: (value) {
                                        _updateScore(participant['id'], int.parse(value));
                                      },
                                    )
                                        : Text(participant['score'].toString()),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}