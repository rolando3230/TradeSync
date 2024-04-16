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

enum UserRole {
  user,
  admin,
}

class Users1 {
  final String id;
  final String passwordHash;
  final String email;
  final String name;
  final String? profilePictureUrl;
  final int? contactNumber;
  final bool isActive;

  Users1(
      {required this.id,
      required this.passwordHash,
      required this.email,
      required this.name,
      this.profilePictureUrl,
      this.contactNumber,
      this.isActive = false,
      UserRole role = UserRole.user});

  factory Users1.fromPlainTextPassword({
    required String id,
    required String plainPassword,
    required String email,
    required String name,
    required UserRole role,
    String? profilePictureUrl,
    int? contactNumber,
    bool isActive = false,
  }) {
    final passwordHash = _hashPassword(plainPassword);
    return Users1(
      id: id,
      passwordHash: passwordHash,
      email: email,
      name: name,
      profilePictureUrl: profilePictureUrl,
      contactNumber: contactNumber,
      isActive: isActive,
      role: role,
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
      'isActive': isActive,
      'role': 'user'
    };
  }
}

class Register2 extends StatefulWidget {
  const Register2({Key? key}) : super(key: key);

  @override
  State<Register2> createState() => _Register2State();
}

class _Register2State extends State<Register2> {
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  late TextEditingController nameController;
  late TextEditingController emailController;
  String gender = 'Male';
  late TextEditingController contactNumberController;
  late TextEditingController addressController; // Add this line
  late TextEditingController ageController;
  late String error;
  late TextEditingController positionController;
  UserRole selectedRole = UserRole.user; // Default role is "user"
  Uint8List? imageBytes;
  int? contactNumber;
  bool isRegistering = false;
  bool isPasswordObscured = true;
  bool isConfirmPasswordObscured = true;
  double uploadProgress = 0.0;
  List<FocusNode> focusNodes = [];

  @override
  void initState() {
    super.initState();
    addressController =
        TextEditingController(); // Initialize the addressController
    ageController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    nameController = TextEditingController();
    emailController = TextEditingController();
    contactNumberController = TextEditingController();
    positionController = TextEditingController();
    error = "";
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
    addressController.dispose();
    super.dispose();
  }

  void togglePasswordVisibility() {
    setState(() {
      isPasswordObscured = !isPasswordObscured;
    });
  }

  Future<void> pickImage() async {
    try {
      if (!kIsWeb) {
        // This code will run on non-web platforms (i.e., mobile)
        // You can add your mobile-specific image picking logic here
        // For example, you can use the image_picker package:
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

  void toggleConfirmPasswordVisibility() {
    setState(() {
      isConfirmPasswordObscured = !isConfirmPasswordObscured;
    });
  }

  Future<void> registerUser() async {
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
        role: selectedRole,
        profilePictureUrl: null,
        contactNumber: contactNumber,
        isActive: false,
      );

      final userData = newUser.toJson();

      await usersCollection.doc(userId).set(userData);

      if (imageBytes != null) {
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures/$userId.jpg');
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
            content: const Text(
                'Account registration successful! Please wait for your account to be activated.'),
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
                    controller: emailController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email),
                      labelText: 'Enter email',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: isPasswordObscured,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.password),
                      labelText: 'Enter password',
                      suffixIcon: IconButton(
                        icon: isPasswordObscured
                            ? Icon(Icons.visibility_off)
                            : Icon(Icons.visibility),
                        onPressed: togglePasswordVisibility,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: isConfirmPasswordObscured,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.password),
                      labelText: 'Confirm password',
                      suffixIcon: IconButton(
                        icon: isConfirmPasswordObscured
                            ? Icon(Icons.visibility_off)
                            : Icon(Icons.visibility),
                        onPressed: toggleConfirmPasswordVisibility,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color.fromARGB(255, 134, 127, 127),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          '63+',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: TextField(
                          controller: contactNumberController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Enter contact number',
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) {
                            setState(() {
                              contactNumber = int.tryParse(value);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.location_on),
                      labelText: 'Enter address',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.calendar_today),
                      labelText: 'Enter age',
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Gender:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: gender,
                        onChanged: (String? value) {
                          setState(() {
                            gender = value!;
                          });
                        },
                        items: <String>['Male', 'Female']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
