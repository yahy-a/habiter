import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send reset email: $e');
    }
  }

  Future<bool> verifyPassword(String password) async {
    final user = _auth.currentUser;
    if (user != null) {
      AuthCredential credential =
          EmailAuthProvider.credential(email: user.email!, password: password);
      try {
        await user.reauthenticateWithCredential(credential);
      } catch (e) {
        return false;
      }
      return true;
    }
    return false;
  }

  Future<bool> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not found");
      }

      bool isVerified = await verifyPassword(currentPassword);
      if (!isVerified) {
        throw Exception("Invalid password");
      }
      await user.updatePassword(newPassword);
    } catch (e) {
      print("Error $e");
      return false;
    }
    return true;
  }

  Future<User?> signupWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } catch (e) {
      print("Error $e");
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } catch (e) {
      print("Error $e");
    }
    return null;
  }
}
