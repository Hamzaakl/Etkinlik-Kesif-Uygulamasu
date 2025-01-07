import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  // Email/Şifre ile kayıt
  Future<UserCredential?> registerWithEmail(
      String email, String password, String displayName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı adını güncelle
      await userCredential.user?.updateDisplayName(displayName);

      // Kullanıcı bilgilerini yenile
      await userCredential.user?.reload();

      return userCredential;
    } catch (e) {
      print('Kayıt hatası: $e');
      return null;
    }
  }

  // Email/Şifre ile giriş
  Future<UserCredential?> loginWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Giriş hatası: $e');
      return null;
    }
  }

  // Google ile giriş
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Google giriş hatası: $e');
      return null;
    }
  }

  // Facebook ile giriş
  Future<UserCredential?> signInWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final OAuthCredential credential =
            FacebookAuthProvider.credential(result.accessToken!.token);
        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      print('Facebook giriş hatası: $e');
    }
    return null;
  }

  // Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Şifre sıfırlama hatası: $e');
      rethrow;
    }
  }

  // Çıkış yapma
  Future<void> signOut() async {
    try {
      // Önce Firebase'den çıkış yap
      await _auth.signOut();

      // Sonra diğer servislerden çıkış yapmayı dene
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('Google çıkış hatası: $e');
      }

      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        print('Facebook çıkış hatası: $e');
      }
    } catch (e) {
      print('Firebase çıkış hatası: $e');
      throw Exception('Çıkış yapılamadı');
    }
  }
}
