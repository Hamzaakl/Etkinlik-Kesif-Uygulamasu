import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/event_model.dart';
import 'event_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final List<Event> events;

  const MapScreen({super.key, required this.events});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  // Türkiye'nin merkezi koordinatları (Kırşehir civarı)
  static const LatLng turkeyCenter = LatLng(39.1667, 35.6667);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 12,
          ),
        ),
      );
    } catch (e) {
      print('Konum alınamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) {
      return const Center(
        child: Text('Yakınınızda etkinlik bulunamadı'),
      );
    }

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: turkeyCenter,
        zoom: 5.5,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _getCurrentLocation(); // Harita oluşturulduğunda konuma git
      },
      markers: widget.events.map((event) {
        return Marker(
          markerId: MarkerId(event.id),
          position: LatLng(event.latitude, event.longitude),
          infoWindow: InfoWindow(
            title: event.name,
            snippet: '${event.venue}, ${event.city}',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(event: event),
                ),
              );
            },
          ),
        );
      }).toSet(),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      zoomControlsEnabled: true,
      mapToolbarEnabled: true,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
