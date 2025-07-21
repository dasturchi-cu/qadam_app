import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qadam_app/app/services/coin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShopItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String category;
  final String? imageUrl;
  final bool isAvailable;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isAvailable = true,
  });

  factory ShopItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShopItem(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'],
      isAvailable: data['isAvailable'] ?? true,
    );
  }
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<ShopItem> _allItems = [];
  List<ShopItem> _filteredItems = [];
  String _selectedCategory = 'Barchasi';
  bool _isLoading = true;

  final List<String> _categories = [
    'Barchasi',
    'Pul chiqarish',
    'Bonuslar',
    'Maxsus takliflar',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadShopItems();
  }

  Future<void> _loadShopItems() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('shop_items')
          .where('isAvailable', isEqualTo: true)
          .orderBy('priority', descending: true)
          .get();

      _allItems =
          snapshot.docs.map((doc) => ShopItem.fromFirestore(doc)).toList();
      _filterItems();
    } catch (e) {
      debugPrint('Do\'kon elementlarini yuklashda xatolik: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterItems() {
    if (_selectedCategory == 'Barchasi') {
      _filteredItems = _allItems;
    } else {
      _filteredItems = _allItems
          .where((item) => item.category == _selectedCategory)
          .toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Do\'kon',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E3A59),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<CoinService>(
            builder: (context, coinService, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB020).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Color(0xFFFFB020),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${coinService.totalCoins}',
                      style: const TextStyle(
                        color: Color(0xFFFFB020),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF667EEA),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF667EEA),
          onTap: (index) {
            _selectedCategory = _categories[index];
            _filterItems();
          },
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadShopItems,
              child: _filteredItems.isEmpty
                  ? _buildEmptyState()
                  : _buildShopGrid(),
            ),
    );
  }

  Widget _buildShopGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        return _buildShopItemCard(_filteredItems[index]);
      },
    );
  }

  Widget _buildShopItemCard(ShopItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rasm yoki icon
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _getCategoryColor(item.category).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: item.imageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            _getCategoryIcon(item.category),
                            size: 48,
                            color: _getCategoryColor(item.category),
                          );
                        },
                      ),
                    )
                  : Icon(
                      _getCategoryIcon(item.category),
                      size: 48,
                      color: _getCategoryColor(item.category),
                    ),
            ),
          ),

          // Ma'lumotlar
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3A59),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Color(0xFFFFB020),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.price}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFB020),
                            ),
                          ),
                        ],
                      ),
                      Consumer<CoinService>(
                        builder: (context, coinService, child) {
                          final canAfford =
                              coinService.totalCoins >= item.price;
                          return GestureDetector(
                            onTap: canAfford ? () => _purchaseItem(item) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: canAfford
                                    ? const Color(0xFF28A745)
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Sotib olish',
                                style: TextStyle(
                                  color: canAfford ? Colors.white : Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Do\'kon bo\'sh',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3A59),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hozircha bu kategoriyada mahsulotlar yo\'q',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseItem(ShopItem item) async {
    final coinService = Provider.of<CoinService>(context, listen: false);

    // Tasdiqlash dialogi
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.name} sotib olish'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.description),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFB020)),
                const SizedBox(width: 8),
                Text(
                  '${item.price} tanga',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB020),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sotib olish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await coinService.spendCoins(item.price, item.name);

      if (success) {
        // Xarid tarixini saqlash
        await _savePurchaseHistory(item);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} muvaffaqiyatli sotib olindi!'),
              backgroundColor: const Color(0xFF28A745),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(coinService.errorMessage ?? 'Xarid amalga oshmadi'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _savePurchaseHistory(ShopItem item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('purchases')
          .add({
        'itemId': item.id,
        'itemName': item.name,
        'price': item.price,
        'category': item.category,
        'purchaseDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Xarid tarixini saqlashda xatolik: $e');
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pul chiqarish':
        return const Color(0xFF28A745);
      case 'Bonuslar':
        return const Color(0xFFFFB020);
      case 'Maxsus takliflar':
        return const Color(0xFF667EEA);
      default:
        return const Color(0xFF6C757D);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Pul chiqarish':
        return Icons.account_balance_wallet;
      case 'Bonuslar':
        return Icons.card_giftcard;
      case 'Maxsus takliflar':
        return Icons.local_offer;
      default:
        return Icons.shopping_bag;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
