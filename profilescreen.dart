import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  String? _profilePictureUrl;
  String? _name;
  String? _email;
  int? _contactNumber;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      setState(() {
        _profilePictureUrl = userData['profilePictureUrl'] as String?;
        _name = userData['name'] as String?;
        _email = userData['email'] as String?;
        // Convert 'contactNumber' to int if it exists
        if (userData['contactNumber'] != null) {
          _contactNumber = userData['contactNumber'] as int;
        } else {
          _contactNumber = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1C26),
      body: ListView(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(16),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: BorderSide(color: Colors.grey, width: 1.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (_profilePictureUrl != null)
                      CircleAvatar(
                        backgroundImage: NetworkImage(_profilePictureUrl!),
                        radius: 80,
                      ),
                    SizedBox(height: 20),
                    if (_name != null)
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.grey),
                          SizedBox(width: 10),
                          Text('Name: $_name',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18.0)),
                        ],
                      ),
                    SizedBox(height: 10),
                    Divider(),
                    SizedBox(height: 10),
                    if (_email != null)
                      Row(
                        children: [
                          Icon(Icons.email, color: Colors.grey),
                          SizedBox(width: 10),
                          Text('Email: $_email',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18.0)),
                        ],
                      ),
                    SizedBox(height: 10),
                    Divider(),
                    SizedBox(height: 10),
                    if (_contactNumber != null)
                      Row(
                        children: [
                          Icon(Icons.phone, color: Colors.grey),
                          SizedBox(width: 10),
                          Text('Contact Number: $_contactNumber',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18.0)),
                        ],
                      ),
                    SizedBox(height: 20),
                    Center(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UpdateUserProfile(
                                  name: _name ?? '',
                                  email: _email ?? '',
                                  contactNumber: _contactNumber ?? 0,
                                  onProfileUpdated:
                                      (name, location, email, contactNumber) {
                                    setState(() {
                                      _name = name;
                                      _email = email;
                                      _contactNumber = contactNumber;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UpdateUserProfile extends StatefulWidget {
  final String name;
  final String email;
  final int contactNumber;
  final Function(String, String, String, int) onProfileUpdated;

  const UpdateUserProfile({
    Key? key,
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  _UpdateUserProfileState createState() => _UpdateUserProfileState();
}

class _UpdateUserProfileState extends State<UpdateUserProfile> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _emailController;
  late TextEditingController _contactNumberController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _locationController = TextEditingController();
    _emailController = TextEditingController(text: widget.email);
    _contactNumberController =
        TextEditingController(text: widget.contactNumber.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Profile'),
      ),
      body: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey), // Add a grey border
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18), // Make text bold and bigger
                    decoration: InputDecoration(labelText: 'Name'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18), // Make text bold and bigger
                    decoration: InputDecoration(labelText: 'Address'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18), // Make text bold and bigger
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _contactNumberController,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18), // Make text bold and bigger
                    decoration: InputDecoration(labelText: 'Contact Number'),
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight, // Align to the right
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onProfileUpdated(
                        _nameController.text,
                        _locationController.text,
                        _emailController.text,
                        int.parse(_contactNumberController.text),
                      );
                      Navigator.pop(context);
                    },
                    child: Text('Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }
}
