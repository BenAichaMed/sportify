import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportify1/responsive/mobile_screen_layout.dart';

import '../responsive/responsive_layout.dart';
import '../responsive/web_screen_layout.dart'; // Add colors file for custom colors

class SelectInterestsScreen extends StatefulWidget {
  @override
  _SelectInterestsScreenState createState() => _SelectInterestsScreenState();
}

class _SelectInterestsScreenState extends State<SelectInterestsScreen> {
  final List<String> sports = [
    'Football', 'Basketball', 'Tennis', 'Cricket', 'Baseball',
    'Hockey', 'Golf', 'Rugby', 'Swimming', 'Cycling'
  ];
  final List<String> selectedSports = [];

  void saveInterests() async {
    if (selectedSports.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can select up to 5 sports only.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'interests': selectedSports});

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const ResponsiveLayout(
          mobileScreenLayout: MobileScreenLayout(),
          webScreenLayout: WebScreenLayout(),
        )),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving interests: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top text phrase
                  const SizedBox(height: 24),
                  const Text(
                    'We want to know what you are interested in!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Chips for sports selection
                  Expanded(
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: sports.map((sport) {
                        final isSelected = selectedSports.contains(sport);
                        return ChoiceChip(
                          label: Text(sport),
                          selected: isSelected,
                          selectedColor: Colors.deepOrangeAccent,
                          backgroundColor: Colors.grey[200],
                          labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                if (selectedSports.length < 5) {
                                  selectedSports.add(sport);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'You can select up to 5 sports only.')),
                                  );
                                }
                              } else {
                                selectedSports.remove(sport);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            // Positioned Save button at the bottom
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveInterests,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
