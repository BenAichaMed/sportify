import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sportify1/screens/add_post_screen.dart';
import 'package:sportify1/screens/search_screen.dart';
import 'package:sportify1/utils/colors.dart';
import 'package:sportify1/utils/global_variable.dart';
import 'package:sportify1/widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: width > webScreenSize ? webBackgroundColor : mobileBackgroundColor,
      appBar: width > webScreenSize
          ? null
          : AppBar(
        backgroundColor: mobileBackgroundColor,
        centerTitle: false,
        title: Text(
          'Sportify',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),



        actions: [
          IconButton(
            icon: const Icon(
              Icons.search,
              color: Colors.black,
            ),
            onPressed: (){
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => SearchScreen()));
                },
          ),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.black,
            ),
            onPressed: () {},
          ),

        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('posts').orderBy('datePublished',descending: true).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
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

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (ctx, index) {
              var doc = snapshot.data!.docs[index];
              if (!doc.exists || doc.data() == null) {
                return Container();
              }

              var postData = doc.data()!;
              if (postData.isEmpty) {
                return Container();
              }

              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: width > webScreenSize ? width * 0.3 : 0,
                  vertical: width > webScreenSize ? 15 : 0,
                ),
                child: PostCard(
                  snap: postData,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {

           Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddPostScreen()));
        },
        child: const Icon(Icons.add),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        backgroundColor: Colors.deepOrangeAccent,
      ),
    );
  }
}

