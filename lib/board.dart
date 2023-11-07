import 'dart:io';

import 'package:board_list/post_detail.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:image_picker/image_picker.dart';


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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewPostScreen(),
            ),
          );
        },
        tooltip: '새로운 게시물 작성',
        child: Icon(Icons.add),
      ),
    );
  }
}

class NewPostScreen extends StatefulWidget {
  @override
  _NewPostScreenState createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  String title = '';
  String content = '';
  XFile? image; // Variable to hold the selected image file

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('새로운 게시물 작성'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(labelText: '제목'),
              onChanged: (value) {
                setState(() {
                  title = value;
                });
              },
            ),
            TextField(
              decoration: InputDecoration(labelText: '내용'),
              onChanged: (value) {
                setState(() {
                  content = value;
                });
              },
            ),
            SizedBox(height: 20),
            image != null
                ? Image.file(File(image!.path))
                : Text('이미지 첨부:'),
            IconButton(
              icon: Icon(Icons.camera_alt),
              onPressed: () async {
                final ImagePicker _picker = ImagePicker();
                XFile? selectedImage = await _picker.pickImage(source: ImageSource.gallery);
                setState(() {
                  image = selectedImage;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Upload image to Firebase Storage if an image is selected
                if (image != null) {
                  Reference ref = FirebaseStorage.instance.ref().child('images/${DateTime.now().toString()}');
                  await ref.putFile(File(image!.path));
                  String imageUrl = await ref.getDownloadURL();

                  // Add post details to Firestore with the image URL
                  await FirebaseFirestore.instance.collection('posts').add({
                    'title': title,
                    'content': content,
                    'imageUrl': imageUrl,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('게시물이 추가되었습니다')),
                  );
                } else {
                  // Add post details to Firestore without the image URL
                  await FirebaseFirestore.instance.collection('posts').add({
                    'title': title,
                    'content': content,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('게시물이 추가되었습니다 (이미지 없음)')),
                  );
                }

                Navigator.pop(context);
              },
              child: Text('추가'),
            ),
          ],
        ),
      ),
    );
  }
}

