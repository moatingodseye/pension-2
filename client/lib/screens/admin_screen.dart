import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import 'package:shared/models/user.dart';
import '../widgets/date_input.dart';
import '../widgets/screen_layout.dart';

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
    final passwordController = TextEditingController();
    DateTime? dob = user.dob;
    bool isAdmin = user.isAdmin;
    bool isLocked = user.isLocked;

    String dialogError = '';

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Update User'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  const SizedBox(height: 8),
                  DateInput(
                    value: dob,
                    onChanged: (d) => setState(() => dob = d),
                    label: 'Date of Birth',
                    nullable: false,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password (Optional)',
                    ),
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
                    final password = passwordController.text.trim();

                    if (username.isEmpty || dob == null) {
                      setState(() {
                        dialogError = 'Please fill all required fields';
                      });
                      return;
                    }

                    try {
                      final updated = User(
                        id: user.id,
                        username: username,
                        dob: dob,
                        password: password.isEmpty ? null : password,
                        isAdmin: isAdmin,
                        isLocked: isLocked,
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
          },
        );
      },
    );
  }

  Future<void> _toggleLock(User user) async {
    final provider = Provider.of<AdminProvider>(context, listen: false);
    if (user.isLocked) {
      await provider.unlockUser(user.id!);
    } else {
      await provider.lockUser(user.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);
    final users = provider.get();

    final content = provider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : provider.error != null
        ? Center(
            child: Text(
              provider.error!,
              style: const TextStyle(color: Colors.red),
            ),
          )
        : users.isEmpty
        ? const Center(child: Text('No users found.'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final u = users[i];
              return Card(
                key: ValueKey(u.id),
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      u.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    ),
                  ),
                  title: Text(u.username),
                  subtitle: Text(u.isAdmin ? 'Admin' : 'User'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          u.isLocked ? Icons.lock : Icons.lock_open,
                          color: u.isLocked ? Colors.red : Colors.green,
                        ),
                        tooltip: u.isLocked ? 'Unlock User' : 'Lock User',
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
          );

    return ScreenLayout(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Admin Panel',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          Expanded(child: content),
        ],
      ),
      sidebar: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reload Users'),
              onPressed: () => provider.loadUsers(),
            ),
          ],
        ),
      ),
    );
  }
}
