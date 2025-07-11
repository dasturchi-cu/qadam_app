import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qadam_app/app/services/location_service.dart';

class MapTrackScreen extends StatefulWidget {
  const MapTrackScreen({Key? key}) : super(key: key);

  @override
  State<MapTrackScreen> createState() => _MapTrackScreenState();
}

class _MapTrackScreenState extends State<MapTrackScreen> {
  GoogleMapController? _mapController;
  List<LatLng> _trackPoints = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrack();
  }

  Future<void> _loadTrack() async {
    final service = LocationService();
    final points = await service.fetchTodayTrack();
    setState(() {
      _trackPoints = points
          .map((e) => LatLng(
                (e['lat'] as num).toDouble(),
                (e['lng'] as num).toDouble(),
              ))
          .toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bugungi yo‘lingiz')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trackPoints.isEmpty
              ? const Center(child: Text('Bugun yo‘l maʼlumoti yo‘q'))
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _trackPoints.first,
                    zoom: 16,
                  ),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('track'),
                      color: Colors.blue,
                      width: 5,
                      points: _trackPoints,
                    ),
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('start'),
                      position: _trackPoints.first,
                      infoWindow: const InfoWindow(title: 'Boshlanish'),
                    ),
                    if (_trackPoints.length > 1)
                      Marker(
                        markerId: const MarkerId('end'),
                        position: _trackPoints.last,
                        infoWindow: const InfoWindow(title: 'Tugash'),
                      ),
                  },
                  onMapCreated: (controller) => _mapController = controller,
                ),
    );
  }
}
