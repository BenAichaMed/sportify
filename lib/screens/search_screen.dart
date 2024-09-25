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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Search', style: TextStyle(color: Colors.black)),
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
                suffixIcon: const Icon(Icons.search, color: Colors.black),
                hintStyle: const TextStyle(color: Colors.black54),
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
          Expanded(
            child: searchController.text.isEmpty
                ? _buildRecommendedUsers()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedUsers() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('users').limit(10).snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No users found.'));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return _buildUserTile(doc);
          }).toList(),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: searchController.text)
          .where('username', isLessThan: searchController.text + '\uf8ff')
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No results found.'));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            return _buildUserTile(doc);
          }).toList(),
        );
      },
    );
  }

  Widget _buildUserTile(QueryDocumentSnapshot doc) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(doc['photoUrl']),
        radius: 24, // Adjust the radius as needed
        onBackgroundImageError: (exception, stackTrace) {
          // Handle error as needed
        },
        // If needed, you can add a background color
        backgroundColor: Colors.grey[300],
      ),
      title: Text(doc['username'], style: const TextStyle(color: Colors.black)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileScreen(uid: doc['uid']),
        ),
      ),
    );
  }
}
