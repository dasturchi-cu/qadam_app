import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/analytics_service.dart';

class WithdrawScreen extends StatefulWidget {
  @override
  _WithdrawScreenState createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'bank_card';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Pul Yechish'),
        backgroundColor: Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBalanceCard(user?.uid),
            SizedBox(height: 20),
            _buildWithdrawForm(),
            SizedBox(height: 20),
            _buildWithdrawHistory(user?.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(String? userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        int availableCoins = 0;
        if (snapshot.hasData && snapshot.data!.exists) {
          availableCoins = (snapshot.data!.data() as Map<String, dynamic>)['coins'] ?? 0;
        }
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Mavjud Balans',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  '$availableCoins coin',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '≈ ${(availableCoins * 0.1).toStringAsFixed(2)} so\'m',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWithdrawForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yechish So\'rovi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Miqdor (coin)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monetization_on),
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: InputDecoration(
                labelText: 'To\'lov usuli',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: [
                DropdownMenuItem(value: 'bank_card', child: Text('Bank kartasi')),
                DropdownMenuItem(value: 'paypal', child: Text('PayPal')),
                DropdownMenuItem(value: 'uzcard', child: Text('UzCard')),
                DropdownMenuItem(value: 'humo', child: Text('Humo')),
              ],
              onChanged: (value) => setState(() => _selectedMethod = value!),
            ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitWithdrawRequest,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('So\'rov Yuborish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawHistory(String? userId) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'So\'rovlar Tarixi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('withdraw_requests')
                .where('userId', isEqualTo: userId)
                .orderBy('date', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final requests = snapshot.data?.docs ?? [];

              if (requests.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('So\'rovlar yo\'q')),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index].data() as Map<String, dynamic>;
                  return WithdrawRequestCard(request: request);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _submitWithdrawRequest() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Miqdorni kiriting')),
      );
      return;
    }

    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('To\'g\'ri miqdor kiriting')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Balansni tekshirish
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userCoins = (userDoc.data()?['coins'] ?? 0) as int;
      
      if (userCoins < amount) {
        throw Exception('Yetarli balans yo\'q');
      }

      // Withdraw request yaratish
      await FirebaseFirestore.instance.collection('withdraw_requests').add({
        'userId': user.uid,
        'amount': amount,
        'method': _selectedMethod,
        'status': 'pending',
        'date': FieldValue.serverTimestamp(),
      });

      // Analytics
      await AnalyticsService.logWithdrawalRequest(
        amount: amount,
        method: _selectedMethod,
      );

      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('So\'rov muvaffaqiyatli yuborildi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class WithdrawRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;

  const WithdrawRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final status = request['status'] ?? 'pending';
    final amount = request['amount'] ?? 0;
    final method = request['method'] ?? '';
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(status),
        child: Icon(_getStatusIcon(status), color: Colors.white),
      ),
      title: Text('$amount coin'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Usul: ${_getMethodName(method)}'),
          Text(_formatDate(request['date'])),
        ],
      ),
      trailing: Chip(
        label: Text(_getStatusText(status)),
        backgroundColor: _getStatusColor(status).withOpacity(0.2),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check;
      case 'pending':
        return Icons.access_time;
      case 'rejected':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Tasdiqlandi';
      case 'pending':
        return 'Kutilmoqda';
      case 'rejected':
        return 'Rad etildi';
      default:
        return 'Noma\'lum';
    }
  }

  String _getMethodName(String method) {
    switch (method) {
      case 'bank_card':
        return 'Bank kartasi';
      case 'paypal':
        return 'PayPal';
      case 'uzcard':
        return 'UzCard';
      case 'humo':
        return 'Humo';
      default:
        return method;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    DateTime dateTime = (date as Timestamp).toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}