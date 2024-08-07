import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportify1/resources/auth_methods.dart';
import 'package:sportify1/resources/firestore_methods.dart';
import 'package:sportify1/resources/storage_methods.dart';
import 'package:sportify1/screens/login_screen.dart';
import 'package:sportify1/utils/colors.dart';
import 'package:sportify1/utils/utils.dart';
import 'package:sportify1/widgets/follow_button.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  var userData = {};
  int postLen = 0;
  int followers = 0;
  int following = 0;
  bool isFollowing = false;
  bool isLoading = false;

  final TextEditingController usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getData();
  }

  @override
  void dispose() {
    usernameController.dispose();
    super.dispose();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      var userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (userSnap.exists) {
        userData = userSnap.data()!;
        followers = userData['followers']?.length ?? 0;
        following = userData['following']?.length ?? 0;
        isFollowing = userData['followers']
            ?.contains(FirebaseAuth.instance.currentUser!.uid) ??
            false;

        var postSnap = await FirebaseFirestore.instance
            .collection('posts')
            .where('uid', isEqualTo: widget.uid)
            .get();

        postLen = postSnap.docs.length;
      } else {
        // Handle case when user data is not found
        showSnackBar(context, "User not found");
      }
    } catch (e) {
      showSnackBar(context, e.toString());
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _updateUsername() async {
    String newUsername = usernameController.text.trim();
    if (newUsername.isEmpty) {
      showSnackBar(context, 'Username cannot be empty');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'username': newUsername});

      setState(() {
        userData['username'] = newUsername;
      });

      showSnackBar(context, 'Username updated successfully');
      Navigator.of(context).pop();
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> _updateProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    // Convert the File to a Uint8List
    Uint8List imageBytes = await image.readAsBytes();

    try {
      // Upload image to Firebase storage
      String photoUrl = await StorageMethods().uploadImageToStorage('profilePics', imageBytes, false);

      // Update user profile with new photo URL
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'photoUrl': photoUrl});

      setState(() {
        userData['photoUrl'] = photoUrl;
      });

      showSnackBar(context, 'Profile picture updated successfully');
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  void _showEditUsernameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Username'),
          content: TextField(
            controller: usernameController,
            decoration: const InputDecoration(
              hintText: 'Enter new username',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _updateUsername,
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
      child: CircularProgressIndicator(),
    )
        : Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        title: Text(
          userData['username'] ?? '',
        ),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey,
                      backgroundImage: userData['photoUrl'] != null
                          ? NetworkImage(userData['photoUrl'])
                          : null,
                      radius: 40,
                      child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: _updateProfilePicture,
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: [
                              buildStatColumn(postLen, "posts"),
                              buildStatColumn(followers, "followers"),
                              buildStatColumn(following, "following"),
                            ],
                          ),
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly,
                            children: [
                              FirebaseAuth.instance.currentUser!.uid ==
                                  widget.uid
                                  ? Column(
                                children: [
                                  SizedBox(
                                    width:
                                    200, // Set your desired width here
                                    child: FollowButton(
                                      text: 'Sign Out',
                                      backgroundColor:
                                      mobileBackgroundColor,
                                      textColor: primaryColor,
                                      borderColor: Colors.grey,
                                      function: () async {
                                        await AuthMethods().signOut();

                                        if (context.mounted) {
                                          Navigator.of(context)
                                              .pushReplacement(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                              const LoginScreen(),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: 200,
                                    child: ElevatedButton(
                                      onPressed: _showEditUsernameDialog,
                                      child: const Text('Change Username'),
                                    ),
                                  ),
                                ],
                              )
                                  : isFollowing
                                  ? SizedBox(
                                width:
                                200, // Set your desired width here
                                child: FollowButton(
                                  text: 'Unfollow',
                                  backgroundColor: Colors.white,
                                  textColor: Colors.black,
                                  borderColor: Colors.grey,
                                  function: () async {
                                    await FireStoreMethods()
                                        .followUser(
                                      FirebaseAuth.instance
                                          .currentUser!.uid,
                                      userData['uid'],
                                    );

                                    setState(() {
                                      isFollowing = false;
                                      followers--;
                                    });
                                  },
                                ),
                              )
                                  : SizedBox(
                                width:
                                200, // Set your desired width here
                                child: FollowButton(
                                  text: 'Follow',
                                  backgroundColor: Colors.blue,
                                  textColor: Colors.white,
                                  borderColor: Colors.blue,
                                  function: () async {
                                    await FireStoreMethods()
                                        .followUser(
                                      FirebaseAuth.instance
                                          .currentUser!.uid,
                                      userData['uid'],
                                    );

                                    setState(() {
                                      isFollowing = true;
                                      followers++;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(
                    top: 15,
                  ),
                  child: Text(
                    userData['username'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(
                    top: 1,
                  ),
                  child: Text(
                    userData['bio'] ?? '',
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          FutureBuilder(
            future: FirebaseFirestore.instance
                .collection('posts')
                .where('uid', isEqualTo: widget.uid)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No posts yet'),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 1.5,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  DocumentSnapshot snap = snapshot.data!.docs[index];

                  return Container(
                    child: Image(
                      image: NetworkImage(snap['postUrl']),
                      fit: BoxFit.cover,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Column buildStatColumn(int num, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          num.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
