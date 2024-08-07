import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportify1/models/challenges.dart';
import 'package:sportify1/screens/pools_list_screen.dart';

class CompetitionScreen extends StatefulWidget {
  final Challenge challenge;
  final String creatorId;

  const CompetitionScreen({required this.challenge, required this.creatorId});

  @override
  _CompetitionScreenState createState() => _CompetitionScreenState();
}

class _CompetitionScreenState extends State<CompetitionScreen> {
  Map<int, List<Map<String, dynamic>>> pools = {};
  Map<String, int?> participantPoolMap = {}; // Track participant's current pool
  List<Map<String, dynamic>> participants = [];
  List<Map<String, dynamic>> filteredParticipants = [];
  bool isLoading = false;
  List<String> selectedParticipantIds = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchParticipantsAndPools();
  }

  Future<void> _fetchParticipantsAndPools() async {
    setState(() => isLoading = true);

    try {
      final challengeDoc = FirebaseFirestore.instance.collection('challenges').doc(widget.challenge.id);

      // Fetch participants
      final participantsSnapshot = await challengeDoc.collection('participants').get();
      participants = participantsSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'] as String,
      }).toList();
      filteredParticipants = participants;

      // Initialize participantPoolMap
      participantPoolMap = {for (var p in participants) p['id']: null};

      // Fetch existing pools
      final docSnapshot = await challengeDoc.get();
      if (docSnapshot.exists && docSnapshot.data()!.containsKey('pools')) {
        final poolsData = docSnapshot['pools'] as Map<String, dynamic>;
        pools = poolsData.map((key, value) {
          return MapEntry(int.parse(key), (value as List<dynamic>).map((id) {
            final participant = participants.firstWhere((p) => p['id'] == id);
            participantPoolMap[id] = int.parse(key);
            return participant;
          }).toList());
        });
      }
    } catch (e) {
      print('Error fetching participants and pools: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _addPool() {
    setState(() {
      final newPoolIndex = (pools.keys.isEmpty ? 0 : pools.keys.reduce((a, b) => a > b ? a : b) + 1);
      pools[newPoolIndex] = [];
      _savePools();
    });
  }

  void _removePool(int poolIndex) {
    setState(() {
      pools.remove(poolIndex);
      _savePools();
    });
  }

  void _assignToPool(int poolIndex) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Assign Participants to Pool ${poolIndex + 1}'),
          content: Container(
            width: double.maxFinite, // Ensure the container takes up available width
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Participants
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        labelText: 'Search Participants',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (query) {
                        setState(() {
                          filteredParticipants = participants.where((participant) {
                            return participant['name'].toLowerCase().contains(query.toLowerCase());
                          }).toList();
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    // Participants List with Checkboxes
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredParticipants.length,
                        itemBuilder: (context, index) {
                          final participant = filteredParticipants[index];
                          return CheckboxListTile(
                            title: Text(participant['name']),
                            value: selectedParticipantIds.contains(participant['id']),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedParticipantIds.add(participant['id']);
                                } else {
                                  selectedParticipantIds.remove(participant['id']);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _handleAssignToPool(poolIndex);
                Navigator.of(context).pop();
              },
              child: Text('Assign'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _handleAssignToPool(int poolIndex) {
    setState(() {
      final selectedParticipants = participants.where((p) => selectedParticipantIds.contains(p['id'])).toList();

      // Remove participants from their current pool
      for (var participant in selectedParticipants) {
        final currentPoolIndex = participantPoolMap[participant['id']];
        if (currentPoolIndex != null && currentPoolIndex != poolIndex) {
          pools[currentPoolIndex]?.removeWhere((p) => p['id'] == participant['id']);
        }
        // Assign participant to the new pool
        participantPoolMap[participant['id']] = poolIndex;
      }

      // Add participants to the new pool, avoid duplicates
      pools.putIfAbsent(poolIndex, () => []);
      for (var participant in selectedParticipants) {
        if (!pools[poolIndex]!.any((p) => p['id'] == participant['id'])) {
          pools[poolIndex]!.add(participant);
        }
      }
      selectedParticipantIds.clear();
      _savePools();
    });
  }

  Future<void> _savePools() async {
    try {
      final challengeDoc = FirebaseFirestore.instance.collection('challenges').doc(widget.challenge.id);

      // Prepare new pool data
      final newPoolData = pools.map((poolIndex, participants) {
        return MapEntry(poolIndex.toString(), participants.map((p) => p['id']).toList());
      });

      // Update or add the pools field
      await challengeDoc.update({
        'pools': newPoolData,
      });

      // Optionally, also update participantPoolMap in Firestore if needed
      for (var entry in participantPoolMap.entries) {
        final participantDoc = challengeDoc.collection('participants').doc(entry.key);
        await participantDoc.update({'poolId': entry.value});
      }
    } catch (e) {
      print('Error saving pools: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Competition: ${widget.challenge.title}')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Pool Management UI
            Row(
              children: [
                Expanded(child: Text('Manage Pools', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addPool,
                  tooltip: 'Add Pool',
                ),
              ],
            ),
            ...pools.entries.map((entry) {
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Pool ${entry.key + 1}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _assignToPool(entry.key),
                        tooltip: 'Edit Pool ${entry.key + 1}',
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle),
                        onPressed: () => _removePool(entry.key),
                        tooltip: 'Remove Pool',
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            SizedBox(height: 16),

            // Display Final Pools
            Text('Final Pools', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ...pools.entries.map((entry) {
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
                            child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...entry.value.map((participant) {
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(participant['name']),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              );
            }).toList(),

            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _savePools(); // Save pools before navigating
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PoolsListScreen(challengeId: widget.challenge.id, creatorId: widget.creatorId),
                  ),
                );
              },
              child: Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}