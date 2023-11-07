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
      Reference storageReference = FirebaseStorage.instance.ref().child('images/${DateTime.now()}.jpeg');
      UploadTask uploadTask = storageReference.putFile(File(pickedFile.path));

      try {
        await uploadTask;
        String downloadURL = await storageReference.getDownloadURL();
        return downloadURL;
      } catch (e) {
        print("Error during image upload: $e");
        throw Exception('이미지를 업로드하는 데 문제가 발생했습니다.');
      }
    }

    throw Exception('이미지를 선택하지 않았습니다.');
  }

  Future<void> _addComment(String postId, String comment, String imageURL) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').add({
      'text': comment,
      'imageURL': imageURL, // 이미지 URL을 Firestore에 저장
      'timestamp': FieldValue.serverTimestamp(),
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

  Future<void> _updateComment(String commentId , String newComment) async {
    await FirebaseFirestore.instance
        .collection('posts')
        .doc(post.id)
        .collection('comments')
        .doc(commentId)
        .update({
      'text': newComment, // 수정된 댓글 내용으로 업데이트
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(post['title']),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              post['content'],
              style: TextStyle(fontSize: 20.0),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String imageUrl = await _uploadImage();
                if (imageUrl != null) {
                  await _addComment(post.id, '', imageUrl);
                }
              },
              child: Text('이미지 업로드'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Implement video upload functionality
              },
              child: Text('동영상 업로드'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('게시물 수정'),
                      content: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(hintText: '새로운 내용을 입력하세요'),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('취소'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: Text('수정'),
                          onPressed: () async {
                            if (_commentController.text.isNotEmpty) {
                              _updatePost(post.id, _commentController.text);
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('게시물 수정'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _deletePost(post.id);
                Navigator.of(context).pop(); // Close the screen after deletion
              },
              child: Text('게시물 삭제'),
            ),
            SizedBox(height: 20),
            Text(
              '댓글',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
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
                        String commentId = document.id;

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(data['text']),
                            subtitle: data['imageURL'] != null ? Image.network(data['imageURL']) : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        String updatedComment = data['text'];
                                        return AlertDialog(
                                          title: Text('댓글 수정'),
                                          content: TextField(
                                            controller: TextEditingController(text: updatedComment),
                                            onChanged: (value) {
                                              updatedComment = value;
                                            },
                                            decoration: InputDecoration(hintText: '수정된 댓글을 입력하세요'),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              child: Text('취소'),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: Text('수정'),
                                              onPressed: () async {
                                                if (updatedComment.isNotEmpty) {
                                                  _updateComment(commentId, updatedComment);
                                                  Navigator.of(context).pop();
                                                }
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteComment(commentId);
                                  },
                                ),
                              ],
                            ),
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('댓글 추가'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _commentController,
                            decoration: InputDecoration(hintText: '댓글을 입력하세요'),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              String imageUrl = await _uploadImage();
                              if (_commentController.text.isNotEmpty) {
                                await _addComment(post.id, _commentController.text, imageUrl);
                                _commentController.clear();
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text('이미지 업로드 후 댓글 추가'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: Text('댓글 추가'),
            ),
          ],
        ),
      ),
    );
  }
}
