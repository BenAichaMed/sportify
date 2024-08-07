import 'package:cloud_firestore/cloud_firestore.dart';

abstract class Challenge {
  String id;
  String title;
  String description;
  String category;
  DateTime dateTime;
  int participants;
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
    required String id,
    required String title,
    required String description,
    required DateTime dateTime,
    required this.location,
    required this.challengeType,
    required this.maxParticipants,
    required String creatorName,
    required String creatorId,
  }) : super(
    id: id,
    title: title,
    description: description,
    category: 'Tennis',
    dateTime: dateTime,
    participants: 0,
    creatorName: creatorName,
    creatorId: creatorId,
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
  String startPoint;
  String endPoint;
  double distance;
  int maxParticipants;

  RunningCyclingChallenge({
    required String id,
    required String title,
    required String description,
    required DateTime dateTime,
    required this.location,
    required this.startPoint,
    required this.endPoint,
    required this.distance,
    required this.maxParticipants,
    required String creatorName,
    required String creatorId,
  }) : super(
    id: id,
    title: title,
    description: description,
    category: 'Running',
    dateTime: dateTime,
    participants: 0,
    creatorName: creatorName,
    creatorId: creatorId,
  );

  factory RunningCyclingChallenge.fromMap(Map<String, dynamic> data) {
    return RunningCyclingChallenge(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      location: data['location'],
      startPoint: data['startPoint'],
      endPoint: data['endPoint'],
      distance: data['distance'],
      maxParticipants: data['maxParticipants'] ?? 20,
      creatorName: data['creatorName'] ?? 'Anonymous',
      creatorId: data['creatorId'] ?? 'Anonymous',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    var map = super.toMap();
    map.addAll({
      'location': location,
      'startPoint': startPoint,
      'endPoint': endPoint,
      'distance': distance,
      'maxParticipants': maxParticipants,
    });
    return map;
  }
}