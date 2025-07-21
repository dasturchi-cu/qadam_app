import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qadam_app/app/models/challenge_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qadam_app/app/services/coin_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

class ChallengeService {
  final _challenges = FirebaseFirestore.instance.collection('challenges');

  // Real-time stream
  Stream<List<Map<String, dynamic>>> getChallengesStream() =>
      _challenges.snapshots().map((s) => s.docs.map((d) => d.data()).toList());

  // Progress yangilash
  Future<void> updateChallengeProgress(
      String challengeId, double progress) async {
    await _challenges.doc(challengeId).update({
      'progress': progress,
      'isCompleted': progress >= 1.0,
    });
  }

  // Challenge qo'shish
  Future<void> addChallenge(Map<String, dynamic> data) async {
    await _challenges.add(data);
  }
}

class MyBannerAdWidget extends StatefulWidget {
  const MyBannerAdWidget({Key? key}) : super(key: key);

  @override
  State<MyBannerAdWidget> createState() => _MyBannerAdWidgetState();
}

class _MyBannerAdWidgetState extends State<MyBannerAdWidget> {
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId:
          'ca-app-pub-7180097986291909/1830667352', // Sizning Banner Ad Unit ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() {}),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_bannerAd == null) {
      return SizedBox.shrink();
    }
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
