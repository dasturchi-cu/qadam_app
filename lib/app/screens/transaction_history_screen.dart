import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _fetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      Future.microtask(() {
        final transactionService =
            Provider.of<TransactionService>(context, listen: false);
        final user = Provider.of<AuthService>(context, listen: false).user;
        if (user != null) {
          transactionService.fetchTransactions(user.uid);
        }
      });
      _fetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionService = Provider.of<TransactionService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tranzaksiya tarixi'),
      ),
      body: transactionService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactionService.error != null
              ? Center(child: Text('Xatolik: ${transactionService.error}'))
              : transactionService.transactions.isEmpty
                  ? const Center(child: Text('Tranzaksiyalar topilmadi.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: transactionService.transactions.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) {
                        final t = transactionService.transactions[i];
                        final double amount = t.amount;
                        final String type = t.type;
                        // TODO: Add description field to TransactionModel in the future
                        final String desc = type;
                        final String date =
                            '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
                        return ListTile(
                          leading: Icon(
                            amount > 0 ? Icons.add_circle : Icons.remove_circle,
                            color: amount > 0 ? Colors.green : Colors.red,
                          ),
                          title: Text('$type — $desc'),
                          subtitle: Text(date),
                          trailing: Text(
                            (amount > 0 ? '+' : '') + '${amount.toInt()} tanga',
                            style: TextStyle(
                              color: amount > 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
