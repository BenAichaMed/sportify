import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sportify1/models/chat.dart';
import 'package:sportify1/models/user.dart' as CustomUser;

class ChatScreen extends StatefulWidget {
  final String challengeId;

  const ChatScreen({super.key, required this.challengeId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<String> _getUsername() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final user = CustomUser.User.fromSnap(userDoc);
    return user.username;
  }

  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    final username = await _getUsername();

    final message = ChatMessage(
      id: FirebaseFirestore.instance.collection('challenges/${widget.challengeId}/messages').doc().id,
      senderId: currentUser!.uid,
      senderName: username,
      message: _messageController.text,
      timestamp: DateTime.now(),
    );

    FirebaseFirestore.instance
        .collection('challenges/${widget.challengeId}/messages')
        .doc(message.id)
        .set(message.toMap());

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion Room'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('challenges/${widget.challengeId}/messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data!.docs.map((doc) => ChatMessage.fromMap(doc.data() as Map<String, dynamic>)).toList();

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Text(message.senderName),
                      subtitle: Text(message.message),
                      trailing: Text(DateFormat('jm').format(message.timestamp)),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}