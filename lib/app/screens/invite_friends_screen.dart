import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../services/analytics_service.dart';

class InviteFriendsScreen extends StatefulWidget {
  @override
  _InviteFriendsScreenState createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Do\'stlarni Taklif Qilish'),
        backgroundColor: Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInviteForm(),
            SizedBox(height: 20),
            _buildInviteStats(user?.uid),
            SizedBox(height: 20),
            _buildInviteHistory(user?.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteForm() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Do\'stingizni Taklif Qiling',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Do\'st email manzili',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.send),
                    label: Text('Taklif Yuborish'),
                    onPressed: _isLoading ? null : _sendInvite,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: Icon(Icons.share),
                  label: Text('Ulashish'),
                  onPressed: _shareInvite,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteStats(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('InviteModel')
          .where('inviterId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        int totalInvites = 0;
        int acceptedInvites = 0;
        
        if (snapshot.hasData) {
          totalInvites = snapshot.data!.docs.length;
          acceptedInvites = snapshot.data!.docs
              .where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'accepted')
              .length;
        }
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      totalInvites.toString(),
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text('Yuborilgan'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      acceptedInvites.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text('Qabul qilingan'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${totalInvites > 0 ? ((acceptedInvites / totalInvites) * 100).toInt() : 0}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text('Muvaffaqiyat'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInviteHistory(String? userId) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Taklif Tarixi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('InviteModel')
                .where('inviterId', isEqualTo: userId)
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

              final invites = snapshot.data?.docs ?? [];

              if (invites.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Hali taklif yuborilmagan')),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: invites.length,
                itemBuilder: (context, index) {
                  final invite = invites[index].data() as Map<String, dynamic>;
                  return InviteCard(invite: invite);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _sendInvite() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email manzilini kiriting')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Invite yuborish
      await FirebaseFirestore.instance.collection('InviteModel').add({
        'inviterId': user.uid,
        'inviterEmail': user.email,
        'friendEmail': _emailController.text.trim(),
        'status': 'pending',
        'date': FieldValue.serverTimestamp(),
      });

      // Analytics
      await AnalyticsService.logReferralInvite(inviteMethod: 'email');

      _emailController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Taklif muvaffaqiyatli yuborildi!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xatolik: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _shareInvite() async {
    final user = FirebaseAuth.instance.currentUser;
    final inviteLink = 'https://qadam.app/invite/${user?.uid}';
    
    await Share.share(
      'Qadam++ ilovasiga qo\'shiling va sog\'lom hayot kechiring! $inviteLink',
      subject: 'Qadam++ ga taklif',
    );

    // Analytics
    await AnalyticsService.logReferralInvite(inviteMethod: 'share');
  }
}

class InviteCard extends StatelessWidget {
  final Map<String, dynamic> invite;

  const InviteCard({required this.invite});

  @override
  Widget build(BuildContext context) {
    final status = invite['status'] ?? 'pending';
    final friendEmail = invite['friendEmail'] ?? '';
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(status),
        child: Icon(_getStatusIcon(status), color: Colors.white),
      ),
      title: Text(friendEmail),
      subtitle: Text(_formatDate(invite['date'])),
      trailing: Chip(
        label: Text(_getStatusText(status)),
        backgroundColor: _getStatusColor(status).withOpacity(0.2),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check;
      case 'pending':
        return Icons.access_time;
      case 'declined':
        return Icons.close;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Qabul qilindi';
      case 'pending':
        return 'Kutilmoqda';
      case 'declined':
        return 'Rad etildi';
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