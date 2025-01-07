class Event {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final DateTime date;
  final String venue;
  final String category;
  final String city;
  final double latitude;
  final double longitude;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.date,
    required this.venue,
    required this.category,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    try {
      final venue = json['_embedded']?['venues']?.first ?? {};
      final images = List<Map<String, dynamic>>.from(json['images'] ?? []);

      return Event(
        id: json['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name']?.toString() ?? 'İsimsiz Etkinlik',
        description: json['description']?.toString() ?? 'Açıklama bulunmuyor',
        imageUrl:
            images.isNotEmpty ? images.first['url']?.toString() ?? '' : '',
        date: DateTime.tryParse(json['dates']?['start']?['dateTime'] ?? '') ??
            DateTime.now(),
        venue: venue['name']?.toString() ?? 'Mekan bilgisi yok',
        category:
            json['classifications']?.first?['segment']?['name']?.toString() ??
                'Diğer',
        city: venue['city']?['name']?.toString() ?? 'Şehir bilgisi yok',
        latitude: double.tryParse(
                venue['location']?['latitude']?.toString() ?? '0') ??
            0,
        longitude: double.tryParse(
                venue['location']?['longitude']?.toString() ?? '0') ??
            0,
      );
    } catch (e) {
      print('Event parse hatası: $e');
      return Event(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Hata',
        description: 'Etkinlik bilgileri yüklenemedi',
        imageUrl: '',
        date: DateTime.now(),
        venue: '',
        category: '',
        city: '',
        latitude: 0,
        longitude: 0,
      );
    }
  }
}
