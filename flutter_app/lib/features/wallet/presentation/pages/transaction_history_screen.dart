import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/wallet_bloc.dart';
import '../widgets/transaction_tile.dart';
import '../../domain/entities/transaction.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedType = 'all';
  DateTimeRange? _dateRange;

  static const _types = [
    ('all', 'All'),
    ('deposit', 'Deposits'),
    ('withdrawal', 'Withdrawals'),
    ('tournament_entry_fee', 'Game Entries'),
    ('tournament_winning', 'Winnings'),
    ('bonus', 'Bonuses'),
  ];

  void _applyFilter() {
    context.read<WalletBloc>().add(LoadTransactions(
          type: _selectedType == 'all' ? null : _selectedType,
          from: _dateRange?.start,
          to: _dateRange?.end,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded,
                color: AppColors.primary),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                        primary: AppColors.primary),
                  ),
                  child: child!,
                ),
              );
              if (range != null) {
                setState(() => _dateRange = range);
                _applyFilter();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _types.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (value, label) = _types[i];
                final isSelected = _selectedType == value;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedType = value);
                    _applyFilter();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  const Icon(Icons.date_range_rounded,
                      size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('MMM d').format(_dateRange!.start)} – ${DateFormat('MMM d, yyyy').format(_dateRange!.end)}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() => _dateRange = null);
                      _applyFilter();
                    },
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<WalletBloc, WalletState>(
              builder: (context, state) {
                if (state is WalletLoading) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                List<Transaction> transactions = [];
                if (state is WalletLoaded) {
                  transactions = state.transactions;
                }

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text('No transactions found',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return TransactionTile(
                      transaction: tx,
                      onTap: () => _showDetails(context, tx),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, Transaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transaction Details',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            _DetailItem(label: 'ID', value: tx.id),
            _DetailItem(
                label: 'Type',
                value: tx.type.replaceAll('_', ' ').toUpperCase()),
            _DetailItem(
                label: 'Amount',
                value: '\$${tx.amount.toStringAsFixed(2)}'),
            _DetailItem(label: 'Currency', value: tx.currency),
            _DetailItem(
                label: 'Status', value: tx.status.toUpperCase()),
            if (tx.description != null)
              _DetailItem(label: 'Description', value: tx.description!),
            if (tx.referenceId != null)
              _DetailItem(
                  label: 'Reference ID', value: tx.referenceId!),
            _DetailItem(
                label: 'Date',
                value: DateFormat('MMM d, yyyy h:mm a')
                    .format(tx.createdAt.toLocal())),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style:
                    const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
