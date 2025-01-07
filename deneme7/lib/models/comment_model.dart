import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime date;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.date,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      print('Yorum verisi: $data');

      DateTime commentDate;
      try {
        final timestamp = data['timestamp'] as Timestamp?;
        commentDate = timestamp?.toDate() ?? DateTime.now();
      } catch (e) {
        print('Tarih parse hatası: $e');
        commentDate = DateTime.now();
      }

      final userName = data['userName']?.toString();
      return Comment(
        id: doc.id,
        userId: data['userId']?.toString() ?? '',
        userName: userName?.isNotEmpty == true ? userName! : 'Kullanıcı',
        text: data['text']?.toString() ?? '',
        date: commentDate,
      );
    } catch (e) {
      print('Comment.fromFirestore hatası: $e');
      rethrow;
    }
  }
}
