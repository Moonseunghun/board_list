import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class PostDetail extends StatelessWidget {
  final DocumentSnapshot post;
  final TextEditingController _commentController = TextEditingController();


  PostDetail(this.post);

  Future<void> _deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
  }

  Future<void> _updatePost(String postId, String newContent) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'content': newContent,
    });
  }

  Future<String> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Reference storageReference =
      FirebaseStorage.instance.ref().child('images/${DateTime.now()}.png');
      UploadTask uploadTask = storageReference.putFile(File(pickedFile.path));
      await uploadTask;
      String downloadURL = await storageReference.getDownloadURL();
      return downloadURL;
    }

    throw Exception('이미지를 업로드하는 데 문제가 발생했습니다.');
  }

  Future<void> _addComment(String postId, String comment) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').add({
      'text': comment,
      'timestamp': FieldValue.serverTimestamp(), // 댓글 시간을 기록합니다.
    });
  }

  Future<void> _deleteComment(String commentId) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(post.id)
        .collection('comments')
        .doc(commentId)
        .delete();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(post['title']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              post['content'],
              style: TextStyle(fontSize: 20.0),
            ),
            // 위젯 내부에 StreamBuilder 추가
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('posts').doc(post.id).collection('comments').snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('댓글을 불러오는 중 오류가 발생했습니다.');
                } else {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    return Column(
                      children: snapshot.data!.docs.map((DocumentSnapshot document) {
                        Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                        String commentId = document.id; // 해당 댓글의 ID 가져오기

                        return ListTile(
                          title: Text(data['text']),
                          subtitle: Text(data['timestamp'].toString()), // 시간 표시 방법은 적절히 포맷팅이 필요합니다.
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteComment(commentId); // 해당 댓글 ID를 전달하여 삭제 함수 호출
                            },
                          ),
                        );
                      }).toList(),
                    );
                  } else {
                    return Text('댓글이 없습니다.');
                  }
                }
              },
            ),

            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('댓글 추가'),
                      content: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(hintText: '댓글을 입력하세요'),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('취소'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('추가'),
                          onPressed: () async {
                            if (_commentController.text.isNotEmpty) {
                              await _addComment(post.id, _commentController.text);
                              _commentController.clear();
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('댓글 추가'),
            ),
            ElevatedButton(
              onPressed: () async {
                String imageUrl = await _uploadImage();
                if (imageUrl != null) {
                  // 이미지가 업로드되면 Firebase Firestore에 저장하는 로직
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc(post.id)
                      .update({'image': imageUrl});
                }
              },
              child: Text('이미지 업로드'),
            ),
            ElevatedButton(
              onPressed: () {
                // 동영상 업로드 기능 구현
                // 이 부분은 동영상 업로드 기능이 추가되면 구현되어야 합니다.
              },
              child: Text('동영상 업로드'),
            ),
            ElevatedButton(
              onPressed: () {
                _updatePost(post.id, '새로운 내용');
              },
              child: Text('게시물 수정'),
            ),
            ElevatedButton(
              onPressed: () {
                _deletePost(post.id);
                Navigator.of(context).pop(); // 삭제 후 화면을 닫습니다.
              },
              child: Text('게시물 삭제'),
            ),
          ],
        ),
      ),
    );
  }
}
