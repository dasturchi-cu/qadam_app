import 'package:flutter/material.dart';
import 'package:qadam_app/app/services/transaction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TransactionHistoryScreen extends StatelessWidget {
  final transactionService = TransactionService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Foydalanuvchi topilmadi.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Tranzaksiya tarixi')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: transactionService.getUserTransactions(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final txs = snapshot.data!;
          if (txs.isEmpty) {
            return const Center(child: Text('Tranzaksiyalar topilmadi.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: txs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final t = txs[index];
              return ListTile(
                title: Text(t['type'] ?? ''),
                subtitle: Text(t['description'] ?? ''),
                trailing: Text('${t['amount']}'),
              );
            },
          );
        },
      ),
    );
  }
}
