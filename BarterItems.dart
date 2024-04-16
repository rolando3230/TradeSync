import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreateReport extends StatefulWidget {
  const CreateReport({
    Key? key,
  }) : super(key: key);

  @override
  State<CreateReport> createState() => _CreateReportState();
}

class _CreateReportState extends State<CreateReport> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TextEditingController descriptionController;
  late TextEditingController headcount;
  late String selectedReportType;
  String? errorMessage;
  final picker = ImagePicker();
  PickedFile? _image;
  int itemCount = 0;

  @override
  void initState() {
    super.initState();
    descriptionController = TextEditingController();
    headcount = TextEditingController(text: '0');
    selectedReportType = 'BrandNew';
    getCurrentUserName();
    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    headcount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          DropdownButtonFormField<String>(
            value: selectedReportType,
            onChanged: (newValue) {
              setState(() {
                selectedReportType = newValue!;
              });
            },
            items: [
              'BrandNew',
              'Used',
              'Fair',
              'Worn', // Changed 'worn' to 'Worn' for consistency and uniqueness
            ].map((item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            decoration: InputDecoration(
              labelText: 'Select Item Type',
              border: OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
          const SizedBox(height: 10.0),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              children: [
                Text(
                  'Number of Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                    color: Color.fromARGB(189, 0, 0, 0),
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      itemCount++;
                    });
                  },
                  icon: Icon(Icons.arrow_upward),
                ),
                Text('$itemCount'),
                IconButton(
                  onPressed: () {
                    setState(() {
                      itemCount = itemCount > 0 ? itemCount - 1 : 0;
                    });
                  },
                  icon: Icon(Icons.arrow_downward),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              Text(
                'Description',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: Color.fromARGB(189, 0, 0, 0),
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          TextField(
            controller: descriptionController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Type your description here',
              border: OutlineInputBorder(),
              contentPadding: const EdgeInsets.all(16.0),
            ),
          ),
          const SizedBox(height: 10.0),
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
            title: Text('Submit Photo'),
            trailing: IconButton(
              padding: EdgeInsets.all(0),
              icon: Icon(Icons.image_search),
              onPressed: _getImage,
            ),
          ),
          if (_image != null)
            Container(
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(_image!.path)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 10.0),
          ElevatedButton(
            onPressed: () async {
              await _showConfirmationDialog();
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              primary: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Submit Item',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                errorMessage!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16.0,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showConfirmationDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Submission'),
          content: Text('Are you sure you want to submit this report?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 244, 54, 54),
              ),
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 54, 184, 244),
              ),
              child: Text('Submit', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
                _createReport();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> saveCurrentUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String username = user.displayName ?? "No Name Provided";

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_name', username);
    }
  }

  Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('current_user_name');
  }

  Future<void> _getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile;
    });
  }

  Future<String?> _uploadImage() async {
    if (_image == null) return null;
    final file = File(_image!.path);
    if (await file.length() > 2 * 1024 * 1024) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Image Size Limit Exceeded'),
          content: Text('Please select an image smaller than 2MB.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      return null;
    }
    final Reference storageReference =
        FirebaseStorage.instance.ref().child('report_images/${DateTime.now()}');
    UploadTask uploadTask = storageReference.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> _createReport() async {
    final imageUrl = await _uploadImage();

    const int maxImageSizeBytes = 2 * 1024 * 1024;

    if (_image != null && File(_image!.path).lengthSync() > maxImageSizeBytes) {
      _showAlertDialog('Image Size Limit Exceeded',
          'Please select an image smaller than 2MB.');
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser != null ? currentUser.uid : 'unknown_user_id';

      final userDocSnapshot = await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .get();
      final userName =
          userDocSnapshot.exists ? userDocSnapshot['name'] : 'Unknown User';
      final docUser = _firestore.collection('Trades').doc();
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        final newReport = Report(
          documentId: docUser.id,
          imageUrl: imageUrl,
          date: Timestamp.now(),
          inspectorName: userName,
          userId: _auth.currentUser?.uid,
          reportType: selectedReportType,
          description: descriptionController.text,
          verified: false,
        );

        setState(() {
          headcount.text = '0';
          descriptionController.text = '';
          errorMessage =
              'No internet connection. Report will be submitted when online.';
        });

        Fluttertoast.showToast(
          msg: 'No internet connection. Report saved as a pending request.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
        );
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            errorMessage = null;
          });
        });

        return;
      }

      final newReport = Report(
        documentId: docUser.id,
        imageUrl: imageUrl,
        date: Timestamp.now(),
        inspectorName: userName,
        userId: _auth.currentUser?.uid,
        reportType: selectedReportType,
        description: descriptionController.text,
        verified: false,
      );

      final json = newReport.toJson();
      await docUser.set(json);

      setState(() {
        headcount.text = '0';
        descriptionController.text = '';
        errorMessage = null;
      });

      Fluttertoast.showToast(
        msg: 'Report submitted successfully.',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
      );

      // Update button click status and add user name to the 'request' field
      await _updateButtonClickStatus(true);
      await _addToRequestField(userName);
      await _addToClickField(userName);
    } catch (e) {
      print('Error creating report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report. Please try again later.'),
        ),
      );
    }
  }

  Future<void> _addToRequestField(String userName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('Trades').doc(userId).update({
        'request': FieldValue.arrayUnion([userName]),
      });
    }
  }

  Future<void> _addToClickField(String userName) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;
    if (userId != null) {
      await _firestore
          .collection('Trades')
          .doc(userId)
          .collection('click')
          .doc()
          .set({
        'userName': userName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateButtonClickStatus(bool clicked) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;
    if (userId != null) {
      await _firestore.collection('Users').doc(userId).update({
        'buttonClicked': clicked,
      });
    }
  }

  Future<bool> _isButtonClickStatusTrue() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;
    if (userId != null) {
      final userDoc = await _firestore.collection('Users').doc(userId).get();
      return userDoc.exists ? userDoc['buttonClicked'] : false;
    }
    return false;
  }
}

class Report {
  final String? documentId;
  final String description; // Changed 'feedback' to 'description'
  final String reportType;
  final String? userId;
  final bool verified;
  final Timestamp date;
  final String inspectorName;
  final String? imageUrl;

  Report({
    required this.documentId,
    required this.description,
    required this.reportType,
    required this.userId,
    required this.verified,
    required this.date,
    required this.inspectorName,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'description': description,
      'reportType': reportType,
      'userId': userId,
      'verified': verified,
      'date': date,
      'inspectorName': inspectorName,
      'imageUrl': imageUrl,
    };
  }
}
