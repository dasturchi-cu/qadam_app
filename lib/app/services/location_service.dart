import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationService {
  List<Position> _positions = [];

  List<Position> get positions => _positions;

  // Joylashuv ruxsatini so'rash va olish
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  // Joylashuvni olish va massivga qo'shish
  Future<void> recordCurrentPosition() async {
    bool allowed = await requestPermission();
    if (!allowed) return;
    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _positions.add(pos);
    await savePositionToFirestore(pos);
  }

  // Firestore'ga saqlash
  Future<void> savePositionToFirestore(Position pos) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final trackDoc = userDoc.collection('tracks').doc(today);
    await trackDoc.set({
      'date': today,
      'positions': FieldValue.arrayUnion([
        {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'timestamp': pos.timestamp?.toIso8601String() ??
              DateTime.now().toIso8601String(),
        }
      ]),
    }, SetOptions(merge: true));
  }

  // Firestore'dan bugungi yo'lni olish
  Future<List<Map<String, dynamic>>> fetchTodayTrack() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final trackDoc = await userDoc.collection('tracks').doc(today).get();
    if (!trackDoc.exists) return [];
    final data = trackDoc.data();
    if (data == null || data['positions'] == null) return [];
    return List<Map<String, dynamic>>.from(data['positions']);
  }
}
