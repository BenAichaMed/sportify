import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String description;
  final String uid;
  final String username;
  final likes;
  final String postId;
  final DateTime datePublished;
  final List<String> postUrls; // Changed from String to List<String>
  final String profImage;

  const Post({
    required this.description,
    required this.uid,
    required this.username,
    required this.likes,
    required this.postId,
    required this.datePublished,
    required this.postUrls, // Changed from postUrl to postUrls
    required this.profImage,
  });

  static Post fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return Post(
      description: snapshot["description"],
      uid: snapshot["uid"],
      likes: snapshot["likes"],
      postId: snapshot["postId"],
      datePublished: (snapshot["datePublished"] as Timestamp).toDate(),
      username: snapshot["username"],
      postUrls: List<String>.from(snapshot['postUrls']), // Changed from postUrl to postUrls
      profImage: snapshot['profImage'],
    );
  }

  Map<String, dynamic> toJson() => {
    "description": description,
    "uid": uid,
    "likes": likes,
    "username": username,
    "postId": postId,
    "datePublished": datePublished,
    'postUrls': postUrls, // Changed from postUrl to postUrls
    'profImage': profImage,
  };
}
