import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifiedReportsPage extends StatefulWidget {
  @override
  _VerifiedReportsPageState createState() => _VerifiedReportsPageState();
}

class _VerifiedReportsPageState extends State<VerifiedReportsPage> {
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search), // Icon you want to add
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Trades')
                  .where('verified', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var filteredDocs = snapshot.data!.docs.where((doc) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  String description = data['description'] ?? '';
                  String reportType = data['reportType'] ?? '';

                  return reportType.toLowerCase().contains(searchText) ||
                      description.toLowerCase().contains(searchText);
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    Map<String, dynamic> data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    String description = data['description'] ?? '';
                    String reportType = data['reportType'] ?? '';
                    Color conditionColor = Colors.black;

                    if (reportType.isNotEmpty) {
                      switch (reportType.toLowerCase()) {
                        case 'brandnew':
                          conditionColor = Colors.green;
                          break;
                        case 'fair':
                          conditionColor = Colors.blue;
                          break;
                        case 'used':
                          conditionColor = Colors.pink;
                          break;
                        case 'worn':
                          conditionColor = Colors.red;
                          break;
                        default:
                          conditionColor = Colors.black;
                          break;
                      }

                      return Container(
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                        child: Card(
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 300, // Adjust the height here
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    fit: BoxFit.contain,
                                    image: NetworkImage(data['imageUrl'] ?? ''),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  title: Text(
                                    'Condition: $reportType',
                                    style: TextStyle(
                                      color: conditionColor,
                                      fontSize: 20, // Adjust the font size here
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Description: $description',
                                        style: TextStyle(
                                          fontSize:
                                              16, // Adjust the font size here
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      RequestButton(
                                          docId: filteredDocs[index].id),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RequestButton extends StatefulWidget {
  final String docId;

  const RequestButton({Key? key, required this.docId}) : super(key: key);

  @override
  _RequestButtonState createState() => _RequestButtonState();
}

class _RequestButtonState extends State<RequestButton> {
  bool clicked = false;

  @override
  void initState() {
    super.initState();
    checkButtonClickStatus();
  }

  @override
  void dispose() {
    super.dispose();
    // Dispose any resources here
  }

  void checkButtonClickStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      // Check if the widget is still mounted
      DocumentSnapshot clickDoc = await FirebaseFirestore.instance
          .collection('Trades')
          .doc(widget.docId)
          .collection('click')
          .doc(user.uid)
          .get();
      if (mounted) {
        // Check again before updating the state
        setState(() {
          clicked = clickDoc.exists;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null && !clicked && mounted) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(user.uid)
              .get();
          String userName = userDoc['name'] ?? '';
          await FirebaseFirestore.instance
              .collection('Trades')
              .doc(widget.docId)
              .update({
            'request': FieldValue.arrayUnion([userName])
          });

          await FirebaseFirestore.instance
              .collection('Trades')
              .doc(widget.docId)
              .collection('click')
              .doc(user.uid)
              .set({
            'clickedAt': DateTime.now(),
          });

          if (mounted) {
            setState(() {
              clicked = true;
            });
          }
        } else if (user != null && clicked && mounted) {
          setState(() {
            clicked = true;
          });
        }
      },
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (clicked) {
            return Colors.grey; // Change color to grey if clicked
          }
          return Colors.green; // Default color
        }),
      ),
      child: Text(clicked ? 'Requested' : 'Request'),
    );
  }
}
