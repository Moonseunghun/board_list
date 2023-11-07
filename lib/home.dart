import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

class NewPostScreen extends StatefulWidget {
  @override
  _NewPostScreenState createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  String title = '';
  String content = '';
  XFile? image; // Variable to hold the selected image file
  String? user;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    userId();
  }

  Future<void> userId() async {
    user = await _storage.read(key: 'uid');
  }

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
                if (image != null) {
                  Reference ref = FirebaseStorage.instance.ref().child('images/${DateTime.now().toString()}');
                  await ref.putFile(File(image!.path));
                  String imageUrl = await ref.getDownloadURL();
                  await FirebaseFirestore.instance.collection('posts').add({
                    'user':user ,
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
                    'user':user ,
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
