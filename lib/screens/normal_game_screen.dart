import 'package:flutter/material.dart';
import 'package:sportify1/models/challenges.dart';

class NormalGameScreen extends StatefulWidget {
  final Challenge challenge;

  const NormalGameScreen({required this.challenge, Key? key}) : super(key: key);

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
      body: Center(
        child: Text('Normal Game Screen Content Here'),
      ),
    );
  }
}