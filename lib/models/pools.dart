class Pool {
  String id;
  String name;
  List<String> participants;

  Pool({required this.id, required this.name, required this.participants});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'participants': participants,
    };
  }

  static Pool fromMap(Map<String, dynamic> map) {
    return Pool(
      id: map['id'],
      name: map['name'],
      participants: List<String>.from(map['participants']),
    );
  }
}
