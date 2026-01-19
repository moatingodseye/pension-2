import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import 'package:shared/models/user.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<AdminProvider>(context, listen: false).loadUsers();
    });
  }

  Future<void> _showUpdateUserDialog(User user) async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    
    final usernameController = TextEditingController(text: user.username);
    final dobController = TextEditingController(text: user.dob?.toIso8601String().split('T')[0] ?? '');
    final passwordController = TextEditingController();
    bool isAdmin = user.isAdmin;
    bool isLocked = user.isLocked;

    String dialogError = '';

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Update User'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: dobController,  // This will pre-fill the DOB
                  decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'New Password (Optional)'),
                  obscureText: true,
                ),
                Row(
                  children: [
                    const Text('Admin'),
                    Switch(
                      value: isAdmin,
                      onChanged: (value) {
                        setState(() {
                          isAdmin = value;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Locked'),
                    Switch(
                      value: isLocked,
                      onChanged: (value) {
                        setState(() {
                          isLocked = value;
                        });
                      },
                    ),
                  ],
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
                  final username = usernameController.text.trim();
                  final dobStr = dobController.text.trim();
                  final password = passwordController.text.trim();

                  if (username.isEmpty || dobStr.isEmpty) {
                    setState(() {
                      dialogError = 'Please fill all required fields';
                    });
                    return;
                  }
                  
                  try {
                      final updated = User(
                          id: user.id,
                          username: username,
                          dob: DateTime.parse(dobStr),
                          password: password.isEmpty ? null : password,
                          isAdmin: isAdmin,
                          isLocked: isLocked
                      );

                      await provider.updateUser(updated);
                      if (context.mounted) Navigator.of(dialogCtx).pop();
                  } catch (e) {
                    setState(() {
                      dialogError = 'Update failed: ${e.toString()}';
                    });
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _toggleLock(User user) async {
     final provider = Provider.of<AdminProvider>(context, listen: false);
/*
     final updated = User(
         id: user.id,
         username: user.username,
         dob: user.dob,
         password: null, // Don't change password
         isAdmin: user.isAdmin,
         isLocked: !user.isLocked
     );
     await provider.updateUser(updated);
*/
     if (user.isLocked)
       await provider.unlockUser(user.id!);
     else
       await provider.lockUser(user.id!);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final users = provider.users;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Admin Panel', style: TextStyle(fontSize: 26)),
          const SizedBox(height: 12),
          if (provider.isLoading) const CircularProgressIndicator(),
          if (provider.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(provider.error!,
                  style: const TextStyle(color: Colors.red)),
            ),
          if (!provider.isLoading && users.isEmpty)
            const Text('No users found.'),
          if (!provider.isLoading && users.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (ctx, i) {
                  final u = users[i];

                  return Card(
                    key: ValueKey(u.id),
                    margin:
                        const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(u.username),
                      subtitle: Text(u.isAdmin ? 'Admin' : 'User'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              u.isLocked
                                  ? Icons.lock
                                  : Icons.lock_open,
                              color: u.isLocked
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            tooltip: u.isLocked
                                ? 'Unlock User'
                                : 'Lock User',
                            onPressed: () => _toggleLock(u),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit User',
                            onPressed: () => _showUpdateUserDialog(u),
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
            onPressed: () => provider.loadUsers(),
            child: const Text('Reload Users'),
          ),
        ],
      ),
    );
  }
}
