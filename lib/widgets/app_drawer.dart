import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:oneai/providers/auth_provider.dart';
import 'package:oneai/screens/auth/login_screen.dart';
import 'package:oneai/screens/home_screen.dart';
import 'package:oneai/screens/profile_screen.dart';
import 'package:oneai/screens/settings_screen.dart';
import 'package:oneai/utils/platform_adaptive.dart';
import 'package:oneai/theme/app_theme.dart';
import 'package:oneai/models/user_model.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isApple = PlatformAdaptive.isApplePlatform();
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context, user),
          ListTile(
            leading: Icon(isApple ? CupertinoIcons.house : Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              }
            },
          ),
          if (user != null) ...[
            ListTile(
              leading: Icon(isApple ? CupertinoIcons.person : Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ],
          ListTile(
            leading: Icon(isApple ? CupertinoIcons.settings : Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const Divider(),
          if (user != null) ...[
            ListTile(
              leading: Icon(
                isApple ? CupertinoIcons.arrow_right_square : Icons.logout,
                color: Colors.red,
              ),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                    );
                  }
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, UserModel? user) {
    final isApple = PlatformAdaptive.isApplePlatform();

    return DrawerHeader(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.2),
                radius: 30,
                child: user?.avatarUrl != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.network(
                    user!.avatarUrl!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        isApple ? CupertinoIcons.person : Icons.person,
                        size: 30,
                        color: Colors.white,
                      );
                    },
                  ),
                )
                    : Icon(
                  isApple ? CupertinoIcons.person : Icons.person,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.username ?? 'Guest User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'OneAI Chatbot Hub',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
