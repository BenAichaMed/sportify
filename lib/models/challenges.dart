import 'package:cloud_firestore/cloud_firestore.dart';

abstract class Challenge {
  String id;
  String title;
  String description;
  String category;
  DateTime dateTime;
  List<String> participants;
  String creatorName;
  String creatorId;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.participants,
    required this.creatorName,
    required this.creatorId,
  });

  factory Challenge.fromMap(Map<String, dynamic> data) {
    switch (data['category']) {
      case 'Running':
      case 'Cycling':
        return RunningCyclingChallenge.fromMap(data);
      case 'Tennis':
        return TennisChallenge.fromMap(data);
      default:
        throw Exception('Unknown challenge type');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'dateTime': dateTime,
      'participants': participants,
      'creatorName': creatorName,
      'creatorId': creatorId,
    };
  }
}
class TennisChallenge extends Challenge {
  String location;
  int maxParticipants;
  String challengeType;

  TennisChallenge({
    required super.id,
    required super.title,
    required super.description,
    required super.dateTime,
    required this.location,
    required this.challengeType,
    required this.maxParticipants,
    required super.creatorName,
    required super.creatorId,
    required super.participants,
  }) : super(
    category: 'Tennis',
  );

  factory TennisChallenge.fromMap(Map<String, dynamic> data) {
    return TennisChallenge(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      location: data['location'],
      challengeType: data['challengeType'],
      maxParticipants: data['maxParticipants'] ?? 4,
      creatorName: data['creatorName'] ?? 'Anonymous',
      creatorId: data['creatorId'] ?? 'Anonymous',
      participants: List<String>.from(data['participants'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = super.toMap();
    map.addAll({
      'location': location,
      'maxParticipants': maxParticipants,
      'challengeType': challengeType,
    });
    return map;
  }
}
class RunningCyclingChallenge extends Challenge {
  String location;
  String meetup;
  double distance;
  int maxParticipants;

  RunningCyclingChallenge({
    required super.id,
    required super.title,
    required super.description,
    required super.dateTime,
    required this.location,
    required this.meetup,
    required this.distance,
    required this.maxParticipants,
    required super.creatorName,
    required super.creatorId,
    required super.participants,
    required super.category,
  });

  factory RunningCyclingChallenge.fromMap(Map<String, dynamic> data) {
    return RunningCyclingChallenge(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      location: data['location'],
      meetup: data['meetup'],
      distance: data['distance'],
      maxParticipants: data['maxParticipants'] ?? 20,
      creatorName: data['creatorName'] ?? 'Anonymous',
      creatorId: data['creatorId'] ?? 'Anonymous',
      participants: List<String>.from(data['participants'] ?? []),
      category: data['category'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = super.toMap();
    map.addAll({
      'location': location,
      'meetup': meetup,
      'distance': distance,
      'maxParticipants': maxParticipants,
    });
    return map;
  }
}