import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportify1/screens/editProfileScreen.dart';
import 'package:sportify1/screens/login_screen.dart'; // Import the login screen
import 'package:sportify1/utils/utils.dart';

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
  int challengesJoined = 0; // Add this line
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

        // Fetch challenges joined count
        var challengesSnap = await FirebaseFirestore.instance
            .collection('challenges')
            .where('participants', arrayContains: widget.uid)
            .get();

        challengesJoined = challengesSnap.docs.length;
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

  void logoutUser(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl, int likes) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 500,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Image.network(imageUrl),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            '$likes',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
        backgroundColor: Colors.deepOrangeAccent,
        title: Text('Profile'),
        centerTitle: true,
        actions: [
          if (FirebaseAuth.instance.currentUser!.uid == widget.uid)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => logoutUser(context),
            ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Picture, Username, and Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey,
                        backgroundImage: userData['photoUrl'] != null
                            ? NetworkImage(userData['photoUrl'])
                            : null,
                        radius: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userData['username'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildStatColumn(challengesJoined, "Challenges"),
                          const VerticalDivider(),
                          buildStatColumn(followers, "Followers"),
                          const VerticalDivider(),
                          buildStatColumn(following, "Following"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FirebaseAuth.instance.currentUser!.uid == widget.uid
                          ? ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfileScreen(uid: widget.uid),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text('Edit Profile'),
                      )
                          : ElevatedButton(
                        onPressed: () {
                          // Implement follow/unfollow functionality here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: isFollowing
                            ? const Text('Unfollow')
                            : const Text('Follow'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // About Yourself Section
                Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ${userData['username']}' ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        userData['bio'] ??
                            'this is a place holder i need to change this once i complete the importtn thing this profile screen line 266',
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${userData['username']} \'s images ' ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('posts')
                            .where('uid', isEqualTo: widget.uid)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text('No posts yet'),
                            );
                          }

                          List<DocumentSnapshot> posts =
                              snapshot.data!.docs;

                          return GridView.builder(
                            shrinkWrap: true,
                            itemCount: posts.length,
                            gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 1.5,
                              childAspectRatio: 1,
                            ),
                            itemBuilder: (context, index) {
                              DocumentSnapshot snap = posts[index];
                              List<dynamic> postUrls = snap['postUrls'];
                              List<dynamic> likes = snap['likes'];

                              if (postUrls.isEmpty) {
                                return Container(
                                  color: Colors.grey,
                                  child: const Center(
                                    child: Text('No Image'),
                                  ),
                                );
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics:
                                const NeverScrollableScrollPhysics(),
                                itemCount: postUrls.length,
                                gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 1,
                                  crossAxisSpacing: 5,
                                  mainAxisSpacing: 1.5,
                                  childAspectRatio: 1,
                                ),
                                itemBuilder: (context, subIndex) {
                                  return Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: GestureDetector(
                                      onTap: () => _showFullScreenImage(
                                          postUrls[subIndex],
                                          likes.length),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          child: Image(
                                            image: NetworkImage(
                                                postUrls[subIndex]),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Interests',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: userData['interests'] != null
                            ? List<Widget>.from(
                          userData['interests'].map((interest) {
                            return Chip(
                              label: Text(
                                interest,
                                style: const TextStyle(
                                  color: Colors.black, // Color of the text
                                  fontWeight: FontWeight.bold, // Bold text style
                                ),
                              ),
                              backgroundColor: Colors.white, // Background color for chips
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ), // Custom padding
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18), // Rounded corners
                              ),
                            );
                          }),
                        )
                            : [],
                      )

                    ],
                  ),
                )
              ],
            ),
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