import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sportify1/providers/user_provider.dart';
import 'package:sportify1/resources/firestore_methods.dart';
import 'package:sportify1/utils/colors.dart';
import 'package:sportify1/utils/utils.dart';
import 'package:sportify1/widgets/comment_card.dart';
import '../models/user.dart';

class CommentsScreen extends StatefulWidget {
  final String postId;
  const CommentsScreen({super.key, required this.postId});

  @override
  _CommentsScreenState createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController commentEditingController = TextEditingController();

  void postComment(String uid, String name, String profilePic) async {
    if (commentEditingController.text.isEmpty) {
      showSnackBar(context, 'Comment cannot be empty');
      return;
    }

    try {
      String res = await FireStoreMethods().postComment(
        widget.postId,
        commentEditingController.text,
        uid,
        name,
        profilePic,
        likes: 0, // Initialize likes field
      );

      if (res != 'success') {
        showSnackBar(context, res);
      } else {
        setState(() {
          commentEditingController.clear(); // Clear only on success
        });
      }
    } catch (err) {
      showSnackBar(context, err.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = Provider.of<UserProvider>(context).getUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: const Text('Comments'),
        centerTitle: false,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .orderBy('datePublished', descending: true) // Sort by datePublished
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No comments yet.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              return CommentCard(snap: snapshot.data!.docs[index].data());
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: kToolbarHeight,
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(user.photoUrl),
                radius: 18,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: TextField(
                    controller: commentEditingController,
                    decoration: InputDecoration(
                      hintText: 'Comment as ${user.username}',
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () => postComment(user.uid, user.username, user.photoUrl),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: const Text('Post', style: TextStyle(color: Colors.blue)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
