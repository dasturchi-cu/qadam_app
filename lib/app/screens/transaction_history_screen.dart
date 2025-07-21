import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/analytics_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  @override
  _TransactionHistoryScreenState createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    AnalyticsService.logCustomEvent('transaction_history_viewed', {});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tranzaksiya Tarixi'),
        backgroundColor: Color(0xFF4CAF50),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _selectedFilter = value),
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('Barchasi')),
              PopupMenuItem(value: 'income', child: Text('Daromad')),
              PopupMenuItem(value: 'expense', child: Text('Xarajat')),
              PopupMenuItem(value: 'withdrawal', child: Text('Yechish')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(user?.uid),
          Expanded(child: _buildTransactionsList(user?.uid)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        int totalIncome = 0;
        int totalExpense = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = data['amount'] ?? 0;
          if (amount > 0) {
            totalIncome += amount as int;
          } else {
            totalExpense += (amount as int).abs();
          }
        }

        return Card(
          margin: EdgeInsets.all(16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      '+$totalIncome',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text('Daromad'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '-$totalExpense',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text('Xarajat'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${totalIncome - totalExpense}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text('Balans'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsList(String? userId) {
    Query query = FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true);

    // Filter qo'llash
    if (_selectedFilter != 'all') {
      if (_selectedFilter == 'income') {
        // Faqat musbat miqdorlar
      } else if (_selectedFilter == 'expense') {
        // Faqat manfiy miqdorlar
      } else if (_selectedFilter == 'withdrawal') {
        query = query.where('type', isEqualTo: 'withdrawal');
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Xatolik: ${snapshot.error}'));
        }

        final transactions = snapshot.data?.docs ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Tranzaksiya tarixi yo\'q'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction =
                transactions[index].data() as Map<String, dynamic>;
            return TransactionCard(transaction: transaction);
          },
        );
      },
    );
  }
}

class TransactionCard extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final amount = transaction['amount'] ?? 0;
    final type = transaction['type'] ?? '';
    final description = transaction['description'] ?? '';
    final date = transaction['date'];

    final isPositive = amount > 0;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPositive ? Colors.green : Colors.red,
          child: Icon(
            _getTransactionIcon(type),
            color: Colors.white,
          ),
        ),
        title: Text(description),
        subtitle: Text(_formatDate(date)),
        trailing: Text(
          '${isPositive ? '+' : ''}$amount',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isPositive ? Colors.green : Colors.red,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'step_reward':
        return Icons.directions_walk;
      case 'challenge_reward':
        return Icons.emoji_events;
      case 'referral_bonus':
        return Icons.people;
      case 'purchase':
        return Icons.shopping_cart;
      case 'withdrawal':
        return Icons.account_balance_wallet;
      default:
        return Icons.monetization_on;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    DateTime dateTime = (date as Timestamp).toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}
