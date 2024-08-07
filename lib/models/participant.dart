class Participant {
  final String id;
  final String name;
  final String photoUrl;
  final int score;

  Participant({required this.id, required this.name, required this.photoUrl, required this.score});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'score': 0, // Assuming rank is part of participant data
    };
  }

  static Participant fromMap(Map<String, dynamic> map) {
    return Participant(
      id: map['id'],
      name: map['name'],
      photoUrl: map['photoUrl'],
      score: map['score'],
    );
  }
}