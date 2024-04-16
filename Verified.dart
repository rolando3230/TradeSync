import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Verified extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0D47A1),
        title: Text('Verify Items'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Report')
            .where('verified', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> data =
                  doc.data() as Map<String, dynamic>; // Get document data
              String feedback = data['feedback'] ?? '';
              String reportType = data['reportType'] ?? '';
              Color conditionColor = Colors.black;

              if (reportType.isNotEmpty) {
                switch (reportType) {
                  case 'BrandNew':
                    conditionColor = Colors.green;
                    break;
                  case 'Fair':
                    conditionColor = Colors.blue;
                    break;
                  case 'Used':
                    conditionColor = Colors.pink;
                    break;
                  case 'Worn':
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
                            subtitle: Text(
                              'Description: $feedback',
                              style: TextStyle(
                                fontSize: 16, // Adjust the font size here
                                fontWeight:
                                    FontWeight.bold, // Make the text bold
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () {
                                // Update Firestore document to set 'verified' to true
                                FirebaseFirestore.instance
                                    .collection('Report')
                                    .doc(doc.id)
                                    .update({'verified': true});
                              },
                              child: Icon(
                                Icons.check,
                                color: Colors.green,
                                size: 30,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Update Firestore document to set 'verified' to false
                                FirebaseFirestore.instance
                                    .collection('Report')
                                    .doc(doc.id)
                                    .update({'verified': 'declined'});
                              },
                              child: Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return SizedBox
                    .shrink(); // Return an empty SizedBox if reportType is empty
              }
            }).toList(),
          );
        },
      ),
    );
  }
}
