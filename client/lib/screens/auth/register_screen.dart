import 'package:flutter/material.dart';
import '../../services/apiService.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController dobController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: userController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dobController,
              decoration:
                  const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),

            if (_successMessage != null)
              Text(
                _successMessage!,
                style: const TextStyle(color: Colors.green),
              ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _register,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _register() async {
    final username = userController.text.trim();
    final password = passController.text.trim();
    final dob = dobController.text.trim();

    if (username.isEmpty || password.isEmpty || dob.isEmpty) {
      setState(() => _errorMessage = 'Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await ApiService.register(
        username: username,
        password: password,
        dob: dob,
      );

      setState(() {
        if (result.ok) {
          _successMessage = result.message;
        } else {
          _errorMessage = result.message;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

}