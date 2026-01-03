import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      await Provider.of<DataProvider>(context, listen: false).fetchUsers();
    } catch (e) {
      setState(() {
        _error = 'Error loading users: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showResetPasswordDialog(int userId) async {
    final TextEditingController passwordController =
        TextEditingController();
    String dialogError = '';

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Reset Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                  ),
                  obscureText: true,
                ),
                if (dialogError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      dialogError,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newPass = passwordController.text.trim();
                  if (newPass.isEmpty) {
                    setState(() {
                      dialogError = 'Please enter a new password';
                    });
                    return;
                  }
                  try {
                    await Provider.of<DataProvider>(context,
                            listen: false)
                        .resetUserPassword(userId, newPass);
                    Navigator.of(dialogCtx).pop();
                  } catch (e) {
                    setState(() {
                      dialogError = 'Reset failed: ${e.toString()}';
                    });
                  }
                },
                child: const Text('Reset'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _toggleLock(int userId, bool currentlyLocked) async {
    if (currentlyLocked) {
      await Provider.of<DataProvider>(context, listen: false)
          .unlockUser(userId);
    } else {
      await Provider.of<DataProvider>(context, listen: false)
          .lockUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DataProvider>(context);
    final users = provider.users;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Admin Panel', style: TextStyle(fontSize: 26)),
          const SizedBox(height: 12),
          if (_isLoading) const CircularProgressIndicator(),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error,
                  style: const TextStyle(color: Colors.red)),
            ),
          if (!_isLoading && users.isEmpty)
            const Text('No users found.'),
          if (!_isLoading && users.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (ctx, i) {
                  final dynamic u = users[i];

                  final username =
                      (u['username']?.toString() ?? '');
                  final isAdmin =
                      (u['is_admin']?.toString() ?? '0') == '1';
                  final isLocked =
                      (u['locked']?.toString() ?? '0') == '1';

                  return Card(
                    key: ValueKey(u['id'] ?? i),
                    margin:
                        const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(username),
                      subtitle: Text(isAdmin ? 'Admin' : 'User'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isLocked
                                  ? Icons.lock_open
                                  : Icons.lock,
                              color: isLocked
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            tooltip: isLocked
                                ? 'Unlock User'
                                : 'Lock User',
                            onPressed: () =>
                                _toggleLock(u['id'] as int, isLocked),
                          ),
                          IconButton(
                            icon: const Icon(Icons.password),
                            tooltip: 'Reset Password',
                            onPressed: () =>
                                _showResetPasswordDialog(
                                    u['id'] as int),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _loadUsers,
            child: const Text('Reload Users'),
          ),
        ],
      ),
    );
  }
}
