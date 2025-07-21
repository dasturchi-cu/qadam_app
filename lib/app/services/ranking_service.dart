import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/src/widgets/framework.dart';
import '../models/ranking_model.dart';

class RankingService extends ChangeNotifier {
  List<RankingModel> _rankings = [];
  bool _isLoading = false;
  String? _error;

  List<RankingModel> get rankings => _rankings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRankings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      _rankings = [];
      int rank = 1;

      // Foydalanuvchilarni steps bo'yicha kamayish tartibida sortlab olish
      final sortedDocs = List.from(snapshot.docs);
      sortedDocs.sort((a, b) {
        final aSteps = a.data()['steps'] ?? 0;
        final bSteps = b.data()['steps'] ?? 0;
        return (bSteps as int).compareTo(aSteps as int);
      });

      for (var doc in sortedDocs) {
        final data = doc.data();
        _rankings.add(RankingModel(
          userId: doc.id,
          name: data['name'] ?? '',
          steps: data['steps'] ?? 0,
          rank: rank,
        ));
        rank++;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }


}
