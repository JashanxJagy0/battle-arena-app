import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/crypto_rate.dart';

class CryptoSelector extends StatelessWidget {
  final List<CryptoRate> cryptoRates;
  final String? selectedCurrency;
  final ValueChanged<String> onSelected;

  const CryptoSelector({
    super.key,
    required this.cryptoRates,
    this.selectedCurrency,
    required this.onSelected,
  });

  static const _cryptoIcons = {
    'BTC': '₿',
    'ETH': 'Ξ',
    'USDT': '₮',
    'USDC': '©',
    'SOL': '◎',
    'BNB': 'B',
  };

  static const _cryptoColors = {
    'BTC': Color(0xFFF7931A),
    'ETH': Color(0xFF627EEA),
    'USDT': Color(0xFF26A17B),
    'USDC': Color(0xFF2775CA),
    'SOL': Color(0xFF9945FF),
    'BNB': Color(0xFFF0B90B),
  };

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: cryptoRates.length,
      itemBuilder: (context, index) {
        final rate = cryptoRates[index];
        final isSelected = selectedCurrency == rate.currency;
        final color = _cryptoColors[rate.currency] ?? AppColors.primary;

        return GestureDetector(
          onTap: () => onSelected(rate.currency),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.2) : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _cryptoIcons[rate.currency] ?? rate.currency[0],
                  style: TextStyle(fontSize: 28, color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  rate.currency,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected ? color : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  rate.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
