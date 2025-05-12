import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.sendPasswordResetEmail(_emailController.text.trim());

        if (mounted) {
          setState(() {
            _emailSent = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),

          const Text(
            'Forgot your password?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 30),

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              // Basic email validation
              if (!value.contains('@') || !value.contains('.')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 30),

          // Reset Password Button
          CustomButton(
            text: 'Send Reset Link',
            onPressed: _handleResetPassword,
            isLoading: _isLoading,
          ),

          const SizedBox(height: 20),

          // Back to Login Button
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: Colors.green,
          size: 80,
        ),

        const SizedBox(height: 20),

        const Text(
          'Email Sent!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'We\'ve sent a password reset link to ${_emailController.text}. Please check your inbox.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 40),

        // Back to Login Button
        CustomButton(
          text: 'Back to Login',
          onPressed: () => Navigator.pop(context),
          isLoading: false,
        ),
      ],
    );
  }
}