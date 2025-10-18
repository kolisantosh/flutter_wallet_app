import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction_model.dart';
import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/transaction/transaction_event.dart';
import '../blocs/transaction/transaction_state.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String userId;

  const TransactionHistoryScreen({super.key, required this.userId});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _searchController = TextEditingController();
  TransactionType? _filterType;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    context.read<TransactionBloc>().add(TransactionSummaryRequested(userId: widget.userId));
  }

  void _searchTransactions(String query) {
    context.read<TransactionBloc>().add(TransactionSearchRequested(userId: widget.userId, searchQuery: query, filterType: _filterType));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon:
                        _searchController.text.isNotEmpty
                            ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _loadTransactions();
                              },
                            )
                            : null,
                  ),
                  onChanged: _searchTransactions,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Filter: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filterType == null,
                      onSelected: (selected) {
                        setState(() {
                          _filterType = null;
                        });
                        _searchTransactions(_searchController.text);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Credit'),
                      selected: _filterType == TransactionType.credit,
                      onSelected: (selected) {
                        setState(() {
                          _filterType = TransactionType.credit;
                        });
                        _searchTransactions(_searchController.text);
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Debit'),
                      selected: _filterType == TransactionType.debit,
                      onSelected: (selected) {
                        setState(() {
                          _filterType = TransactionType.debit;
                        });
                        _searchTransactions(_searchController.text);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TransactionError) {
                  return Center(child: Text(state.message));
                }

                if (state is TransactionSummaryLoaded) {
                  return Column(
                    children: [
                      _SummaryCard(summary: state.summary),
                      Expanded(child: _TransactionList(transactions: state.transactions, userId: widget.userId)),
                    ],
                  );
                }

                if (state is TransactionLoaded) {
                  return _TransactionList(transactions: state.transactions, userId: widget.userId);
                }

                return const Center(child: Text('No transactions'));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Map<String, double> summary;

  const _SummaryCard({Key? key, required this.summary}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(label: 'Total Received', amount: summary['totalReceived'] ?? 0, color: Colors.green),
                _SummaryItem(label: 'Total Sent', amount: summary['totalSent'] ?? 0, color: Colors.red),
                _SummaryItem(label: 'Net Balance', amount: summary['netBalance'] ?? 0, color: Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryItem({Key? key, required this.label, required this.amount, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          '₹${NumberFormat('#,##0.00').format(amount)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<TransactionModel> transactions;
  final String userId;

  const _TransactionList({Key? key, required this.transactions, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(child: Text('No transactions found'));
    }

    double runningBalance = 0;
    final transactionsWithBalance =
        transactions.reversed
            .map((t) {
              if (t.toUserId == userId && t.type == TransactionType.credit) {
                runningBalance += t.amount;
              } else if (t.fromUserId == userId && t.type == TransactionType.debit) {
                runningBalance -= t.amount;
              }
              return {'transaction': t, 'balance': runningBalance};
            })
            .toList()
            .reversed
            .toList();

    print(runningBalance);
    print(transactions.length);
    print(transactionsWithBalance.length);

    return ListView.builder(
      itemCount: transactionsWithBalance.length,
      itemBuilder: (context, index) {
        final item = transactionsWithBalance[index];
        final transaction = item['transaction'] as TransactionModel;
        final balance = item['balance'] as double;

        final isCredit = transaction.toUserId == userId && transaction.type == TransactionType.credit;
        final isDebit = transaction.fromUserId == userId && transaction.type == TransactionType.debit;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCredit ? Colors.green : Colors.red,
              child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.white),
            ),
            title: Text(transaction.note.isEmpty ? 'Transaction' : transaction.note, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(DateFormat('MMM dd, yyyy hh:mm a').format(transaction.datetime)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}₹${NumberFormat('#,##0.00').format(transaction.amount)}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? Colors.green : Colors.red, fontSize: 16),
                ),
                Text('Bal: ₹${NumberFormat('#,##0.00').format(balance)}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}
