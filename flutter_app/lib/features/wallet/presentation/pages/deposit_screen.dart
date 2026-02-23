import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/crypto_rate.dart';
import '../bloc/wallet_bloc.dart';
import '../widgets/crypto_selector.dart';
import '../widgets/qr_code_widget.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

const _kWarningColor = Color(0xFFFFC107);

class _DepositScreenState extends State<DepositScreen> {
  int _step = 0;
  String? _selectedCurrency;
  String? _selectedNetwork;
  final _amountController = TextEditingController();
  Map<String, dynamic>? _depositData;
  Timer? _pollTimer;
  Timer? _expiryTimer;
  int _expirySeconds = 1800;
  bool _confirmed = false;

  static const _networks = {
    'BTC': ['Bitcoin'],
    'ETH': ['ERC20'],
    'USDT': ['ERC20', 'TRC20', 'BEP20'],
    'USDC': ['ERC20', 'BEP20'],
    'SOL': ['Solana'],
    'BNB': ['BEP20'],
  };

  List<CryptoRate> get _cryptoRates {
    final state = context.read<WalletBloc>().state;
    if (state is WalletLoaded && state.cryptoRates.isNotEmpty) {
      return state.cryptoRates;
    }
    return _defaultRates;
  }

  static const _defaultRates = [
    CryptoRate(currency: 'BTC', name: 'Bitcoin', usdRate: 65000, change24h: 0),
    CryptoRate(currency: 'ETH', name: 'Ethereum', usdRate: 3500, change24h: 0),
    CryptoRate(currency: 'USDT', name: 'Tether', usdRate: 1.0, change24h: 0),
    CryptoRate(currency: 'SOL', name: 'Solana', usdRate: 180, change24h: 0),
    CryptoRate(currency: 'BNB', name: 'BNB', usdRate: 600, change24h: 0),
    CryptoRate(currency: 'USDC', name: 'USD Coin', usdRate: 1.0, change24h: 0),
  ];

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

  @override
  void dispose() {
    _amountController.dispose();
    _pollTimer?.cancel();
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _startPolling(String depositId) {
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      context.read<WalletBloc>().add(CheckDepositStatus(depositId));
    });
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_expirySeconds > 0) {
        setState(() => _expirySeconds--);
      } else {
        _expiryTimer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Deposit'),
        leading: _step > 0 && !_confirmed
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => setState(() => _step--),
              )
            : null,
      ),
      body: BlocListener<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state is DepositCreated) {
            setState(() {
              _depositData = state.depositData;
              _step = 3;
              _expirySeconds = 1800;
            });
            final depositId = state.depositData['id'] as String?;
            if (depositId != null) _startPolling(depositId);
          } else if (state is DepositConfirmed) {
            _pollTimer?.cancel();
            setState(() => _confirmed = true);
          } else if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error),
            );
          }
        },
        child: _confirmed ? _buildSuccess() : _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildSelectCurrency();
      case 1:
        return _buildSelectNetwork();
      case 2:
        return _buildEnterAmount();
      case 3:
        return _buildDepositAddress();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSelectCurrency() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 0, total: 4),
          const SizedBox(height: 20),
          Text('Select Cryptocurrency',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Choose the crypto you want to deposit',
              style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: CryptoSelector(
                cryptoRates: _cryptoRates,
                selectedCurrency: _selectedCurrency,
                onSelected: (c) {
                  setState(() {
                    _selectedCurrency = c;
                    _selectedNetwork = null;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _PrimaryButton(
            text: 'Continue',
            enabled: _selectedCurrency != null,
            onPressed: () => setState(() => _step = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectNetwork() {
    final networks = _networks[_selectedCurrency] ?? ['Default'];
    if (networks.length == 1) {
      _selectedNetwork = networks.first;
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setState(() => _step = 2));
      return const SizedBox();
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 1, total: 4),
          const SizedBox(height: 20),
          Text('Select Network',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Choose the network for your $_selectedCurrency deposit',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: networks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final net = networks[i];
                final isSelected = _selectedNetwork == net;
                return GestureDetector(
                  onTap: () => setState(() => _selectedNetwork = net),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cable_rounded,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMuted),
                        const SizedBox(width: 12),
                        Text(net,
                            style: Theme.of(context).textTheme.bodyLarge),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _PrimaryButton(
            text: 'Continue',
            enabled: _selectedNetwork != null,
            onPressed: () => setState(() => _step = 2),
          ),
        ],
      ),
    );
  }

  Widget _buildEnterAmount() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 2, total: 4),
          const SizedBox(height: 20),
          Text('Enter Amount',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle:
                  const TextStyle(color: AppColors.primary, fontSize: 28),
              hintText: '0.00',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          if (_amountController.text.isNotEmpty && _selectedCurrency != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    '≈ ${_cryptoAmount.toStringAsFixed(8)} $_selectedCurrency',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          const Spacer(),
          BlocBuilder<WalletBloc, WalletState>(
            builder: (context, state) => _PrimaryButton(
              text: state is WalletLoading
                  ? 'Processing...'
                  : 'Generate Address',
              enabled: (double.tryParse(_amountController.text) ?? 0) >= 5 &&
                  state is! WalletLoading,
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.read<WalletBloc>().add(CreateDeposit(
                      currency: _selectedCurrency!,
                      network: _selectedNetwork!,
                      amountUsd: double.parse(_amountController.text),
                    ));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepositAddress() {
    final address = _depositData?['address'] as String? ?? '0x...';
    final minutes = _expirySeconds ~/ 60;
    final seconds = _expirySeconds % 60;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StepIndicator(current: 3, total: 4),
          const SizedBox(height: 20),
          FadeInDown(
              child: Text('Deposit Address',
                  style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: 8),
          Text(
            'Send $_selectedCurrency via $_selectedNetwork to this address',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          QrCodeWidget(
              address: address, currency: _selectedCurrency ?? ''),
          const SizedBox(height: 24),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _kWarningColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _kWarningColor.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_rounded,
                    color: _kWarningColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Expires in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                      color: _kWarningColor,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Waiting for payment confirmation...',
            style: TextStyle(color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          const CircularProgressIndicator(
              color: AppColors.primary, strokeWidth: 2),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.secondary, size: 80),
            const SizedBox(height: 24),
            Text(
              'Deposit Confirmed!',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: AppColors.secondary),
            ),
            const SizedBox(height: 12),
            Text(
              'Your balance has been updated.',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _PrimaryButton(
              text: 'Back to Wallet',
              enabled: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isActive = i <= current;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final bool enabled;
  final VoidCallback onPressed;
  const _PrimaryButton(
      {required this.text,
      required this.enabled,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? AppColors.primaryGradient
                : [AppColors.textMuted, AppColors.textMuted],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                      color: AppColors.primaryGlow,
                      blurRadius: 12,
                      spreadRadius: 1)
                ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16),
          ),
        ),
      ),
    );
  }
}
