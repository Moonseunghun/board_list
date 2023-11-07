import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login.dart';
import 'home.dart';
import 'post_detail.dart'; // import for PostDetail page

class MyBoard extends StatefulWidget {

  @override
  _MyBoardState createState() => _MyBoardState();
}

class _MyBoardState extends State<MyBoard> {
  late Stream<QuerySnapshot> _postStream;
   String? user;



// Stream for posts

  @override
  void initState() {
    super.initState();
    // Get the posts related to the current user
    _postStream = FirebaseFirestore.instance.collection('posts')
        .where('author', isEqualTo:user)
        .snapshots();
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate back to the login screen or any other screen after logout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      print('Error signing out: $e');
      // Handle error here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Posts'), // Adjust title
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _signOut(context);
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _postStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final posts = snapshot.data as QuerySnapshot<Map<String, dynamic>>;
              return ListView.builder(
                itemCount: posts.size,
                itemBuilder: (context, index) {
                  final post = posts.docs[index];
                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(post['title']),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostDetail(post),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewPostScreen(),
            ),
          );
        },
        tooltip: 'Create a new post',
        child: Icon(Icons.add),
      ),
    );
  }
}
