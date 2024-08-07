import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportify1/models/challenges.dart';
import 'package:intl/intl.dart';
import 'package:sportify1/models/user.dart' as CustomUser;

class CreateChallengeScreen extends StatefulWidget {
  const CreateChallengeScreen({Key? key}) : super(key: key);

  @override
  _CreateChallengeScreenState createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends State<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startPointController = TextEditingController();
  final TextEditingController _endPointController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _maxParticipantsController = TextEditingController();
  DateTime _selectedDateTime = DateTime.now();
  String _selectedCategory = 'Running'; // Default category
  List<String> _categories = ['Running', 'Tennis', 'Basketball', 'Cycling'];
  final user = FirebaseAuth.instance.currentUser;
  String _selectedChallengeType = 'Normal Game'; // Default challenge type
  List<String> _challengeTypes = ['Normal Game', 'Competition'];

  Future<String> _getUsername() async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    final customUser = CustomUser.User.fromSnap(userDoc);
    return customUser.username;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final creatorName = await _getUsername();

      Challenge newChallenge;
      if (_selectedCategory == 'Running' || _selectedCategory == 'Cycling') {
        newChallenge = RunningCyclingChallenge(
          id: FirebaseFirestore.instance.collection('challenges').doc().id,
          title: _titleController.text,
          description: _descriptionController.text,
          dateTime: _selectedDateTime,
          location: _locationController.text,
          startPoint: _startPointController.text,
          endPoint: _endPointController.text,
          distance: double.tryParse(_distanceController.text) ?? 0.0,
          maxParticipants: int.tryParse(_maxParticipantsController.text) ?? 20,
          creatorName: creatorName,
          creatorId: user!.uid,
        );
      } else if (_selectedCategory == 'Tennis') {
        newChallenge = TennisChallenge(
          id: FirebaseFirestore.instance.collection('challenges').doc().id,
          title: _titleController.text,
          description: _descriptionController.text,
          dateTime: _selectedDateTime,
          location: _locationController.text,
          maxParticipants: int.tryParse(_maxParticipantsController.text) ?? 4,
          creatorName: creatorName,
          creatorId: user!.uid,
          challengeType: _selectedChallengeType,
        );
      } else {
        throw Exception('Unknown challenge category: $_selectedCategory');
      }
      FirebaseFirestore.instance
          .collection('challenges')
          .doc(newChallenge.id)
          .set(newChallenge.toMap())
          .then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Challenge created successfully!')),
        );
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create challenge: $error')),
        );
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDateTime) {
      setState(() {
        _selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDateTime.hour,
          _selectedDateTime.minute,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Challenge'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Create a New Challenge',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              if (_selectedCategory == 'Tennis' || _selectedCategory == 'Running' || _selectedCategory == 'Cycling') ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a location';
                    }
                    return null;
                  },
                ),
              ],
              if (_selectedCategory == 'Tennis') ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _maxParticipantsController,
                  decoration: const InputDecoration(
                    labelText: 'Max Participants',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter max participants';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField(
                  value: _selectedChallengeType,
                  decoration: const InputDecoration(
                    labelText: 'Challenge Type',
                    border: OutlineInputBorder(),
                  ),
                  items: _challengeTypes.map((String type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedChallengeType = newValue!;
                    });
                  },
                ),
              ],
              if (_selectedCategory == 'Running' || _selectedCategory == 'Cycling') ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _startPointController,
                  decoration: const InputDecoration(
                    labelText: 'Start Point',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a start point';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _endPointController,
                  decoration: const InputDecoration(
                    labelText: 'End Point',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an end point';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _distanceController,
                  decoration: const InputDecoration(
                    labelText: 'Distance',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a distance';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 16),
              ListTile(
                title: Text('Date: ${DateFormat('yMMMd').format(_selectedDateTime)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              ListTile(
                title: Text('Time: ${DateFormat('jm').format(_selectedDateTime)}'),
                trailing: Icon(Icons.access_time),
                onTap: _selectTime,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Create Challenge'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}