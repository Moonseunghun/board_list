import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class PostDetail extends StatelessWidget {
  final DocumentSnapshot post;
  final TextEditingController _commentController = TextEditingController();
  final String currentUserID = FirebaseAuth.instance.currentUser!.uid;
  String ? commentId;
  String ? newContent;
  String getCurrentUserID() {
    // Firebase Authentication을 통해 현재 사용자의 UID를 가져옵니다.
    final String currentUserID = FirebaseAuth.instance.currentUser!.uid;
    return currentUserID;
  }

  PostDetail(this.post);

  void someFunction() async {
    String currentUserID = getCurrentUserID();
    print(currentUserID);

    String postId = getCurrentUserID();
    String postAuthorID = getCurrentUserID();

    await deletePost(postId, postAuthorID);
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUserID).get();
      // 여기서 userSnapshot을 사용하여 해당 사용자의 데이터에 액세스할 수 있습니다.
      if (userSnapshot.exists) {
        // 사용자 데이터가 존재하는 경우
        var userData = userSnapshot.data();
        print('사용자 데이터: $userData');
      } else {
        // 사용자 데이터가 존재하지 않는 경우
        print('해당 사용자 데이터가 없습니다.');
      }
    } catch (e) {
      print('사용자 데이터를 가져오는 중 오류 발생: $e');
      // 에러 처리
    }
  }

  // 게시물 삭제 기능 구현
  Future<void> deletePost(String postId, String postAuthorID) async {
    if (currentUserID == postAuthorID) {
      try {
        await FirebaseFirestore.instance.collection('posts')
            .doc(postId)
            .delete();
      } catch (e) {
        print('게시물을 삭제하는 중 오류 발생: $e');
        // 에러 처리 로직
      }
    } else {
      print('작성자만 게시물을 삭제할 수 있습니다.');
      // 사용자에게 권한이 없음을 알리는 로직
    }
  }

  // 게시물 수정 기능 구현
  Future<void> updatePost(String postId, String newContent) async {
    // Firebase Authentication을 통해 현재 사용자의 ID를 가져옵니다.
    final String currentUserID = FirebaseAuth.instance.currentUser!.uid;
    // 게시물 수정에 앞서 해당 사용자가 게시물의 작성자인지 확인
    // (이 코드가 Firebase에서 가져온 사용자 ID와 게시물의 작성자 ID를 비교하는 것으로 바꿔야 합니다)
    if (currentUserID == '작성자의ID') {
      try {
        await FirebaseFirestore.instance.collection('posts').doc(postId).update(
            {
              'content': newContent,
            });
      } catch (e) {
        print('게시물을 수정하는 중 오류 발생: $e');
        // 에러 처리 로직
      }
    } else {
      print('작성자만 게시물을 수정할 수 있습니다.');
      // 사용자에게 권한이 없음을 알리는 로직
    }
  }

  Future<String> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Reference storageReference = FirebaseStorage.instance.ref().child(
          'images/${DateTime.now()}.jpeg');
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

  Future<void> _addComment(String postId, String comment,
      String imageURL) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).collection(
        'comments').add({
      'text': comment,
      'imageURL': imageURL, // 이미지 URL을 Firestore에 저장
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String postId, String commentId) async {
    // Firebase Authentication을 통해 현재 사용자의 ID를 가져옵니다.
    final String currentUserID = FirebaseAuth.instance.currentUser!.uid;
    // 댓글 삭제에 앞서 해당 사용자가 댓글의 작성자인지 확인
    // (이 코드가 Firebase에서 가져온 사용자 ID와 댓글의 작성자 ID를 비교하는 것으로 바꿔야 합니다)
    if (currentUserID == commentId) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .delete();
      } catch (e) {
        print('댓글을 삭제하는 중 오류 발생: $e');
        // 에러 처리 로직
      }
    } else {
      print('작성자만 댓글을 삭제할 수 있습니다.');
      // 사용자에게 권한이 없음을 알리는 로직
    }
  }

  Future<void> updateComment(String postId, String commentId,
      String newComment) async {
    // Firebase Authentication을 통해 현재 사용자의 ID를 가져옵니다.
    final String currentUserID = FirebaseAuth.instance.currentUser!.uid;

    // 댓글 수정에 앞서 해당 사용자가 댓글의 작성자인지 확인
    // (이 코드가 Firebase에서 가져온 사용자 ID와 댓글의 작성자 ID를 비교하는 것으로 바꿔야 합니다)
    if (currentUserID == '댓글의작성자의ID') {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .collection('comments')
            .doc(commentId)
            .update({
          'text': newComment,
        });
      } catch (e) {
        print('댓글을 수정하는 중 오류 발생: $e');
        // 에러 처리 로직
      }
    } else {
      print('작성자만 댓글을 수정할 수 있습니다.');
      // 사용자에게 권한이 없음을 알리는 로직
    }
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
                              updatePost(post.id, _commentController.text);
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

                deletePost(post.id, commentId!);
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
              stream: FirebaseFirestore.instance.collection('posts').doc(
                  post.id).collection('comments').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('댓글을 불러오는 중 오류가 발생했습니다.');
                } else {
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    return Column(
                      children: snapshot.data!.docs.map((
                          DocumentSnapshot document) {
                        Map<String, dynamic> data = document.data() as Map<
                            String,
                            dynamic>;
                        String commentId = document.id;

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(data['text']),
                            subtitle: data['imageURL'] != null ? Image.network(
                                data['imageURL']) : null,
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
                                            controller: TextEditingController(
                                                text: updatedComment),
                                            onChanged: (value) {
                                              updatedComment = value;
                                            },
                                            decoration: InputDecoration(
                                                hintText: '수정된 댓글을 입력하세요'),
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
                                                  updateComment(
                                                    commentId, updatedComment,newContent!);
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
                                    deleteComment(commentId , post as String);
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
                                await _addComment(
                                    post.id, _commentController.text, imageUrl);
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

