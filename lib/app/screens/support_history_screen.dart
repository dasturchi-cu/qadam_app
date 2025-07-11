import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SupportHistoryScreen extends StatelessWidget {
  const SupportHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Murojaat tarixi'),
      ),
      body: user == null
          ? const Center(child: Text('Foydalanuvchi aniqlanmadi.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('supports')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Xatolik: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Murojaatlar topilmadi.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final String subject = data['subject'] ?? '';
                    final String status = data['status'] ?? '';
                    final Timestamp? ts = data['date'] as Timestamp?;
                    final String date = ts != null ? '${ts.toDate().year}-${ts.toDate().month.toString().padLeft(2, '0')}-${ts.toDate().day.toString().padLeft(2, '0')}' : '';
                    return ListTile(
                      leading: const Icon(Icons.support_agent, color: Colors.blue),
                      title: Text(subject),
                      subtitle: Text(date),
                      trailing: Text(
                        status,
                        style: TextStyle(
                          color: status == 'Yopildi'
                              ? Colors.green
                              : status == 'Ko‘rib chiqilmoqda'
                                  ? Colors.orange
                                  : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
} 