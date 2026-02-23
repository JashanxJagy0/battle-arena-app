import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/crypto_rate.dart';
import '../bloc/wallet_bloc.dart';
import '../widgets/crypto_selector.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

const _kWarningColor = Color(0xFFFFC107);

class _WithdrawScreenState extends State<WithdrawScreen> {
  String? _selectedCurrency;
  String? _selectedNetwork;
  final _amountController = TextEditingController();
  final _addressController = TextEditingController();
  bool _submitted = false;
  String? _amountError;

  static const _networks = {
    'BTC': ['Bitcoin'],
    'ETH': ['ERC20'],
    'USDT': ['ERC20', 'TRC20', 'BEP20'],
    'USDC': ['ERC20', 'BEP20'],
    'SOL': ['Solana'],
    'BNB': ['BEP20'],
  };

  static const _defaultRates = [
    CryptoRate(currency: 'BTC', name: 'Bitcoin', usdRate: 65000, change24h: 0),
    CryptoRate(currency: 'ETH', name: 'Ethereum', usdRate: 3500, change24h: 0),
    CryptoRate(currency: 'USDT', name: 'Tether', usdRate: 1.0, change24h: 0),
    CryptoRate(currency: 'SOL', name: 'Solana', usdRate: 180, change24h: 0),
    CryptoRate(currency: 'BNB', name: 'BNB', usdRate: 600, change24h: 0),
    CryptoRate(currency: 'USDC', name: 'USD Coin', usdRate: 1.0, change24h: 0),
  ];

  List<CryptoRate> get _cryptoRates {
    final state = context.read<WalletBloc>().state;
    if (state is WalletLoaded && state.cryptoRates.isNotEmpty) {
      return state.cryptoRates;
    }
    return _defaultRates;
  }

  double get _winningBalance {
    final state = context.read<WalletBloc>().state;
    if (state is WalletLoaded) return state.wallet.winningBalance;
    return 0;
  }

  double get _cryptoAmount {
    final usd = double.tryParse(_amountController.text) ?? 0;
    if (usd == 0 || _selectedCurrency == null) return 0;
    final rate = _cryptoRates.firstWhere(
      (r) => r.currency == _selectedCurrency,
      orElse: () =>
          const CryptoRate(currency: '', name: '', usdRate: 1, change24h: 0),
    );
    return usd / rate.usdRate;
  }

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value ?? '');
    if (amount == null || amount <= 0) return 'Enter a valid amount';
    if (amount < 5) return 'Minimum withdrawal is \$5';
    if (amount > _winningBalance) return 'Insufficient winning balance';
    return null;
  }

  void _showConfirmation() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final fee = amount * 0.01;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm Withdrawal',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            _DetailRow(label: 'Currency', value: _selectedCurrency ?? ''),
            _DetailRow(label: 'Network', value: _selectedNetwork ?? ''),
            _DetailRow(
                label: 'Amount', value: '\$${amount.toStringAsFixed(2)}'),
            _DetailRow(
                label: 'Fee (1%)', value: '\$${fee.toStringAsFixed(2)}'),
            _DetailRow(
              label: 'You Receive',
              value: '\$${(amount - fee).toStringAsFixed(2)}',
              valueColor: AppColors.secondary,
            ),
            _DetailRow(
                label: 'Wallet',
                value: _addressController.text,
                truncate: true),
            const SizedBox(height: 20),
            BlocBuilder<WalletBloc, WalletState>(
              builder: (context, state) => SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: state is WalletLoading
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          HapticFeedback.heavyImpact();
                          context.read<WalletBloc>().add(RequestWithdrawal(
                                currency: _selectedCurrency!,
                                network: _selectedNetwork!,
                                amountUsd: amount,
                                walletAddress: _addressController.text,
                              ));
                        },
                  child: state is WalletLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm Withdrawal',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Withdraw'),
      ),
      body: BlocListener<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is WithdrawalRequested) {
            setState(() => _submitted = true);
          } else if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error),
            );
          }
        },
        child: _submitted ? _buildPending() : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    final networks = _selectedCurrency != null
        ? (_networks[_selectedCurrency] ?? ['Default'])
        : <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.secondaryGradient
                    .map((c) => c.withOpacity(0.12))
                    .toList(),
              ),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.secondary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: AppColors.secondary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Withdrawable Balance',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    Text(
                      '\$${_winningBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Select Cryptocurrency',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          CryptoSelector(
            cryptoRates: _cryptoRates,
            selectedCurrency: _selectedCurrency,
            onSelected: (c) => setState(() {
              _selectedCurrency = c;
              _selectedNetwork = null;
            }),
          ),
          if (networks.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Select Network',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: networks.map((net) {
                final isSelected = _selectedNetwork == net;
                return GestureDetector(
                  onTap: () => setState(() => _selectedNetwork = net),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.15)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(net,
                        style: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary)),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 20),
          Text('Amount (USD)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(color: AppColors.primary),
              hintText: 'Min \$5',
              hintStyle: TextStyle(color: AppColors.textMuted),
              errorText: _amountError,
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2)),
            ),
            onChanged: (v) =>
                setState(() => _amountError = _validateAmount(v)),
          ),
          if (_cryptoAmount > 0 && _selectedCurrency != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '≈ ${_cryptoAmount.toStringAsFixed(8)} $_selectedCurrency',
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          const SizedBox(height: 20),
          Text('Wallet Address',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: _addressController,
            style: const TextStyle(
                color: AppColors.textPrimary, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText:
                  'Enter your $_selectedCurrency wallet address',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.paste_rounded,
                    color: AppColors.primary),
                onPressed: () async {
                  final data =
                      await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    _addressController.text = data!.text!;
                    setState(() {});
                  }
                },
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: (_selectedCurrency != null &&
                      _selectedNetwork != null &&
                      _validateAmount(_amountController.text) == null &&
                      _addressController.text.isNotEmpty)
                  ? _showConfirmation
                  : null,
              child: const Text('Continue',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPending() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kWarningColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _kWarningColor.withOpacity(0.5),
                    width: 2),
              ),
              child: const Icon(Icons.hourglass_empty_rounded,
                  color: _kWarningColor, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Withdrawal Requested',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: _kWarningColor),
            ),
            const SizedBox(height: 12),
            Text(
              'Your withdrawal is being processed. You will be notified once it\'s confirmed.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cardBackground,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to Wallet',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool truncate;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.truncate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              truncate && value.length > 20
                  ? '${value.substring(0, 10)}...${value.substring(value.length - 8)}'
                  : value,
              style: TextStyle(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
