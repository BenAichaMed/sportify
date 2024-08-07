import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sportify1/screens/profile_screen.dart';
import 'package:sportify1/utils/colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), color: Colors.black,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Search',style: TextStyle(color: Colors.black),),

      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(7.0),
            child: TextField(
              style: const TextStyle(color: Colors.black),
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search for a user...',
                suffixIcon: const Icon(Icons.search),
                hintStyle: const TextStyle(color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.black),

                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.black),
                ),
              ),
            ),
          ),
          searchController.text.isEmpty ? _buildRecommendedUsers() : _buildSearchResults(),
        ],
      ),
    );
  }

  Widget _buildRecommendedUsers() {
    return Expanded(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').limit(10).snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(doc['photoUrl']),
                  onBackgroundImageError: (exception, stackTrace) {
                    // Log error or handle it as needed
                  },
                  child: Image.network(
                    doc['photoUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                      // Return an error icon or placeholder image
                      return const Icon(Icons.error);
                    },
                  ),
                ),
                title: Text(doc['username'],style: TextStyle(color: Colors.black),),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(uid: doc['uid']),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    return Expanded(
      child: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('username', isGreaterThanOrEqualTo: searchController.text)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(doc['photoUrl']),
                  onBackgroundImageError: (exception, stackTrace) {
                    // Log error or handle it as needed
                  },
                  child: Image.network(
                    doc['photoUrl'],
                    fit: BoxFit.cover,
                    errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                      // Return an error icon or placeholder image
                      return const Icon(Icons.error);
                    },
                  ),
                ),
                title: Text(doc['username'],style: TextStyle(color: Colors.black),),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(uid: doc['uid']),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
