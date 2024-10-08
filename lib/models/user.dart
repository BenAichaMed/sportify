import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String email;
  final String uid;
  final String photoUrl;
  final String username;
  final String bio;
  final List followers;
  final List following;
  final List<String> interests;

  const User({
    required this.username,
    required this.uid,
    required this.photoUrl,
    required this.email,
    required this.bio,
    required this.followers,
    required this.following,
    required this.interests,
  });

  static User fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>?;

    if (snapshot == null) {
      throw Exception("Snapshot data is null");
    }

    return User(
      username: snapshot["username"] ?? '',
      uid: snapshot["uid"] ?? '',
      email: snapshot["email"] ?? '',
      photoUrl: snapshot["photoUrl"] ?? '',
      bio: snapshot["bio"] ?? '',
      followers: snapshot["followers"] ?? [],
      following: snapshot["following"] ?? [],
      interests: List<String>.from(snapshot["interests"] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    "username": username,
    "uid": uid,
    "email": email,
    "photoUrl": photoUrl,
    "bio": bio,
    "followers": followers,
    "following": following,
    "interests": interests,
  };
}
