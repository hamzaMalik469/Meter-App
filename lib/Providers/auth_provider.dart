import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null;

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscure = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool? get obscure => _obscure;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  void setObscure() {
    _obscure = !_obscure;
    notifyListeners();
  }

  /// Set loading and notify
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message and notify
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Fetch user data from Firestore
  Future<void> fetchUserData() async {
    if (user == null) return;
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        _userData = doc.data() as Map<String, dynamic>;

        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to load user data');
    }
  }

  /// Sign up and store user info in Firestore
  Future<void> signUp(String email, String password, String name) async {
    _setLoading(true);
    _setError(null);

    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'name': name,
        'createdAt': DateTime.now(),
      });

      await fetchUserData(); // Fetch after signup
      _setLoading(false);
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(e.message ?? 'Signup failed');
      rethrow;
    } catch (e) {
      _setLoading(false);
      _setError('Unexpected error occurred');
      rethrow;
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await fetchUserData(); // Fetch after login
    } on FirebaseAuthException catch (e) {
      _setError(e.message ?? 'Login failed');
      rethrow;
    } catch (e) {
      _setError('Unexpected error occurred');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    await _auth.signOut();
    _userData = null;
    notifyListeners();
  }

  /// Stream to monitor auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
