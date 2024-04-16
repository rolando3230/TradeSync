import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';

class User {
  String position;
  String id;
  String name;
  String email;
  String password;
  String? profilePictureUrl;
  int? age;
  String? address;
  DateTime? birthday;
  int? contactNumber;
  bool isActive;
  String role;
  String? remark;

  User({
    this.position = '',
    this.id = '',
    this.name = '',
    this.email = '',
    this.password = '',
    this.profilePictureUrl,
    this.age,
    this.address,
    this.birthday,
    this.contactNumber,
    this.isActive = true,
    required this.role,
  });

  User.fromMap(Map<String, dynamic>? map)
      : position = map?['position'] ?? '',
        id = map?['id'] ?? '',
        name = map?['name'] ?? '',
        email = map?['email'] ?? '',
        password = map?['password'] ?? '',
        profilePictureUrl = map?['profilePictureUrl'] ?? null,
        age = map?['age'],
        address = map?['address'],
        birthday = (map?['birthday'] as Timestamp?)?.toDate(),
        contactNumber = map?['contactNumber'],
        isActive = map?['isActive'] ?? true,
        role = map?['role'] ?? 'user';

  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'profilePictureUrl': profilePictureUrl,
      'age': age,
      'address': address,
      'birthday': birthday,
      'contactNumber': contactNumber,
      'isActive': isActive,
      'role': role,
      'remark': remark,
    };
  }

  String get defaultProfilePicture => 'assets/images/default.jpeg';
}

Widget Photo(String? profilePictureUrl) {
  final imageSize = 120.0;

  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: 10,
    ),
    child: ClipOval(
      child: CachedNetworkImage(
        imageUrl: profilePictureUrl ?? '',
        width: imageSize,
        height: imageSize,
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
      ),
    ),
  );
}

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

String _remark = '';

class CustomAlertDialog extends StatelessWidget {
  final String message;

  CustomAlertDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'OK',
            style: TextStyle(color: Color(0xFF0D47A1)),
          ),
        ),
      ],
    );
  }
}

class NoChangesDialog extends StatelessWidget {
  final VoidCallback onDismiss;

  NoChangesDialog({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('No Changes Detected'),
      content: Text('You did not make any changes to the account details.'),
      actions: [
        TextButton(
          onPressed: () {
            onDismiss();
            Navigator.of(context).pop();
          },
          child: Text(
            'OK',
            style: TextStyle(color: Color(0xFF0D47A1)),
          ),
        ),
      ],
    );
  }
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> users = [];
  bool showActiveUsers = true;
  String searchQuery = '';
  String selectedRole = 'All Roles';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> _pickAndUploadImage(User user) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      String imageUrl = await _uploadImageToFirebaseStorage(user, file);

      await FirebaseFirestore.instance.collection('Users').doc(user.id).update({
        'profilePictureUrl': imageUrl,
      });

      setState(() {
        user.profilePictureUrl = imageUrl;
      });
    }
  }

  Future<List<User>> getUsersFromFirestore() async {
    List<User> users = [];
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('Users').get();
      snapshot.docs.forEach((doc) {
        users.add(User.fromMap(doc.data() as Map<String, dynamic>?));
      });
    } catch (e) {
      print(e.toString());
    }
    return users;
  }

  Future<void> fetchUsers() async {
    List<User> userList = await getUsersFromFirestore();
    setState(() {
      users = userList;
    });
  }

  Future<Uint8List?> getProfilePicture(String? filename) async {
    if (filename == null || filename.isEmpty) {
      return null;
    }

    try {
      final ref = FirebaseStorage.instance.ref('/profile_pictures/$filename');
      final data = await ref.getData().timeout(Duration(seconds: 5));
      return data;
    } catch (e) {
      print('Error fetching profile picture: $e');
      return null;
    }
  }

  Widget buildProfilePicture(User user) {
    final String imageUrl =
        user.profilePictureUrl ?? user.defaultProfilePicture;
    final bool isValidUrl = Uri.tryParse(imageUrl)?.isAbsolute ?? false;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
      ),
      child: ClipOval(
        child: isValidUrl
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: 120.0,
                height: 120.0,
                placeholder: (context, url) => CircularProgressIndicator(),
                errorWidget: (context, url, error) => Icon(Icons.error),
              )
            : Image.asset(
                user.defaultProfilePicture,
                width: 120.0,
                height: 120.0,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  void _showConfirmationDialog(User user, bool isActive) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Action'),
          content: isActive
              ? Text(
                  'Are you sure you want to activate this account?',
                  style: TextStyle(
                    color: Colors.greenAccent[700],
                    // You can add other styling properties here if needed
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Are you sure you want to deactivate this account?',
                      style: TextStyle(
                        color: Colors.red,
                        // You can add other styling properties here if needed
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      maxLines: 3,
                      decoration:
                          InputDecoration(labelText: 'Deactivation Remark'),
                      onChanged: (value) {
                        // Save the entered remark in a variable
                        _remark = value;
                      },
                    ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (!isActive && _remark.isNotEmpty) {
                  // Only update the remark if deactivating and a remark is provided
                  updateRemark(user, _remark);
                }
                updateUserStatus(user, isActive);
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void updateRemark(User user, String remark) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.id)
          .update({'remark': remark});
      fetchUsers();
    } catch (e) {
      print(e.toString());
    }
  }

  void _showNoChangesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return NoChangesDialog(
          onDismiss: () {
            // Handle the dialog dismissal if needed
          },
        );
      },
    );
  }

  void updateUserStatus(User user, bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.id)
          .update({'isActive': isActive});
      fetchUsers();
    } catch (e) {
      print(e.toString());
    }
  }

  List<User> filterUsersByRole(List<User> users, String selectedRole) {
    if (selectedRole == 'All Roles') {
      return users;
    } else {
      return users.where((user) => user.role == selectedRole).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    List<User> filteredUsers = showActiveUsers
        ? users.where((user) => user.isActive).toList()
        : users.where((user) => !user.isActive).toList();

    if (selectedRole != 'All Roles') {
      filteredUsers =
          filteredUsers.where((user) => user.role == selectedRole).toList();
    }

    if (searchQuery.isNotEmpty) {
      filteredUsers = filteredUsers
          .where((user) =>
              user.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0xFF0D47A1),
            title: Text('Manage Users'),
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          body: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 4, // You can adjust the elevation as needed
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    children: [
                      DropdownButton(
                        value: showActiveUsers,
                        onChanged: (bool? newValue) {
                          if (newValue != null) {
                            setState(() {
                              showActiveUsers = newValue;
                            });
                          }
                        },
                        items: [
                          DropdownMenuItem(
                            value: true,
                            child: Text(
                              'Active Accounts',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text(
                              'Deactivated Accounts',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: SizedBox(
                            width: kIsWeb ? 200.0 : double.infinity,
                            child: TextField(
                              onChanged: (value) {
                                setState(() {
                                  searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Search by Complete Name',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: kIsWeb ? 1 : null,
                              style: TextStyle(fontSize: kIsWeb ? 16.0 : null),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    key: Key('userList'),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      User user = filteredUsers[index];

                      return Visibility(
                        visible: user.role != 'admin',
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 4,
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.0),
                                child: buildProfilePicture(user),
                              ),
                              Divider(),
                              ListTile(
                                dense: kIsWeb,
                                title: Text(
                                  user.name,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.email),
                                    GestureDetector(
                                      onTap: () async {
                                        if (!user.isActive) {
                                          DocumentSnapshot userDoc =
                                              await FirebaseFirestore.instance
                                                  .collection('Users')
                                                  .doc(user.id)
                                                  .get();
                                          String remark = (userDoc.data()
                                                  as Map<String,
                                                      dynamic>?)?['remark'] ??
                                              'No remark available';

                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title:
                                                    Text('Deactivation Remark'),
                                                content: Text(remark),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text('OK'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        } else {
                                          _showConfirmationDialog(
                                              user, !user.isActive);
                                        }
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Switch(
                                            value: user.isActive,
                                            onChanged: (isActive) {
                                              _showConfirmationDialog(
                                                  user, isActive);
                                            },
                                          ),
                                          Text('Account Status'),
                                          if (!user.isActive)
                                            Icon(
                                              Icons.warning,
                                              color: Colors.red,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

Future<String> _uploadImageToFirebaseStorage(
    User user, PlatformFile file) async {
  try {
    if (file.bytes == null) {
      throw Exception('File bytes are null');
    }

    final Reference storageRef =
        FirebaseStorage.instance.ref().child('profile_pictures/${user.id}');
    final UploadTask uploadTask = storageRef.putData(file.bytes!);

    await uploadTask.whenComplete(() {});

    String imageUrl = await storageRef.getDownloadURL();

    return imageUrl;
  } catch (e) {
    print('Error uploading image: $e');
    return '';
  }
}

class UpdateConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  UpdateConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm Update'),
      content: Text(
        'Are you sure you want to update this account?',
        style: TextStyle(color: Colors.red),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          child: Text('Confirm'),
        ),
      ],
    );
  }
}
