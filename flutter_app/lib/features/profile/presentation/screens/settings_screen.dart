import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _twoFactorAuth = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Notifications',
            children: [
              SwitchListTile(
                title: const Text('Push Notifications', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Receive game and bonus alerts', style: TextStyle(color: Colors.white54, fontSize: 12)),
                value: _pushNotifications,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => _pushNotifications = v);
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'Security',
            children: [
              ListTile(
                leading: const Icon(Icons.lock_outline, color: AppColors.primary, size: 20),
                title: const Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 14),
                dense: true,
                onTap: () => _showChangePasswordDialog(context),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.divider),
              SwitchListTile(
                title: const Text('Two-Factor Authentication', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Extra security for your account', style: TextStyle(color: Colors.white54, fontSize: 12)),
                value: _twoFactorAuth,
                onChanged: (v) {
                  HapticFeedback.lightImpact();
                  setState(() => _twoFactorAuth = v);
                },
                activeColor: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'Linked Accounts',
            children: [
              ListTile(
                leading: const Text('🔥', style: TextStyle(fontSize: 18)),
                title: const Text('Free Fire UID', style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: TextButton(
                  onPressed: () => context.push('/profile/edit'),
                  child: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                title: const Text('App Version', style: TextStyle(color: Colors.white, fontSize: 14)),
                trailing: const Text('1.0.0', style: TextStyle(color: Colors.white54, fontSize: 13)),
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => _showDeleteAccountDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Delete Account'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Change Password', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: const Text('Delete Account', style: TextStyle(color: AppColors.error)),
        content: const Text(
          'This action is permanent and cannot be undone. All your data will be deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
