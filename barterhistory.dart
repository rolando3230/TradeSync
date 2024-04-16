import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BarterHistory extends StatefulWidget {
  @override
  _BarterHistoryState createState() => _BarterHistoryState();
}

class _BarterHistoryState extends State<BarterHistory> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search ',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Trades')
                  .where('verified', isEqualTo: true)
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                List<DocumentSnapshot> filteredDocs =
                    snapshot.data!.docs.where((doc) {
                  Map<String, dynamic> data =
                      doc.data() as Map<String, dynamic>;
                  String description = data['description'] ?? '';
                  String reportType = data['reportType'] ?? '';

                  return description.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          ) ||
                      reportType.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          );
                }).toList();

                return ListView(
                  children: filteredDocs.map((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;
                    String description = data['description'] ?? '';
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

                      List<dynamic> requests = data['request'] ?? [];
                      return Column(
                        children: requests.map((request) {
                          return InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Request: $request tapped'),
                                ),
                              );
                            },
                            child: Container(
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
                                      height: 300,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          fit: BoxFit.contain,
                                          image: NetworkImage(
                                            data['imageUrl'] ?? '',
                                          ),
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
                                            fontSize: 20,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Description: $description',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              'Requested by: $request',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    } else {
                      return SizedBox.shrink();
                    }
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
