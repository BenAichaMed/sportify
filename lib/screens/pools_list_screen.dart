import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportify1/screens/match_screen.dart';

class PoolsListScreen extends StatelessWidget {
  final String challengeId;
  final String creatorId;

  const PoolsListScreen({super.key, required this.challengeId, required this.creatorId});

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
          participant['score'] = participantDoc['score']; // Fetch score from Firestore
        }
      }

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

    await participantDoc.update({'score': newScore}); // Save score to Firestore
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
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: const Text('Pools List'),
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/pools_back.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Scrollable Content
          FutureBuilder<Map<int, List<Map<String, dynamic>>>>(
            future: _fetchPools(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No pools found.'));
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
                      margin: const EdgeInsets.all(8.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      color: Colors.white60,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pool ${poolIndex + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Table(
                              columnWidths: const {
                                0: FixedColumnWidth(49.0),
                                1: FlexColumnWidth(),
                                2: FixedColumnWidth(80.0),
                              },
                              border: TableBorder(
                                verticalInside: BorderSide(color: Colors.black),
                              ),
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(color: Colors.deepOrangeAccent),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
                                        child: Text(rank.toString(), style: const TextStyle(color: Colors.black)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(participant['name'], style: const TextStyle(color: Colors.black,fontWeight: FontWeight.bold)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: _isCreator(userId!)
                                            ? TextField(
                                          style: const TextStyle(color: Colors.black),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.grey[300],
                                            contentPadding: const EdgeInsets.only(left: 10.0),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8.0),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          controller: TextEditingController(text: participant['score'].toString()),
                                          onChanged: (value) {
                                            _updateScore(participant['id'], int.tryParse(value) ?? 0);
                                          },
                                        )
                                            : Text(participant['score'].toString(), style: const TextStyle(color: Colors.black)),
                                      ),
                                    ],
                                  );
                                }),
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
        ],
      ),
    );
  }
}
