import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

class ReferralScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Referral Dasturi'),
        backgroundColor: Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Referral statistikasi
            _buildReferralStats(user?.uid),
            SizedBox(height: 20),

            // Referral link
            _buildReferralLink(user?.uid, context),
            SizedBox(height: 20),

            // Referral ro'yxati
            _buildReferralList(user?.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralStats(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        int totalReferrals = 0;
        int totalReward = 0;

        if (snapshot.hasData) {
          totalReferrals = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            totalReward += (data['reward'] ?? 0) as int;
          }
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
                      totalReferrals.toString(),
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text('Taklif qilinganlar'),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      totalReward.toString(),
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    Text('Jami mukofot'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReferralLink(String? userId, BuildContext context) {
    final referralLink = 'https://qadam.app/ref/$userId';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sizning referral linkingiz:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(referralLink)),
                  IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: referralLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Link nusxalandi!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.share),
                    label: Text('Ulashish'),
                    onPressed: () => Share.share(referralLink),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralList(String? userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('referrals')
          .where('referrerId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        final referrals = snapshot.data?.docs ?? [];

        if (referrals.isEmpty) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Hali hech kim taklif qilinmagan'),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Taklif qilinganlar:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: referrals.length,
                itemBuilder: (context, index) {
                  final referral =
                      referrals[index].data() as Map<String, dynamic>;

                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text('Foydalanuvchi ${index + 1}'),
                    subtitle: Text(_formatDate(referral['date'])),
                    trailing: Text(
                      '+${referral['reward']} coin',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    DateTime dateTime = (date as Timestamp).toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}
