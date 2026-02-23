import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../bloc/auth_bloc.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onVerify() {
    if (_otp.length == 6) {
      // In a real app, phone number would come from route state/arguments
      context.read<AuthBloc>().add(
            OTPVerified(phone: '', otp: _otp),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/register'),
        ),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.otpVerification,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.enterOtp,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 48),
                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 48,
                      height: 56,
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                GradientButton(
                  text: AppStrings.verify,
                  onPressed: (_otp.length == 6 && !isLoading) ? _onVerify : null,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      AppStrings.resendOtp,
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
