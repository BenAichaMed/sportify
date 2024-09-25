import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportify1/models/challenges.dart';
import 'package:sportify1/screens/pools_list_screen.dart';

class CompetitionScreen extends StatefulWidget {
  final Challenge challenge;
  final String creatorId;

  const CompetitionScreen(
      {super.key, required this.challenge, required this.creatorId});

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _fetchParticipantsAndPools() async {
    setState(() => isLoading = true);

    try {
      final challengeDoc = FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challenge.id);

      // Fetch participants
      final participantsSnapshot =
      await challengeDoc.collection('participants').get();
      participants = participantsSnapshot.docs
          .map((doc) =>
      {
        'id': doc.id,
        'name': doc['name'] as String,
      })
          .toList();
      filteredParticipants = participants;

      // Initialize participantPoolMap
      participantPoolMap = {for (var p in participants) p['id']: null};

      // Fetch existing pools
      final docSnapshot = await challengeDoc.get();
      if (docSnapshot.exists && docSnapshot.data()!.containsKey('pools')) {
        final poolsData = docSnapshot['pools'] as Map<String, dynamic>;
        pools = poolsData.map((key, value) {
          return MapEntry(
              int.parse(key),
              (value as List<dynamic>).map((id) {
                final participant =
                participants.firstWhere((p) => p['id'] == id);
                participantPoolMap[id] = int.parse(key);
                return participant;
              }).toList());
        });
      }
    } catch (e) {
      _showError('Error fetching participants and pools: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _savePools() async {
    try {
      final challengeDoc = FirebaseFirestore.instance
          .collection('challenges')
          .doc(widget.challenge.id);

      // Prepare new pool data
      final newPoolData = pools.map((poolIndex, participants) {
        return MapEntry(
            poolIndex.toString(), participants.map((p) => p['id']).toList());
      });

      // Update or add the pools field
      await challengeDoc.update({
        'pools': newPoolData,
      });

      // Optionally, also update participantPoolMap in Firestore if needed
      for (var entry in participantPoolMap.entries) {
        final participantDoc =
        challengeDoc.collection('participants').doc(entry.key);
        await participantDoc.update({'poolId': entry.value});
      }
    } catch (e) {
      _showError('Error saving pools: $e');
    }
  }

  void _addPool() {
    setState(() {
      final newPoolIndex = (pools.keys.isEmpty
          ? 0
          : pools.keys.reduce((a, b) => a > b ? a : b) + 1);
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
          backgroundColor: Colors.grey[900], // Dark background
          title: Text(
            'Assign Participants to Pool ${poolIndex + 1}',
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search Participants with a cleaner design
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[850],
                        labelText: 'Search Participants',
                        labelStyle: const TextStyle(color: Colors.white),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (query) {
                        setState(() {
                          filteredParticipants = participants.where((participant) {
                            return participant['name']
                                .toLowerCase()
                                .contains(query.toLowerCase());
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Participants List with Checkboxes and improved spacing and design
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredParticipants.length,
                        itemBuilder: (context, index) {
                          final participant = filteredParticipants[index];
                          return Card(
                            color: Colors.grey[850],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: CheckboxListTile(
                              title: Text(
                                participant['name'],
                                style: const TextStyle(color: Colors.white),
                              ),
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
                              checkColor: Colors.white,
                              activeColor: Colors.blueAccent,
                            ),
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
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
              child: const Text('Assign'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }


  void _handleAssignToPool(int poolIndex) {
    setState(() {
      final selectedParticipants = participants
          .where((p) => selectedParticipantIds.contains(p['id']))
          .toList();

      // Remove participants from their current pool
      for (var participant in selectedParticipants) {
        final currentPoolIndex = participantPoolMap[participant['id']];
        if (currentPoolIndex != null && currentPoolIndex != poolIndex) {
          pools[currentPoolIndex]
              ?.removeWhere((p) => p['id'] == participant['id']);
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.deepOrange,
          title: Text('Competition: ${widget.challenge.title}')),
      body: Stack(
        children: [
          // Full-Screen Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/competition_back.jpg', // Replace with your image path
              fit: BoxFit.cover,
            ),
          ),
          // Main Content
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            SingleChildScrollView(
              child: Container(
                // Ensures the container takes full height of the screen
                height: MediaQuery.of(context).size.height,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Pool Management UI
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Manage Pools',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.white),
                          onPressed: _addPool,
                          tooltip: 'Add Pool',
                        ),
                      ],
                    ),

                    // Scrollable Box for Display Pools
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: pools.entries.map((entry) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6.0,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueAccent,
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                title: Text(
                                  'Pool ${entry.key + 1}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${entry.value.length} participants',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                      onPressed: () => _assignToPool(entry.key),
                                      tooltip: 'Edit Pool ${entry.key + 1}',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                                      onPressed: () => _removePool(entry.key),
                                      tooltip: 'Remove Pool',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),


                    // Title for Final Pools
                    const Text(
                      'Final Pools',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    // Scrollable Box for Final Pools
                    Expanded( // This ensures that the list of final pools is scrollable while taking remaining space
                      child: SingleChildScrollView(
                        child: Column(
                          children: pools.entries.map((entry) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.black87, // Dark background for contrast
                                borderRadius: BorderRadius.circular(10.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4.0,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Pool Title with Background
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Text(
                                      'Pool ${entry.key + 1}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Table for Participants
                                  Table(
                                    border: TableBorder.all(color: Colors.white54, width: 1),
                                    columnWidths: const {0: FlexColumnWidth()},
                                    children: [
                                      const TableRow(
                                        decoration: BoxDecoration(color: Colors.blueGrey),
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'Name',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      ...entry.value.map((participant) {
                                        return TableRow(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Text(
                                                participant['name'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(1.0),
        child: ElevatedButton(

          onPressed: () async {
            await _savePools(); // Save pools before navigating
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PoolsListScreen(
                    challengeId: widget.challenge.id,
                    creatorId: widget.creatorId),
              ),
            );
          },
          child: const Text('Next', style: TextStyle(fontSize: 18,color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrangeAccent[400],
            minimumSize: const Size(double.infinity, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}