import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import '../models/comment_model.dart';
import '../services/event_service.dart';
import 'package:add_2_calendar/add_2_calendar.dart' as calendar;

class EventDetailScreen extends StatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final EventService _eventService = EventService();
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  bool _isFavorite = false;
  double _userRating = 0;

  String get _userName {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return 'Kullanıcı';

    // Önce displayName'i kontrol et
    if (currentUser.displayName?.isNotEmpty ?? false) {
      return currentUser.displayName!;
    }

    // Sonra email'i kontrol et
    if (currentUser.email?.isNotEmpty ?? false) {
      final emailName = currentUser.email!.split('@')[0];
      // Email adresinin ilk harfini büyük yap
      return emailName[0].toUpperCase() + emailName.substring(1);
    }

    // Son çare olarak UID'nin ilk 6 karakterini kullan
    return 'Kullanıcı ${currentUser.uid.substring(0, 6)}';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorum yapmak için giriş yapmalısınız'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      setState(() => _isLoading = true);
      await _eventService.addComment(
        widget.event.id,
        user!.uid,
        _userName,
        _commentController.text.trim(),
      );
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorumunuz eklendi'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Yorum ekleme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorum eklenirken bir hata oluştu'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadFavoriteStatus() async {
    if (user != null) {
      final isFav = await _eventService.isFavorite(widget.event.id, user!.uid);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Favorilere eklemek için giriş yapmalısınız'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _eventService.toggleFavorite(widget.event.id, user!.uid);
      setState(() => _isFavorite = !_isFavorite);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite
                ? 'Etkinlik favorilere eklendi'
                : 'Etkinlik favorilerden çıkarıldı'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Favori işlemi hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bir hata oluştu'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserRating() async {
    if (user != null) {
      final rating =
          await _eventService.getUserRating(widget.event.id, user!.uid);
      if (mounted && rating != null) {
        setState(() => _userRating = rating);
      }
    }
  }

  Future<void> _rateEvent(double rating) async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Puanlama yapmak için giriş yapmalısınız'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _eventService.rateEvent(widget.event.id, user!.uid, rating);
      setState(() => _userRating = rating);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Puanınız kaydedildi'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Puanlama hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Puanlama yapılırken bir hata oluştu'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Text(
          'Yorumlar',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        if (user != null)
          TextField(
            controller: _commentController,
            decoration: InputDecoration(
              hintText: 'Yorumunuzu yazın...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                onPressed: _isLoading ? null : _submitComment,
              ),
            ),
            maxLines: 3,
          )
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Yorum yapmak için giriş yapmalısınız'),
            ),
          ),
        const SizedBox(height: 16),
        StreamBuilder<List<Comment>>(
          stream: _eventService.getComments(widget.event.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print('StreamBuilder hatası: ${snapshot.error}');
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                          'Yorumlar yüklenirken hata oluştu: ${snapshot.error}'),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final comments = snapshot.data ?? [];
            comments.sort((a, b) => b.date.compareTo(a.date));

            if (comments.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Henüz yorum yapılmamış'),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              comment.userName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm')
                                  .format(comment.date),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(comment.text),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _eventService.getEventRating(widget.event.id),
      builder: (context, snapshot) {
        final averageRating = snapshot.data?['averageRating'] ?? 0.0;
        final ratingCount = snapshot.data?['ratingCount'] ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Puanlama',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ...List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _userRating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                    ),
                    onPressed: () => _rateEvent(index + 1.0),
                  );
                }),
                const SizedBox(width: 16),
                if (ratingCount > 0)
                  Text(
                    '${averageRating.toStringAsFixed(1)} (${ratingCount} oy)',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _loadUserRating();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Özel AppBar ve resim
          SliverAppBar(
            expandedHeight: 250,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, size: 50),
                      );
                    },
                  ),
                  // Gradient overlay
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),

          // İçerik
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Etkinlik başlığı ve kategori
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.event.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.event.category,
                            style: TextStyle(
                              color: Colors.orange[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Tarih ve konum bilgileri
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.calendar_today,
                                    size: 20, color: Colors.orange[900]),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('dd MMMM yyyy, HH:mm')
                                    .format(widget.event.date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.location_on,
                                    size: 20, color: Colors.blue[900]),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${widget.event.venue}, ${widget.event.city}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Butonlar
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: const Text('Takvime Ekle'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              final calendarEvent = calendar.Event(
                                title: widget.event.name,
                                description: widget.event.description,
                                location:
                                    '${widget.event.venue}, ${widget.event.city}',
                                startDate: widget.event.date,
                                endDate: widget.event.date
                                    .add(const Duration(hours: 2)),
                              );
                              calendar.Add2Calendar.addEvent2Cal(calendarEvent);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (widget.event.latitude != 0 &&
                            widget.event.longitude != 0)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final url =
                                    'https://www.google.com/maps/dir/?api=1&destination=${widget.event.latitude},${widget.event.longitude}';
                                _launchURL(context, url);
                              },
                              icon: const Icon(Icons.directions),
                              label: const Text('Yol Tarifi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Etkinlik detayları
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Etkinlik Detayları',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.event.description,
                            style: TextStyle(
                              height: 1.5,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Puanlama ve yorumlar
                    _buildRatingSection(),
                    const SizedBox(height: 24),
                    _buildCommentSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yol tarifi açılamadı')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bir hata oluştu')),
        );
      }
    }
  }
}
