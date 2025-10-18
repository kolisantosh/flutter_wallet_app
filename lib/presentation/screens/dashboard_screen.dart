import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_wallet_app/presentation/screens/transaction_screen.dart';
import 'package:intl/intl.dart';

import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/wallet/wallet_bloc.dart';
import '../blocs/wallet/wallet_event.dart';
import '../blocs/wallet/wallet_state.dart';
import 'add_money_screen.dart';
import 'send_money_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  void _loadWallet() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<WalletBloc>().add(WalletLoadRequested(userId: authState.user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadWallet();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back,', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(user.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        Text('Wallet Balance', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        BlocConsumer<WalletBloc, WalletState>(
                          listener: (context, state) {
                            if (state is WalletTransactionSuccess) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.green));
                            } else if (state is WalletError) {
                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
                            }
                          },
                          builder: (context, state) {
                            if (state is WalletLoading) {
                              return const CircularProgressIndicator();
                            }

                            if (state is WalletLoaded || state is WalletTransactionSuccess) {
                              final wallet = state is WalletLoaded ? state.wallet : (state as WalletTransactionSuccess).wallet;

                              return Row(
                                children: [
                                  Text(
                                    '₹${NumberFormat('#,##,##0.00').format(wallet.balance)}',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              );
                            }

                            return const Text('--');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.add_circle,
                        title: 'Add Money',
                        color: Colors.green,
                        onTap: () async {
                          final result = await Navigator.of(
                            context,
                          ).push(MaterialPageRoute(builder: (_) => AddMoneyScreen(userId: user.id)));
                          if (result == true) _loadWallet();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.send,
                        title: 'Send Money',
                        color: Colors.blue,
                        onTap: () async {
                          final result = await Navigator.of(
                            context,
                          ).push(MaterialPageRoute(builder: (_) => SendMoneyScreen(userId: user.id)));
                          if (result == true) _loadWallet();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _ActionCard(
                    icon: Icons.history,
                    title: 'Transaction History',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => TransactionHistoryScreen(userId: user.id)));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({Key? key, required this.icon, required this.title, required this.color, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
