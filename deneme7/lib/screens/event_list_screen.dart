import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final EventService _eventService = EventService();
  final TextEditingController _searchController = TextEditingController();
  List<Event> _events = [];
  List<String> _cities = [];
  bool _isLoading = false;
  String _selectedCategory = '';
  String _selectedCity = '';
  Position? _currentPosition;

  final List<String> categories = [
    'Tümü',
    'Music',
    'Festival',
    'Arts',
    'Theatre',
    'Sports',
    'Learning',
    'Community',
  ];

  final Map<String, String> categoryNames = {
    'Tümü': 'Tümü',
    'Music': 'Konser',
    'Festival': 'Festival',
    'Arts': 'Sergi',
    'Theatre': 'Tiyatro',
    'Sports': 'Spor',
    'Learning': 'Eğitim',
    'Community': 'Topluluk',
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final cities = await _eventService.getCities();
      if (mounted) {
        setState(() {
          _cities = ['Tüm Şehirler', ...cities];
        });
      }
      await _initializeLocation();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationDialog(
            'Konum servisi kapalı', 'Lütfen cihazınızın konum servisini açın.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationDialog('Konum izni reddedildi',
              'Yakınınızdaki etkinlikleri görebilmek için konum iznine ihtiyacımız var.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationDialog('Konum izni kalıcı olarak reddedildi',
            'Lütfen cihaz ayarlarından uygulama için konum iznini etkinleştirin.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
      await _fetchEvents();
    } catch (e) {
      print('Konum alma hatası: $e');
      _showLocationDialog(
          'Hata', 'Konum alınırken bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showLocationDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializeLocation();
            },
            child: const Text('Tekrar Dene'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchEvents() async {
    if (_currentPosition == null && _selectedCity.isEmpty) {
      _showLocationDialog('Konum Bulunamadı',
          'Etkinlikleri listeleyebilmek için konum iznine ihtiyacımız var veya bir şehir seçin.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final events = await _eventService.getEvents(
        keyword: _searchController.text,
        category: _selectedCategory == 'Tümü' ? '' : _selectedCategory,
        city: _selectedCity == 'Tüm Şehirler' ? '' : _selectedCity,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
        localEventsOnly: _selectedCity.isEmpty,
      );

      if (mounted) {
        setState(() => _events = events);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Etkinlik Ara',
              prefixIcon: const Icon(Icons.search, color: Colors.orange),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey),
                onPressed: () {
                  _searchController.clear();
                  _fetchEvents();
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onSubmitted: (_) => _fetchEvents(),
          ),
        ),
        Container(
          height: 50,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    categoryNames[category] ?? category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : '';
                    });
                    _fetchEvents();
                  },
                  backgroundColor: Colors.orange[50],
                  selectedColor: Colors.orange,
                  checkmarkColor: Colors.white,
                  elevation: 2,
                  pressElevation: 4,
                  shadowColor: Colors.orange.withOpacity(0.3),
                ),
              );
            },
          ),
        ),
        if (_cities.isNotEmpty)
          Container(
            height: 50,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _cities.length,
              itemBuilder: (context, index) {
                final city = _cities[index];
                final isSelected = _selectedCity == city;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      city,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCity = selected ? city : '';
                      });
                      _fetchEvents();
                    },
                    backgroundColor: Colors.blue[50],
                    selectedColor: Colors.blue,
                    checkmarkColor: Colors.white,
                    elevation: 2,
                    pressElevation: 4,
                    shadowColor: Colors.blue.withOpacity(0.3),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.orange))
              : _events.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _currentPosition == null
                                  ? 'Konum bilgisi alınamadı. Lütfen konum izni verin veya bir şehir seçin.'
                                  : 'Etkinlik bulunamadı',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _events.length,
                      itemBuilder: (context, index) {
                        final event = _events[index];
                        return EventCard(event: event);
                      },
                    ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class EventCard extends StatelessWidget {
  final Event event;

  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: event),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      event.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 50),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        event.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${event.date.day}/${event.date.month}/${event.date.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.location_on, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${event.venue}, ${event.city}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
