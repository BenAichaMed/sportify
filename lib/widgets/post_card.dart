import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sportify1/models/user.dart' as model;
import 'package:sportify1/screens/profile_screen.dart';
import 'package:sportify1/utils/global_variable.dart';
import 'package:sportify1/widgets/like_animation.dart';
import '../providers/user_provider.dart';
import '../resources/firestore_methods.dart';
import '../screens/comments_screen.dart';
import '../utils/colors.dart';
import '../utils/utils.dart';

class PostCard extends StatefulWidget {
  final Map<String, dynamic> snap;

  const PostCard({
    super.key,
    required this.snap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int commentLen = 0;
  bool isLikeAnimating = false;
  bool isUserValid = true;
  Map<String, dynamic>? updatedUserData;

  @override
  void initState() {
    super.initState();
    fetchCommentLen();
    checkUserExistence();
    fetchUserData();
  }

  fetchCommentLen() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.snap['postId'])
          .collection('comments')
          .get();
      commentLen = snap.docs.length;
    } catch (err) {
      showSnackBar(
        context,
        err.toString(),
      );
    }
    setState(() {});
  }

  checkUserExistence() async {
    try {
      DocumentSnapshot userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.snap['uid'])
          .get();
      if (!userSnap.exists) {
        setState(() {
          isUserValid = false;
        });
      }
    } catch (err) {
      showSnackBar(
        context,
        err.toString(),
      );
      setState(() {
        isUserValid = false;
      });
    }
  }

  fetchUserData() async {
    try {
      DocumentSnapshot userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.snap['uid'])
          .get();
      updatedUserData = userSnap.data() as Map<String, dynamic>?;
      setState(() {});
    } catch (err) {
      showSnackBar(
        context,
        err.toString(),
      );
    }
  }

  deletePost(String postId) async {
    try {
      await FireStoreMethods().deletePost(postId);
    } catch (err) {
      showSnackBar(
        context,
        err.toString(),
      );
    }
  }

  bool isValidData() {
    return widget.snap.containsKey('profImage') &&
        widget.snap.containsKey('username') &&
        widget.snap.containsKey('uid') &&
        widget.snap.containsKey('postUrls') &&
        widget.snap.containsKey('postId') &&
        widget.snap.containsKey('likes') &&
        widget.snap.containsKey('description') &&
        widget.snap.containsKey('datePublished');
  }

  @override
  Widget build(BuildContext context) {
    final model.User? user = Provider.of<UserProvider>(context).getUser;
    final width = MediaQuery.of(context).size.width;

    if (!isValidData() || !isUserValid) {
      // Skip rendering if the data is invalid or user doesn't exist
      return Container();
    }

    if (updatedUserData == null) {
      // Show a loading indicator while fetching user data
      return const Center(child: CircularProgressIndicator());
    }

    List<dynamic> postUrls = widget.snap['postUrls'];

    return Container(
      // boundary needed for web
      decoration: BoxDecoration(
        border: Border.all(
          color: width > webScreenSize ? secondaryColor : mobileBackgroundColor,
        ),
        color: mobileBackgroundColor,
      ),
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 16,
            ).copyWith(right: 0),
            child: Row(
              children: <Widget>[
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          uid: widget.snap['uid'],
                        ),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      updatedUserData?['photoUrl'].toString() ?? '',
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 5,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          updatedUserData?['username'].toString() ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          DateFormat('d MMM y \'at\' h:mm a')
                              .format(widget.snap['datePublished'].toDate()),
                          style: const TextStyle(
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                widget.snap['uid']?.toString() == user?.uid
                    ? IconButton(
                  color: Colors.black,
                  onPressed: () {
                    showDialog(
                      useRootNavigator: false,
                      context: context,
                      builder: (context) {
                        return Dialog(
                          child: ListView(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shrinkWrap: true,
                              children: [
                                'Delete',
                              ]
                                  .map(
                                    (e) => InkWell(
                                    child: Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16),
                                      child: Text(e),
                                    ),
                                    onTap: () {
                                      deletePost(
                                        widget.snap['postId']
                                            .toString(),
                                      );
                                      // remove the dialog box
                                      Navigator.of(context).pop();
                                    }),
                              )
                                  .toList()),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.more_vert),
                )
                    : Container(),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 8,
              left: 16,
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: ' ${widget.snap['description']}',
                    style: const TextStyle(fontSize: 21),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 26,
          ),
          // IMAGE SECTION OF THE POST
          GestureDetector(
            onDoubleTap: () {
              FireStoreMethods().likePost(
                widget.snap['postId'].toString(),
                user?.uid ?? '',
                widget.snap['likes'],
              );
              setState(() {
                isLikeAnimating = true;
              });
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.30,
                    width: MediaQuery.of(context).size.height * 0.5,
                    child: PageView.builder(
                      itemCount: postUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          postUrls[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text('Image not available'),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isLikeAnimating ? 1 : 0,
                  child: LikeAnimation(
                    isAnimating: isLikeAnimating,
                    duration: const Duration(
                      milliseconds: 400,
                    ),
                    onEnd: () {
                      setState(() {
                        isLikeAnimating = false;
                      });
                    },
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // LIKE, COMMENT SECTION OF THE POST
          Row(
            children: <Widget>[
              LikeAnimation(
                isAnimating: widget.snap['likes'].contains(user?.uid),
                smallLike: true,
                child: IconButton(
                  icon: widget.snap['likes'].contains(user?.uid)
                      ? const Icon(
                    Icons.favorite,
                    color: Colors.red,
                  )
                      : const Icon(
                    Icons.favorite_border,
                    color: Colors.black,
                  ),
                  onPressed: () => FireStoreMethods().likePost(
                    widget.snap['postId'].toString(),
                    user?.uid ?? '',
                    widget.snap['likes'],
                  ),
                ),
              ),
              Text('${widget.snap['likes'].length} likes', style: const TextStyle(color: Colors.black),),
              IconButton(
                icon: const Icon(
                  Icons.comment_outlined,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CommentsScreen(
                      postId: widget.snap['postId'].toString(),
                    ),
                  ),
                ),
              ),
              Text('$commentLen comments', style: const TextStyle(color: Colors.black),),
            ],
          ),
        ],
      ),
    );
  }
}