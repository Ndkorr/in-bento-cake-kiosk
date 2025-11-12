import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onContinueKiosk;
  final ValueChanged<String> onStaffLogin;

  const LoginScreen({
    super.key,
    required this.onContinueKiosk,
    required this.onStaffLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showStaffLogin = false;
  final TextEditingController _controller = TextEditingController();
  String? _error;

  void _handleStaffLogin() {
    final password = _controller.text.trim();
    if (password == 'staff123') {
      // Replace with your real password logic
      widget.onStaffLogin(password);
    } else {
      setState(() => _error = 'Incorrect password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _showStaffLogin
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Staff Login',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _controller,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          errorText: _error,
                        ),
                        onSubmitted: (_) => _handleStaffLogin(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: _handleStaffLogin,
                            child: const Text('Login'),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () => setState(() {
                              _showStaffLogin = false;
                              _error = null;
                            }),
                            child: const Text('Back'),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Welcome to Inbento Kiosk',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: widget.onContinueKiosk,
                        child: const Text('Continue to Kiosk'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => setState(() => _showStaffLogin = true),
                        child: const Text('Staff Login'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
