import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tradesync/BarterItems.dart';
import 'package:tradesync/chat.dart';
import 'package:tradesync/login.dart';
import 'package:tradesync/profilescreen.dart';
import 'package:tradesync/barterscreen.dart';
import 'package:tradesync/barterhistory.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentIndex = 0;
  int _newRequestCount = 0;

  @override
  void initState() {
    super.initState();
    _listenForNewRequests();
  }

  void _listenForNewRequests() {
    _firestore.collection('Trades').snapshots().listen((snapshot) {
      snapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added &&
            change.doc.data()?['verified'] == true &&
            change.doc.data()?['request'] != null &&
            change.doc.data()?['userId'] ==
                FirebaseAuth.instance.currentUser!.uid) {
          _firestore
              .collection('Notifications')
              .where('userId',
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid)
              .where('tradeId', isEqualTo: change.doc.id)
              .get()
              .then((querySnapshot) {
            if (querySnapshot.docs.isEmpty) {
              setState(() {
                _newRequestCount++;
              });

              _firestore.collection('Notifications').add({
                'userId': FirebaseAuth.instance.currentUser!.uid,
                'tradeId': change.doc.id,
              });
            }
          });
        }
      });
    });
  }

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout Confirmation'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _handleLogout(context);
              },
              child: Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const Login()));
    } catch (e) {
      print('Error logging out: $e');
    }
  }

  void _clearNewRequestCount() {
    setState(() {
      _newRequestCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0D1C26),
          toolbarHeight: 80.0,
          actions: [
            Expanded(
              child: IconButton(
                iconSize: 40.0,
                icon: Icon(Icons.home),
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                },
              ),
            ),
            Expanded(
              child: IconButton(
                icon: Icon(Icons.library_books),
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
              ),
            ),
            Expanded(
              child: IconButton(
                icon: Icon(Icons.person),
                onPressed: () {
                  setState(() {
                    _currentIndex = 2;
                  });
                },
              ),
            ),
            Expanded(
              child: IconButton(
                icon: Stack(
                  children: <Widget>[
                    Icon(Icons.chat_outlined),
                  ],
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 3;
                  });
                },
              ),
            ),
            Expanded(
              child: IconButton(
                icon: Stack(
                  children: [
                    Icon(Icons.move_to_inbox_outlined),
                    if (_newRequestCount > 0)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '$_newRequestCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  setState(() {
                    _currentIndex = 4;
                    _clearNewRequestCount();
                  });
                },
              ),
            ),
            Expanded(
              child: IconButton(
                icon: Icon(Icons.logout),
                onPressed: () => _showLogoutConfirmationDialog(context),
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            VerifiedReportsPage(),
            CreateReport(),
            UserProfile(),
            UserSelectionPage(),
            BarterHistory(),
          ],
        ),
      ),
    );
  }
}
