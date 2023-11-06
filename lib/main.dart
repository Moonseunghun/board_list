import 'dart:io';

import 'package:board_list/post_detail.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase 게시판',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyBoard(),
    );
  }
}

class MyBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase 게시판'),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('posts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          } else {
            return ListView.builder(
              itemCount: snapshot.data?.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot post = snapshot.data!.docs[index];
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
        },
      ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () async {
                final ImagePicker _picker = ImagePicker();
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

                if (image != null) {
                  // Upload the selected image to Firebase Storage
                  Reference ref = FirebaseStorage.instance.ref().child('images/${DateTime.now().toString()}');
                  UploadTask uploadTask = ref.putFile(File(image.path));

                  uploadTask.whenComplete(() async {
                    String imageUrl = await ref.getDownloadURL();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Image added')),
                    );
                  });
                }
              },
              tooltip: '이미지 추가',
              child: Icon(Icons.image),
            ),
            SizedBox(height: 16), // Add some space between the buttons
            FloatingActionButton(
              onPressed: () async {
                // Show dialog to add a new post with title and content
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    String title = '';
                    String content = '';

                    return AlertDialog(
                      title: Text('승훈의 작당모의 '),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextField(
                            decoration: InputDecoration(labelText: 'Title'),
                            onChanged: (value) {
                              title = value;
                            },
                          ),
                          TextField(
                            decoration: InputDecoration(labelText: 'Content'),
                            onChanged: (value) {
                              content = value;
                            },
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('취소'),
                        ),
                        TextButton(
                          onPressed: () async {
                            // Add the post details to Firebase Firestore
                            await FirebaseFirestore.instance.collection('posts').add({
                              'title': title,
                              'content': content,
                              'timestamp': FieldValue.serverTimestamp(),
                            });

                            // Show a message that the post has been added
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('New post added')),
                            );

                            Navigator.pop(context);
                          },
                          child: Text('추가'),
                        ),
                      ],
                    );
                  },
                );
              },
              tooltip: '새로운 게시물 작성',
              child: Icon(Icons.add),
            ),
          ],
        )

    );
  }
}