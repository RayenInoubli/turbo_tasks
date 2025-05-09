import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String userName,
    required String phoneNumber,
    required DateTime birthdate,
  }) async {
    try {
      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user information to Firestore
      if (userCredential.user != null) {
        await _saveUserData(
          uid: userCredential.user!.uid,
          email: email,
          userName: userName,
          phoneNumber: phoneNumber,
          birthdate: birthdate,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Save user data to Firestore
  Future<void> _saveUserData({
    required String uid,
    required String email,
    required String userName,
    required String phoneNumber,
    required DateTime birthdate,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'userName': userName,
      'phoneNumber': phoneNumber,
      'birthdate': Timestamp.fromDate(birthdate),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Update profile
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (_auth.currentUser == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      return doc.data();
    } catch (e) {
      rethrow;
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'No user found with this email.';
        break;
      case 'wrong-password':
        message = 'Wrong password.';
        break;
      case 'email-already-in-use':
        message = 'The email is already in use by another account.';
        break;
      case 'invalid-email':
        message = 'The email address is invalid.';
        break;
      case 'weak-password':
        message = 'The password is too weak.';
        break;
      case 'operation-not-allowed':
        message = 'This operation is not allowed.';
        break;
      default:
        message = 'An error occurred: ${e.message}';
    }

    return Exception(message);
  }

  // Add this to your AuthService class
  Future<void> editProfile({
    required String userName,
    required String phoneNumber,
    required DateTime birthdate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'userName': userName,
        'phoneNumber': phoneNumber,
        'birthdate': Timestamp.fromDate(birthdate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  Future<int> getTasksCountByStatus(TaskStatus status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final querySnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      return querySnapshot.size;
    } catch (e) {
      throw Exception('Failed to get tasks count: ${e.toString()}');
    }
  }
  
  Future<int> getActiveRoutinesCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final querySnapshot = await _firestore
          .collection('routines') // Assuming you have a routines collection
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'routine')
          .where('status', whereIn: ['pending', 'inProgress'])
          .get();

      return querySnapshot.size;
    } catch (e) {
      throw Exception('Failed to get active routines count: ${e.toString()}');
    }
  }
}