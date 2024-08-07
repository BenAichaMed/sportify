import 'package:flutter/material.dart';
import 'package:sportify1/models/challenges.dart';

class RunningChallengeDetailScreen extends StatelessWidget {
  final Challenge challenge;

  const RunningChallengeDetailScreen({Key? key, required this.challenge}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Running Challenge Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              challenge.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Description: ${challenge.description}'),
            SizedBox(height: 16),
            //Text('Location: ${challenge.location}'),
            SizedBox(height: 16),
            Text('Date & Time: ${challenge.dateTime}'),
            SizedBox(height: 16),
            //Text('Challenge Type: ${challenge.challengeType}'),
            SizedBox(height: 16),
            Text('Creator: ${challenge.creatorName}'),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
