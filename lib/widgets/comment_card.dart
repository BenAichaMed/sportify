import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommentCard extends StatefulWidget {
  final Map<String, dynamic> snap;
  const CommentCard({super.key, required this.snap});

  @override
  _CommentCardState createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool showReplyField = false;
  final TextEditingController replyController = TextEditingController();
  int likeCount = 0;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    likeCount = widget.snap['likes'] ?? 0;
    isLiked = widget.snap['isLiked'] ?? false;
  }

  String getTimeDifference(DateTime datePublished) {
    final now = DateTime.now();
    final difference = now.difference(datePublished);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Just now';
    }
  }

  void toggleLike() async {
    String postId = widget.snap['postId'];
    String commentId = widget.snap['commentId'];


    DocumentReference commentRef = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);

    try {
      DocumentSnapshot commentSnapshot = await commentRef.get();

      if (commentSnapshot.exists) {
        setState(() {
          isLiked = !isLiked;
          likeCount += isLiked ? 1 : -1;
        });

        await commentRef.update({
          'likes': likeCount,
          'isLiked': isLiked,
        });
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error fetching document: $e');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(
                  widget.snap['profilePic'],
                ),
                radius: 18,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: widget.snap['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: ' ${getTimeDifference(widget.snap['datePublished'].toDate())}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '${widget.snap['text']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                onPressed: toggleLike,
                color: isLiked ? Colors.red : Colors.black,
              ),
              Text('$likeCount'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 56), // Align with the avatar
              TextButton(
                onPressed: () {
                  setState(() {
                    showReplyField = !showReplyField;
                  });
                },
                child: const Text(' maybe Reply ', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
          // if (showReplyField)
          //   Padding(
          //     padding: const EdgeInsets.only(left: 56),
          //     child: Column(
          //       children: [
          //         TextField(
          //           controller: replyController,
          //           decoration: const InputDecoration(
          //             hintText: 'Write a reply...',
          //             border: OutlineInputBorder(),
          //           ),
          //         ),
          //         TextButton(
          //           onPressed: () {
          //             // Add reply posting functionality here
          //           },
          //           child: const Text('Post', style: TextStyle(color: Colors.blue)),
          //         ),
          //       ],
          //     ),
          //   ),
          // Add replies here
        ],
      ),
    );
  }
}