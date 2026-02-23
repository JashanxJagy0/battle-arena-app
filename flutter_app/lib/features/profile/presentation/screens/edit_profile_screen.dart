import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../bloc/profile_bloc.dart';
import '../../domain/entities/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _freefireUidController;
  late TextEditingController _freefireIgnController;

  static const List<String> _presetAvatars = [
    'https://api.dicebear.com/7.x/pixel-art/svg?seed=battle1',
    'https://api.dicebear.com/7.x/pixel-art/svg?seed=arena2',
    'https://api.dicebear.com/7.x/pixel-art/svg?seed=player3',
    'https://api.dicebear.com/7.x/pixel-art/svg?seed=warrior4',
    'https://api.dicebear.com/7.x/pixel-art/svg?seed=ninja5',
    'https://api.dicebear.com/7.x/pixel-art/svg?seed=king6',
  ];

  String? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _freefireUidController = TextEditingController();
    _freefireIgnController = TextEditingController();

    final state = context.read<ProfileBloc>().state;
    UserProfile? profile;
    if (state is ProfileLoaded) profile = state.profile;
    if (state is ProfileUpdated) profile = state.profile;

    if (profile != null) {
      _usernameController.text = profile.username;
      _emailController.text = profile.email;
      _freefireUidController.text = profile.freefireUid ?? '';
      _freefireIgnController.text = profile.freefireIgn ?? '';
      _selectedAvatar = profile.avatarUrl;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _freefireUidController.dispose();
    _freefireIgnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.background,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: AppColors.secondary,
              ),
            );
            Navigator.pop(context);
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar selector
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: ClipOval(
                            child: _selectedAvatar != null
                                ? Image.network(_selectedAvatar!, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 40, color: AppColors.primary))
                                : const Icon(Icons.person, size: 40, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Select Avatar', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 56,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _presetAvatars.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (_, index) {
                              final url = _presetAvatars[index];
                              final isSelected = _selectedAvatar == url;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedAvatar = url),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? AppColors.primary : AppColors.divider,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.network(url, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.primary)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _freefireUidController,
                    decoration: const InputDecoration(
                      labelText: 'Free Fire UID',
                      prefixIcon: Text('🔥', style: TextStyle(fontSize: 18)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _freefireIgnController,
                    decoration: const InputDecoration(
                      labelText: 'Free Fire IGN',
                      prefixIcon: Text('🎮', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: state is ProfileLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                HapticFeedback.mediumImpact();
                                context.read<ProfileBloc>().add(
                                      UpdateProfileEvent(
                                        username: _usernameController.text.trim(),
                                        email: _emailController.text.trim(),
                                        freefireUid: _freefireUidController.text.trim().isEmpty
                                            ? null
                                            : _freefireUidController.text.trim(),
                                        freefireIgn: _freefireIgnController.text.trim().isEmpty
                                            ? null
                                            : _freefireIgnController.text.trim(),
                                        avatarUrl: _selectedAvatar,
                                      ),
                                    );
                              }
                            },
                      child: state is ProfileLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
