import 'package:flutter/material.dart';

class RecommendedUserTile extends StatelessWidget {
  final String username;
  final String photoUrl;
  final VoidCallback onFollow;

  const RecommendedUserTile({
    super.key,
    required this.username,
    required this.photoUrl,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(photoUrl),
      ),
      title: Text(username),
      trailing: ElevatedButton(
        onPressed: onFollow,
        child: const Text('Follow'),
      ),
    );
  }
}