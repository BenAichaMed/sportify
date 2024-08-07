import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sportify1/models/challenges.dart';
import 'package:sportify1/screens/running_details.dart';
import 'package:sportify1/screens/create_challenge_screen.dart';
import 'package:sportify1/screens/tennis_details.dart';
import 'package:sportify1/widgets/categoryButton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportify1/models/user.dart' as CustomUser;

class ChallengesListScreen extends StatefulWidget {
  const ChallengesListScreen({Key? key}) : super(key: key);

  @override
  _ChallengesListScreenState createState() => _ChallengesListScreenState();
}

class _ChallengesListScreenState extends State<ChallengesListScreen> {
  String selectedCategory = 'All';
  final user = FirebaseAuth.instance.currentUser;
  String? currentUsername;

  Map<String, String> categoryImages = {
    'All': 'assets/all.jpg',
    'Running': 'assets/running.jpeg',
    'Cycling': 'assets/cycling.jpeg',
    'Tennis': 'assets/tennis.jpeg',
    // Add more category images as needed
  };

  @override
  void initState() {
    super.initState();
    _deletePastChallenges();
    _fetchCurrentUsername();
  }

  Future<void> _fetchCurrentUsername() async {
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      final customUser = CustomUser.User.fromSnap(userDoc);
      setState(() {
        currentUsername = customUser.username;
      });
    }
  }

  Future<void> _deletePastChallenges() async {
    final now = DateTime.now();
    final querySnapshot = await FirebaseFirestore.instance
        .collection('challenges')
        .where('dateTime', isLessThan: now)
        .get();

    for (var doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
  }

  void _deleteChallenge(String challengeId) {
    FirebaseFirestore.instance
        .collection('challenges')
        .doc(challengeId)
        .delete()
        .then((_) {
      print('Challenge deleted successfully');
    }).catchError((error) {
      print('Failed to delete challenge: $error');
    });
  }

  void _reportChallenge(String challengeId) {
    FirebaseFirestore.instance
        .collection('reports')
        .add({
      'challengeId': challengeId,
      'reportedBy': user?.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Pending',
    })
        .then((_) {
      print('Challenge reported successfully');
    })
        .catchError((error) {
      print('Failed to report challenge: $error');
    });
  }

  Widget _buildChallengeCard(Challenge challenge) {
    return Card(
      elevation: 8,
      shadowColor: Colors.black,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              challenge.title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.deepOrangeAccent
              ),
            ),
            if (challenge is TennisChallenge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: challenge.challengeType == 'Competition'
                      ? Colors.redAccent
                      : Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  challenge.challengeType,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '${challenge.category} - ${DateFormat('d MMMM yyyy \'at\' h:mm a').format(challenge.dateTime)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text('Created by: ${challenge.creatorName}'),
            SizedBox(height: 8),
            Text(challenge.description),
          ],
        ),
        trailing: user!.uid == challenge.creatorId
            ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.delete),
              color: Colors.red,
              onPressed: () => _deleteChallenge(challenge.id),
            ),
            IconButton(
              icon: Icon(Icons.report),
              color: Colors.orange,
              onPressed: () => _reportChallenge(challenge.id),
            ),
          ],
        )
            : IconButton(
          icon: Icon(Icons.report),
          color: Colors.orange,
          onPressed: () => _reportChallenge(challenge.id),
        ),
        onTap: () {
          switch (challenge.category) {
            case 'Running':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RunningChallengeDetailScreen(challenge: challenge),
                ),
              );
              break;
            case 'Tennis':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TennisChallengeDetailScreen(challenge: challenge as TennisChallenge),
                ),
              );
              break;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CategoryButton(
                  category: 'All',
                  isSelected: selectedCategory == 'All',
                  onTap: () {
                    setState(() {
                      selectedCategory = 'All';
                    });
                  },
                ),
                CategoryButton(
                  category: 'Running',
                  isSelected: selectedCategory == 'Running',
                  onTap: () {
                    setState(() {
                      selectedCategory = 'Running';
                    });
                  },
                ),
                CategoryButton(
                  category: 'Cycling',
                  isSelected: selectedCategory == 'Cycling',
                  onTap: () {
                    setState(() {
                      selectedCategory = 'Cycling';
                    });
                  },
                ),
                CategoryButton(
                  category: 'Tennis',
                  isSelected: selectedCategory == 'Tennis',
                  onTap: () {
                    setState(() {
                      selectedCategory = 'Tennis';
                    });
                  },
                ),
                // Add more category buttons as needed
              ],
            ),
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
            child: Image.asset(
              categoryImages[selectedCategory]!,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('challenges').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No challenges found.'));
                }

                var challenges = snapshot.data!.docs.map((doc) => Challenge.fromMap(doc.data() as Map<String, dynamic>)).toList();

                if (selectedCategory != 'All') {
                  challenges = challenges.where((challenge) => challenge.category == selectedCategory).toList();
                }

                return ListView.builder(
                  itemCount: challenges.length,
                  itemBuilder: (context, index) {
                    final challenge = challenges[index];
                    return _buildChallengeCard(challenge);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateChallengeScreen()),
          );
        },
        child: const Icon(Icons.add),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        backgroundColor: Colors.deepOrangeAccent,
      ),
    );
  }
}