import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantsCard extends StatelessWidget {
  final List<Map<String, dynamic>> participants;

  const ParticipantsCard({Key? key, required this.participants}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange[50], // Light background color
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 300, // Adjust height as needed
        child: ListView.builder(
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final participant = participants[index];
            return ListTile(
              title: Text(
                participant['name'] ?? 'Unknown',
                style: TextStyle(color: Colors.deepOrange), // Text color
              ),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(participant['photoUrl'] ?? 'https://i.stack.imgur.com/l60Hf.png'),
              ),
            );
          },
        ),
      ),
    );
  }
}