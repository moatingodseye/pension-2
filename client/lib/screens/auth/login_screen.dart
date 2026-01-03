import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage; // To capture error message from the server

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Username Field
              TextField(
                controller: userController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
                textInputAction: TextInputAction.next, // Move to Password field
              ),
              const SizedBox(height: 12),

              // Password Field
              TextField(
                controller: passController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true,
                textInputAction: TextInputAction.done, // Done action for login
              ),
              const SizedBox(height: 20),

              // Error message display (if any error occurs)
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),

              const SizedBox(height: 20),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null; // Clear previous error
                        });

                        try {
                          // Attempt login
                          await authProvider.login(
                            userController.text.trim(),
                            passController.text.trim(),
                          );
                        } catch (e) {
                          // If there's an error, show the error message
                          setState(() {
                            _errorMessage = e.toString(); // Display the error
                          });
                        } finally {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login'),
              ),

              const SizedBox(height: 16),

              // Register button to navigate to Register screen
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
