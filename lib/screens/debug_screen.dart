import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:oneai/services/database_service.dart';
import 'package:oneai/services/auth_service.dart';
import 'package:oneai/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugInfo = 'Loading...';
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    try {
      final StringBuffer info = StringBuffer();

      // Platform info
      info.writeln('=== PLATFORM INFO ===');
      info.writeln('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}');
      info.writeln('🐛 Debug mode: ${kDebugMode}');
      info.writeln('📱 Release mode: ${kReleaseMode}');

      // Database status
      info.writeln('\n=== DATABASE STATUS ===');
      try {
        // Initialize database (SharedPreferences)
        await _dbService.database;
        info.writeln('✅ Database initialized: SharedPreferences');

        // Check SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final usersList = prefs.getStringList('users_list') ?? [];
        info.writeln('👥 Users in SharedPreferences: ${usersList.length}');
        for (final email in usersList) {
          info.writeln('  - $email');
        }
      } catch (e) {
        info.writeln('❌ Database error: $e');
      }

      info.writeln('\n=== AUTH STATUS ===');
      try {
        final token = await AuthService.getToken();
        final userId = await AuthService.getUserId();
        final isLoggedIn = await AuthService.isLoggedIn();

        info.writeln('🔑 Token exists: ${token != null}');
        info.writeln('🆔 User ID: $userId');
        info.writeln('✅ Is logged in: $isLoggedIn');

        if (userId != null) {
          final user = await AuthService.getUser();
          info.writeln('👤 User found: ${user?.username} (${user?.email})');
        }
      } catch (e) {
        info.writeln('❌ Auth error: $e');
      }

      info.writeln('\n=== PROVIDER STATUS ===');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      info.writeln('🔄 Provider loading: ${authProvider.isLoading}');
      info.writeln('✅ Provider authenticated: ${authProvider.isAuthenticated}');
      info.writeln('👤 Provider user: ${authProvider.user?.username}');
      info.writeln('❌ Provider error: ${authProvider.error}');

      // SharedPreferences debug info
      info.writeln('\n=== SHARED PREFERENCES DEBUG ===');
      try {
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        info.writeln('🔑 Total keys: ${keys.length}');

        final userKeys = keys.where((key) => key.startsWith('user_')).toList();
        info.writeln('👥 User keys: ${userKeys.length}');
        for (final key in userKeys) {
          info.writeln('  - $key');
        }

        final conversationKeys = keys.where((key) => key.startsWith('conversation_')).toList();
        info.writeln('💬 Conversation keys: ${conversationKeys.length}');

        final messageKeys = keys.where((key) => key.startsWith('message_')).toList();
        info.writeln('📝 Message keys: ${messageKeys.length}');

        final authKeys = keys.where((key) => key.contains('auth') || key.contains('token') || key.contains('user_id')).toList();
        info.writeln('🔐 Auth keys: ${authKeys.length}');
        for (final key in authKeys) {
          info.writeln('  - $key');
        }
      } catch (e) {
        info.writeln('❌ SharedPreferences debug error: $e');
      }

      setState(() {
        _debugInfo = info.toString();
      });
    } catch (e) {
      setState(() {
        _debugInfo = 'Error loading debug info: $e';
      });
    }
  }

  Future<void> _testRegistration() async {
    try {
      setState(() {
        _debugInfo = 'Testing registration...';
      });

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final success = await _dbService.registerUser(
          'testuser_$timestamp',
          'test$timestamp@example.com',
          'password123'
      );

      setState(() {
        _debugInfo = 'Registration test result: $success';
      });

      await Future.delayed(const Duration(seconds: 2));
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _debugInfo = 'Registration test error: $e';
      });
    }
  }

  Future<void> _createTestUser() async {
    try {
      setState(() {
        _debugInfo = 'Creating test user...';
      });

      final success = await _dbService.registerUser(
          'testuser',
          'test@example.com',
          'password123'
      );

      if (success) {
        setState(() {
          _debugInfo = 'Test user created successfully!\nEmail: test@example.com\nPassword: password123';
        });
      } else {
        setState(() {
          _debugInfo = 'Failed to create test user (might already exist)';
        });
      }

      await Future.delayed(const Duration(seconds: 2));
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _debugInfo = 'Create test user error: $e';
      });
    }
  }

  Future<void> _clearAllData() async {
    try {
      setState(() {
        _debugInfo = 'Clearing all data...';
      });

      await AuthService.logout();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      setState(() {
        _debugInfo = 'All data cleared!';
      });

      await Future.delayed(const Duration(seconds: 1));
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _debugInfo = 'Error clearing data: $e';
      });
    }
  }

  Future<void> _testLogin() async {
    try {
      setState(() {
        _debugInfo = 'Testing login with test@example.com...';
      });

      final user = await _dbService.loginUser('test@example.com', 'password123');

      if (user != null) {
        setState(() {
          _debugInfo = 'Login test successful!\nUser: ${user.username}\nEmail: ${user.email}';
        });
      } else {
        setState(() {
          _debugInfo = 'Login test failed - user not found or wrong password';
        });
      }

      await Future.delayed(const Duration(seconds: 2));
      await _loadDebugInfo();
    } catch (e) {
      setState(() {
        _debugInfo = 'Login test error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createTestUser,
                    child: const Text('Create Test User'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testLogin,
                    child: const Text('Test Login'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testRegistration,
                    child: const Text('Test Registration'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearAllData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Clear All Data'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _debugInfo,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
