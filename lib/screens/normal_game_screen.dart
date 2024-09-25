import 'package:flutter/material.dart';
import 'package:sportify1/models/challenges.dart';

class NormalGameScreen extends StatefulWidget {
  final Challenge challenge;

  const NormalGameScreen({required this.challenge, super.key});

  @override
  State<NormalGameScreen> createState() => _NormalGameScreenState();
}

class _NormalGameScreenState extends State<NormalGameScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Normal Game: ${widget.challenge.title}'),
      ),
      body: const Center(
        child: Text('Normal Game Screen Content Here'),
      ),
    );
  }
}