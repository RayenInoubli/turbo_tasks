import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _rocketAnimation;
  late Animation<double> _textOpacityAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Setup the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Rocket flies up from bottom
    _rocketAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5), // Start from below the screen
      end: Offset.zero, // End at center
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Text fades in after rocket reaches center
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0), // Starts halfway through animation
    ));

    // Start the animation
    _animationController.forward();

    // Navigate to appropriate screen after animations complete
    Timer(const Duration(seconds: 3), () {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    final User? user = _authService.currentUser;
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Text that fades in
            FadeTransition(
              opacity: _textOpacityAnimation,
              child: const Text(
                'Turbo Task',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Rocket that flies up
            SlideTransition(
              position: _rocketAnimation,
              child: const Icon(
                Icons.rocket_launch,
                size: 80,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}