import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tradesync/login.dart';

class Users1 {
  final String id;
  final String passwordHash;
  final String email;
  final String name;
  final String? profilePictureUrl;
  final int? contactNumber;
  final String? location;
  final String role;
  final int? age; // Add age field
  final String? sex; // Add sex field

  Users1({
    required this.id,
    required this.passwordHash,
    required this.email,
    required this.name,
    this.profilePictureUrl,
    this.contactNumber,
    this.location,
    required this.role,
    this.age,
    this.sex,
  });

  factory Users1.fromPlainTextPassword({
    required String id,
    required String plainPassword,
    required String email,
    required String name,
    String? profilePictureUrl,
    int? contactNumber,
    bool isActive = false,
    String? location,
    String role = 'user',
    int? age,
    String? sex,
  }) {
    final passwordHash = _hashPassword(plainPassword);
    return Users1(
      id: id,
      passwordHash: passwordHash,
      email: email,
      name: name,
      profilePictureUrl: profilePictureUrl,
      contactNumber: contactNumber,
      location: location,
      role: role,
      age: age,
      sex: sex,
    );
  }

  static String _hashPassword(String plainPassword) {
    final bytes = utf8.encode(plainPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'passwordHash': passwordHash,
      'email': email,
      'name': name,
      'profilePictureUrl': profilePictureUrl,
      'contactNumber': contactNumber,
      'location': location,
      'role': role,
      'age': age,
      'sex': sex,
    };
  }
}

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController contactNumberController;
  late TextEditingController positionController;
  late TextEditingController ageController; // Add age controller
  Uint8List? imageBytes;
  int? contactNumber;
  bool isRegistering = false;
  double uploadProgress = 0.0;
  late List<TextEditingController> otpControllers;
  List<FocusNode> focusNodes = [];
  String? _selectedSex = 'male';

  late String error;

  @override
  void initState() {
    super.initState();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    nameController = TextEditingController();
    emailController = TextEditingController();
    contactNumberController = TextEditingController();
    positionController = TextEditingController();
    ageController = TextEditingController(); // Initialize age controller
    error = '';
    otpControllers = List.generate(6, (index) => TextEditingController());
    focusNodes = List.generate(6, (index) => FocusNode());
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    emailController.dispose();
    contactNumberController.dispose();
    positionController.dispose();
    ageController.dispose(); // Dispose age controller
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      if (!kIsWeb) {
        final pickedImage =
            await ImagePicker().getImage(source: ImageSource.gallery);
        if (pickedImage != null) {
          final imageBytes = await pickedImage.readAsBytes();
          setState(() {
            this.imageBytes = imageBytes;
          });
        }
      } else {
        final FilePickerResult? pickedImage =
            await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png'],
          allowMultiple: false,
        );

        if (pickedImage != null && pickedImage.files.isNotEmpty) {
          setState(() {
            imageBytes = pickedImage.files.single.bytes;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> registerUser() async {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        nameController.text.isEmpty ||
        positionController.text.isEmpty ||
        ageController.text.isEmpty ||
        _selectedSex == null) {
      setState(() {
        error = "Please fill in all required fields.";
      });
      return;
    }

    if (!_passwordsMatch()) {
      setState(() {
        error = "Passwords do not match.";
      });
      return;
    }

    setState(() {
      isRegistering = true;
      error = "";
      uploadProgress = 0.0;
    });

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user == null) {
        setState(() {
          error = "User registration failed.";
          isRegistering = false;
        });
        return;
      }

      final userId = userCredential.user!.uid;
      final currentUser = FirebaseAuth.instance.currentUser;

      final usersCollection = FirebaseFirestore.instance.collection('Users');

      final newUser = Users1.fromPlainTextPassword(
        id: userId,
        plainPassword: passwordController.text.trim(),
        email: emailController.text,
        name: nameController.text,
        profilePictureUrl: null,
        contactNumber: contactNumber,
        isActive: false,
        location: positionController.text,
        role: 'user',
        age: int.tryParse(ageController.text), // Set age from ageController
        sex: _selectedSex, // Set sex from _selectedSex
      );

      final userData = newUser.toJson();

      await usersCollection.doc(userId).set(userData);

      if (imageBytes != null) {
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures/$userId.jpeg');
        final UploadTask uploadTask = storageRef.putData(imageBytes!);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          setState(() {
            uploadProgress = progress;
          });
        });

        final TaskSnapshot storageSnapshot = await uploadTask;
        final profilePictureUrl = await storageSnapshot.ref.getDownloadURL();

        userData['profilePictureUrl'] = profilePictureUrl;
        await usersCollection.doc(userId).set(userData);
      }

      setState(() {
        error = "";
        isRegistering = false;
      });

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Account registration successful!.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e, stackTrace) {
      print('$e\n$stackTrace');
      setState(() {
        error = e.toString();
        isRegistering = false;
      });
    }
  }

  bool _passwordsMatch() {
    return passwordController.text == confirmPasswordController.text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Account'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.grey,
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  GestureDetector(
                    onTap: () {
                      pickImage();
                    },
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10.0),
                        border: Border.all(
                          color: Colors.grey,
                          width: 2.0,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: imageBytes != null
                            ? Image.memory(imageBytes!).image
                            : const AssetImage('assets/images/default.jpeg'),
                        child: imageBytes == null
                            ? Icon(Icons.add_a_photo, color: Colors.black)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      labelText: 'Enter your complete name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: positionController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.location_on),
                      labelText: 'Enter location',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: 'Enter email',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.password),
                      labelText: 'Enter password',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.password),
                      labelText: 'Confirm password',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today),
                      labelText: 'Enter your age',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedSex,
                    onChanged: (String? value) {
                      setState(() {
                        _selectedSex = value;
                      });
                    },
                    items: <String>['male', 'female']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person),
                      labelText: 'Select your sex',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_passwordsMatch()) {
                        registerUser();
                      } else {
                        setState(() {
                          error = "Passwords do not match.";
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'REGISTER',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (isRegistering) CircularProgressIndicator(),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    error,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
