import 'package:cloud_firestore/cloud_firestore.dart';

class ShopService {
  final _shop = FirebaseFirestore.instance.collection('shop_items');

  Stream<List<Map<String, dynamic>>> getShopItems() =>
      _shop.snapshots().map((s) => s.docs.map((d) => d.data()).toList());
}
