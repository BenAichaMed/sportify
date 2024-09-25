import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sportify1/models/challenges.dart';
import 'package:sportify1/screens/chat.dart';
import 'package:sportify1/models/user.dart' as CustomUser;
import 'package:sportify1/screens/pools_list_screen.dart';
import 'package:sportify1/screens/competetion_screen.dart';
import 'package:sportify1/screens/normal_game_screen.dart';
import 'package:sportify1/models/participant.dart';
import 'package:intl/intl.dart';

class TennisChallengeDetailScreen extends StatefulWidget {
  final TennisChallenge challenge;

  const TennisChallengeDetailScreen({super.key, required this.challenge});

  @override
  _TennisChallengeDetailScreen createState() => _TennisChallengeDetailScreen();
}

class _TennisChallengeDetailScreen extends State<TennisChallengeDetailScreen> {
  bool isJoined = false;
  bool isLoading = false;
  bool isCreator = false;
  String username = '';
  String creatorName = '';
  String creatorPhotoUrl = '';
  Duration timeLeft = const Duration();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _checkIfJoined();
    _fetchUsername();
    _fetchParticipantCount();
    _fetchCreatorDetails();
    _startCountdown();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    final eventDateTime = widget.challenge.dateTime;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newTimeLeft = eventDateTime.difference(DateTime.now());
      setState(() {
        timeLeft = newTimeLeft;
        if (timeLeft.isNegative) {
          timer.cancel();
        }
      });
    });
  }

  String getCountdownText() {
    if (timeLeft.isNegative) return '0d 0h 0m 0s';
    final days = timeLeft.inDays;
    final hours = timeLeft.inHours % 24;
    final minutes = timeLeft.inMinutes % 60;
    final seconds = timeLeft.inSeconds % 60;
    return '${days}d ${hours}h ${minutes}m ${seconds}s';
  }

  Future<void> _checkIfJoined() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final docSnapshot = await FirebaseFirestore.instance
        .collection('challenges')
        .doc(widget.challenge.id)
        .collection('participants')
        .doc(userId)
        .get();

    if (docSnapshot.exists) {
      setState(() {
        isJoined = true;
      });
    }
  }

  Future<void> _fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final customUser = CustomUser.User.fromSnap(userDoc);
      setState(() {
        username = customUser.username;
        isCreator = user.uid == widget.challenge.creatorId;
      });
    }
  }

  Future<void> _fetchParticipantCount() async {
    final challengeDocRef = FirebaseFirestore.instance
        .collection('challenges')
        .doc(widget.challenge.id);
    final challengeSnapshot = await challengeDocRef.get();
    final participantsList =
    List<String>.from(challengeSnapshot.data()?['participants'] ?? []);
    setState(() {
      widget.challenge.participants = participantsList;
    });
  }

  Future<void> _fetchCreatorDetails() async {
    final creatorDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.challenge.creatorId)
        .get();
    final creator = CustomUser.User.fromSnap(creatorDoc);
    setState(() {
      creatorName = creator.username;
      creatorPhotoUrl = creator.photoUrl;
    });
  }

  void _showJoinChallengeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Challenge Joined'),
          content: const Text('You have successfully joined the challenge!. you can now chat with other participants just click the chat icon on the top right corner'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _joinChallenge() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final customUser = CustomUser.User.fromSnap(userDoc);
        final userName = customUser.username;
        final photoUrl = customUser.photoUrl;

        final maxParticipants = widget.challenge.maxParticipants;

        final challengeDocRef = FirebaseFirestore.instance
            .collection('challenges')
            .doc(widget.challenge.id);
        final challengeSnapshot = await challengeDocRef.get();
        final participantsList =
        List<String>.from(challengeSnapshot.data()?['participants'] ?? []);

        if (participantsList.length >= maxParticipants) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This challenge is full.')),
          );
          return;
        }

        final participant = Participant(
            id: userId, name: userName, photoUrl: photoUrl, score: 0);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          participantsList.add(userId);
          transaction
              .update(challengeDocRef, {'participants': participantsList});
          transaction.set(
            challengeDocRef.collection('participants').doc(userId),
            participant.toMap(),
          );
        });

        setState(() {
          widget.challenge.participants = participantsList;
          isJoined = true;
        });
        _showJoinChallengeDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join challenge: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cancelJoinChallenge() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;

        final challengeDocRef = FirebaseFirestore.instance
            .collection('challenges')
            .doc(widget.challenge.id);
        final challengeSnapshot = await challengeDocRef.get();
        final participantsList =
        List<String>.from(challengeSnapshot.data()?['participants'] ?? []);

        if (!participantsList.contains(userId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('You are not a participant of this challenge.')),
          );
          return;
        }

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          participantsList.remove(userId);
          transaction
              .update(challengeDocRef, {'participants': participantsList});
          transaction
              .delete(challengeDocRef.collection('participants').doc(userId));
        });

        setState(() {
          widget.challenge.participants = participantsList;
          isJoined = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to leave challenge: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startChallenge() {
    final challengeType = widget.challenge.challengeType;
    if (challengeType == 'Competition') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CompetitionScreen(
                challenge: widget.challenge,
                creatorId: widget.challenge.creatorId)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                NormalGameScreen(challenge: widget.challenge)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canStartChallenge = widget.challenge.participants.length >=
        widget.challenge.maxParticipants / 2;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange[700],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.challenge.category,
              style: TextStyle(color: Colors.white),
            ),
            if (isJoined)
              IconButton(
                icon: Icon(Icons.chat),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        challengeId: widget.challenge.id,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(15.0),
                      ),
                      child: Image.asset(
                        'assets/challenge_u.png',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text.rich(
                    TextSpan(
                      text: widget.challenge.title,
                      style: const TextStyle(fontWeight: FontWeight.normal),
                    ),
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        // Set the desired border radius here
                        child: Container(
                          width: 40, // Set the desired width
                          height: 40, // Set the desired height
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(creatorPhotoUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        creatorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const Spacer(),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 0),
                        ),
                        onPressed: () {
                          // Add follow functionality here i neeeeeeeeeeeddddddd to remind this later
                        },
                        child: const Text('Follow'),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.calendar_today_sharp,
                              color: Colors.deepOrangeAccent, size: 40),
                          const Text('Date',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 30),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(widget
                                .challenge.dateTime
                                .toLocal()),
                            style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                          ),
                          Text(
                            DateFormat('EEE, hh:mm a')
                                .format(widget.challenge.dateTime.toLocal()),

                            style:
                            const TextStyle(fontWeight: FontWeight.w300),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Text(
                        'Description',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),

                  const SizedBox(height: 9),
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.challenge.description,
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.deepOrangeAccent, size: 40),
                          const Text('Location',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 30),
                      Text(
                        widget.challenge.location,
                        style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  const Divider(),

                  Row(
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.groups,
                              color: Colors.deepOrangeAccent, size: 40),
                          const Text('Capacity',
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(width: 30),
                      Text(
                        widget.challenge.maxParticipants.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 18),
                      ),
                    ],
                  ),




                  const SizedBox(height: 69),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isJoined
                          ? const Color(0xFF0288D1)
                          : Colors.deepOrangeAccent,
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isLoading
                        ? null
                        : (isJoined ? _cancelJoinChallenge : _joinChallenge),
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : Text(
                      isJoined ? 'Cancel Join' : 'Join Challenge',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Participants: ${widget.challenge.participants.length}/${widget.challenge.maxParticipants}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('challenges')
                          .doc(widget.challenge.id)
                          .collection('participants')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final participants = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: participants.length,
                          itemBuilder: (context, index) {
                            final participant = participants[index];
                            return ListTile(
                              title: Text(participant['name']),
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(participant['photoUrl']),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isCreator)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent[400],
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: canStartChallenge ? _startChallenge : null,
                child: const Text(
                  'Start Challenge',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          else if (isJoined && widget.challenge.challengeType == 'Competition')
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrangeAccent[400],
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PoolsListScreen(
                        challengeId: widget.challenge.id,
                        creatorId: widget.challenge.creatorId,
                      ),
                    ),
                  );
                },
                child: const Text("View Pools List"),
              ),
            ),
          SizedBox(height: 10),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Time left to start: ${getCountdownText()}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}