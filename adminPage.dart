import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tradesync/ManageUser.dart';
import 'package:tradesync/Verified.dart';
import 'package:tradesync/adminchat.dart';
import 'package:tradesync/login.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool showNewScheduleMessage = false;

  @override
  void initState() {
    super.initState();

    _checkNewSchedules();
  }

  Future<String> getUserName() async {
    final currentUser = _auth.currentUser;
    final userId = currentUser != null ? currentUser.uid : 'unknown_user_id';

    final userDocSnapshot =
        await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    final userName =
        userDocSnapshot.exists ? userDocSnapshot['name'] : 'Unknown User';
    return userName;
  }

  void _checkNewSchedules() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userId = currentUser.uid;
      FirebaseFirestore.instance
          .collection('schedules')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .listen((snapshot) {
        snapshot.docs.forEach((doc) {
          final scheduleId = doc.id;
          FirebaseFirestore.instance
              .collection('notifications')
              .doc(scheduleId)
              .get()
              .then((notificationDoc) {
            if (!notificationDoc.exists) {
              _showNewSchedulePopup(scheduleId);
              _saveShowNewScheduleMessage(scheduleId);
            }
          });
        });
      });
    }
  }

  void _showNewSchedulePopup(String scheduleId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'New Schedule Available! A new schedule is available for you.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.fixed,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUserName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        } else {
          final userName = snapshot.data;

          return Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 100.0,
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF0D47A1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 30, 10, 0),
                      child: ListTile(
                        title: Text(
                          'Welcome Admin $userName',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: IconButton(
                          onPressed: () async {
                            _showLogoutConfirmationDialog(context);
                          },
                          icon: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            body: Column(
              children: [
                const SizedBox(
                  height: 25,
                ),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    padding: const EdgeInsets.all(16.0),
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    children: [
                      FeatureCard(
                        icon: Icons.shopping_basket,
                        title: 'Verify Items',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Verified(),
                            ),
                          );
                        },
                      ),
                      FeatureCard(
                        icon: Icons.chat_bubble,
                        title: 'Chat Support',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserSelectionPage1(),
                            ),
                          );
                        },
                      ),
                      FeatureCard(
                        icon: Icons.manage_accounts_rounded,
                        title: 'Manage User',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserManagementScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Future<void> _saveShowNewScheduleMessage(String scheduleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showNewScheduleMessage', true);

    // Mark the notification as shown in the "notifications" collection
    FirebaseFirestore.instance.collection('notifications').doc(scheduleId).set({
      'shown': false,
    });
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const FeatureCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48.0,
            ),
            const SizedBox(height: 8.0),
            Text(
              title,
              style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.blue[900],
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
