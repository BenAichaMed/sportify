import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:sportify1/models/challenges.dart';
import 'package:sportify1/screens/chat.dart';
import 'package:sportify1/models/user.dart' as CustomUser;
import 'package:sportify1/screens/pools_screen.dart';
import 'package:sportify1/screens/normal_game_screen.dart';
import 'package:sportify1/models/participant.dart';

class TennisChallengeDetailScreen extends StatefulWidget {
  final TennisChallenge challenge;

  const TennisChallengeDetailScreen({required this.challenge});

  @override
  _TennisChallengeDetailScreen createState() => _TennisChallengeDetailScreen();
}

class _TennisChallengeDetailScreen extends State<TennisChallengeDetailScreen> {
  bool isJoined = false;
  bool isLoading = false;
  bool isCreator = false;
  String username = '';
  Duration timeLeft = Duration();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _checkIfJoined();
    _fetchUsername();
    _fetchParticipantCount();
    _startCountdown();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    final eventDateTime = widget.challenge.dateTime;
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
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
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final customUser = CustomUser.User.fromSnap(userDoc);
      setState(() {
        username = customUser.username;
        isCreator = user.uid == widget.challenge.creatorId;
      });
    }
  }

  Future<void> _fetchParticipantCount() async {
    final challengeDocRef = FirebaseFirestore.instance.collection('challenges').doc(widget.challenge.id);
    final challengeSnapshot = await challengeDocRef.get();
    final participantsCount = challengeSnapshot.data()?['participants'] ?? 0;
    setState(() {
      widget.challenge.participants = participantsCount;
    });
  }

  Future<void> _joinChallenge() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userId = user.uid;
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        final customUser = CustomUser.User.fromSnap(userDoc);
        final userName = customUser.username;
        final photoUrl = customUser.photoUrl;

        final maxParticipants = widget.challenge.maxParticipants;

        final challengeDocRef = FirebaseFirestore.instance.collection('challenges').doc(widget.challenge.id);
        final challengeSnapshot = await challengeDocRef.get();
        final participantsCount = challengeSnapshot.data()?['participants'] ?? 0;

        if (participantsCount >= maxParticipants) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('This challenge is full.')),
          );
          return;
        }
        final participant = Participant(id: userId, name: userName, photoUrl: photoUrl, score: 0);

        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.update(challengeDocRef, {'participants': FieldValue.increment(1)});
          transaction.set(challengeDocRef.collection('participants').doc(userId), participant.toMap());
        });

        setState(() {
          widget.challenge.participants += 1;
          isJoined = true;
        });
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

        final challengeDocRef = FirebaseFirestore.instance.collection('challenges').doc(widget.challenge.id);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          transaction.update(challengeDocRef, {'participants': FieldValue.increment(-1)});
          transaction.delete(challengeDocRef.collection('participants').doc(userId));
        });

        setState(() {
          widget.challenge.participants -= 1;
          isJoined = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel join: $e')),
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
            builder: (context) =>
                CompetitionScreen(challenge: widget.challenge, creatorId: widget.challenge.creatorId,)),
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
    final canStartChallenge =
        widget.challenge.participants >= widget.challenge.maxParticipants / 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.challenge.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.challenge.title,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Category: ${widget.challenge.category}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(width: 36),
                  Text(
                    'Type: ${widget.challenge.challengeType ?? 'Unknown'}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                'Created by: ${widget.challenge.creatorName ?? 'Unknown'}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(
                      'Location: ${widget.challenge.location ?? 'Unknown'}'),
                  subtitle: Text(
                      'Max Participants: ${widget.challenge.maxParticipants}'),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : (isJoined ? _cancelJoinChallenge : _joinChallenge),
                child: isLoading
                    ? CircularProgressIndicator()
                    : Text(isJoined ? 'Cancel Join' : 'Join Challenge'),
              ),
              SizedBox(height: 16),
              if (isJoined)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ChatScreen(challengeId: widget.challenge.id)),
                    );
                  },
                  child: Text('Go to Chat'),
                ),
              SizedBox(height: 16),
              if (isCreator)
                ElevatedButton(
                  onPressed: canStartChallenge ? _startChallenge : null,
                  child: Text('Start Challenge'),
                ),
              SizedBox(height: 16),
              Text(
                'Participants: ${widget.challenge.participants}/${widget.challenge.maxParticipants}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('challenges')
                      .doc(widget.challenge.id)
                      .collection('participants')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();
                    final participants = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: participants.length,
                      itemBuilder: (context, index) {
                        final participant = participants[index];
                        return ListTile(
                          title: Text(participant['name'] ?? 'Unknown'),
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(
                                participant['photoUrl'] ??
                                    'https://i.stack.imgur.com/l60Hf.png'),
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
      bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Time left to start: ${getCountdownText()}'),
          ],
        ),
      ),
    );
  }
}