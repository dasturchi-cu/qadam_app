import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('To\'lovlar'),
        backgroundColor: Color(0xFF4CAF50),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('payments')
            .where('userId', isEqualTo: user?.uid)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Xatolik: ${snapshot.error}'));
          }

          final payments = snapshot.data?.docs ?? [];

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payment, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('To\'lovlar tarixi yo\'q'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index].data() as Map<String, dynamic>;
              final amount = payment['amount'] ?? 0;
              final status = payment['status'] ?? 'pending';
              final provider = payment['provider'] ?? 'Unknown';
              
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status),
                    child: Icon(
                      _getStatusIcon(status),
                      color: Colors.white,
                    ),
                  ),
                  title: Text('${amount.toString()} so\'m'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Provider: $provider'),
                      Text('Status: ${_getStatusText(status)}'),
                      Text(_formatDate(payment['date'])),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(_getStatusText(status)),
                    backgroundColor: _getStatusColor(status).withOpacity(0.2),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check;
      case 'pending':
        return Icons.access_time;
      case 'failed':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Tugallandi';
      case 'pending':
        return 'Kutilmoqda';
      case 'failed':
        return 'Xatolik';
      default:
        return 'Noma\'lum';
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    DateTime dateTime = (date as Timestamp).toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}