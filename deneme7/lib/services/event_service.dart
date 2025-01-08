import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment_model.dart';

class EventService {
  static const String apiKey = 'TICKETMASTER-API';
  static const String baseUrl =
      'EVENT-URL';

  Future<List<Event>> getEvents({
    String? keyword,
    String? category,
    String? city,
    double? latitude,
    double? longitude,
    bool localEventsOnly = true,
  }) async {
    try {
      final queryParams = {
        'apikey': apiKey,
        'size': '100',
        'countryCode': 'TR',
        if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
        if (category != null && category.isNotEmpty)
          'classificationName': category,
        if (city != null && city.isNotEmpty) 'city': city,
        if (localEventsOnly && latitude != null && longitude != null) ...{
          'latlong': '$latitude,$longitude',
          'radius': '100',
          'unit': 'km',
        },
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      print('Requesting events from: $uri');

      final response = await http.get(uri);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['_embedded'] == null) {
          print('No events found');
          if (localEventsOnly) {
            print('Trying to fetch country-wide events...');
            return getEvents(
              keyword: keyword,
              category: category,
              city: city,
              localEventsOnly: false,
            );
          }
          return [];
        }

        final events = data['_embedded']['events'] as List;
        return events.map((event) => Event.fromJson(event)).toList();
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  Future<List<String>> getCities() async {
    try {
      final queryParams = {
        'apikey': apiKey,
        'countryCode': 'TR',
        'size': '200',
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      print('Requesting cities from: $uri');

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['_embedded'] == null) return [];

        final events = data['_embedded']['events'] as List;
        final Set<String> cities = {};

        for (var event in events) {
          try {
            final venue = event['_embedded']?['venues']?.first;
            final cityName = venue?['city']?['name'] as String?;
            if (cityName != null && cityName.isNotEmpty) {
              cities.add(cityName);
            }
          } catch (e) {
            print('Error extracting city: $e');
          }
        }

        return cities.toList()..sort();
      }
      return [];
    } catch (e) {
      print('Error fetching cities: $e');
      return [];
    }
  }

  Future<bool> isFavorite(String eventId, String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('favorites')
          .doc('${userId}_$eventId')
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  Future<void> toggleFavorite(String eventId, String userId) async {
    final docRef = FirebaseFirestore.instance
        .collection('favorites')
        .doc('${userId}_$eventId');

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'userId': userId,
        'eventId': eventId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> addComment(
      String eventId, String userId, String userName, String text) async {
    print('Yorum ekleniyor: userName=$userName');
    await FirebaseFirestore.instance.collection('comments').add({
      'eventId': eventId,
      'userId': userId,
      'userName': userName.trim(),
      'text': text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Comment>> getComments(String eventId) {
    try {
      print('Yorumlar getiriliyor. EventId: $eventId');
      return FirebaseFirestore.instance
          .collection('comments')
          .where('eventId', isEqualTo: eventId)
          .limit(50)
          .snapshots()
          .map((snapshot) {
        print('Yorum sayısı: ${snapshot.docs.length}');
        return snapshot.docs.map((doc) {
          try {
            return Comment.fromFirestore(doc);
          } catch (e) {
            print('Yorum parse hatası: $e');
            rethrow;
          }
        }).toList();
      });
    } catch (e) {
      print('Yorumları getirme hatası: $e');
      rethrow;
    }
  }

  Future<void> rateEvent(String eventId, String userId, double rating) async {
    await FirebaseFirestore.instance
        .collection('ratings')
        .doc('${userId}_$eventId')
        .set({
      'eventId': eventId,
      'userId': userId,
      'rating': rating,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Ortalama puanı güncelle
    final ratingsSnapshot = await FirebaseFirestore.instance
        .collection('ratings')
        .where('eventId', isEqualTo: eventId)
        .get();

    double totalRating = 0;
    int ratingCount = ratingsSnapshot.docs.length;

    for (var doc in ratingsSnapshot.docs) {
      totalRating += (doc.data()['rating'] as num).toDouble();
    }

    await FirebaseFirestore.instance.collection('events').doc(eventId).set({
      'averageRating': totalRating / ratingCount,
      'ratingCount': ratingCount,
    }, SetOptions(merge: true));
  }

  Future<double?> getUserRating(String eventId, String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('ratings')
        .doc('${userId}_$eventId')
        .get();

    if (doc.exists) {
      return (doc.data()?['rating'] as num?)?.toDouble();
    }
    return null;
  }

  Stream<Map<String, dynamic>> getEventRating(String eventId) {
    return FirebaseFirestore.instance
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((doc) => {
              'averageRating':
                  (doc.data()?['averageRating'] as num?)?.toDouble() ?? 0.0,
              'ratingCount': doc.data()?['ratingCount'] ?? 0,
            });
  }

  Future<Event?> getEventById(String eventId) async {
    try {
      final queryParams = {
        'apikey': apiKey,
        'id': eventId,
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['_embedded']?['events'] == null) return null;

        final eventData = data['_embedded']['events'][0];
        return Event.fromJson(eventData);
      }
      return null;
    } catch (e) {
      print('Error fetching event: $e');
      return null;
    }
  }
}
