import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_login_facebook/flutter_login_facebook.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthBase {
  User get currentUser;
  
  Future<void> signOut();
  Stream<User> authStateChanges();
  Future<User> signInAnonymously();
  Future<User> signInWithGoogle();
  Future<User> signInWIthFacebook();
  Future<User> signInWithEmailAndPassword(String email, String password);
  Future<User> createUserWithEmailAndPassword(String email, String password);
}

class Auth implements AuthBase {
  final _firebaseAuth = FirebaseAuth.instance;

  @override
  Stream<User> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  User get currentUser => _firebaseAuth.currentUser;

  @override
  Future<User> signInAnonymously() async {
    final UserCredential = await _firebaseAuth.signInAnonymously();
    return UserCredential.user;
  }

  @override
  Future<User> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithCredential(
      EmailAuthProvider.credential(
        email: email,
        password: password,
      ),
    );
    return userCredential.user;
  }

  @override
  Future<User> createUserWithEmailAndPassword(String email, String password) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password, 
    );
    return userCredential.user;
  }

  @override
  Future<User> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser != null) {
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken != null) {
        final userCredential = await _firebaseAuth.signInWithCredential(GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        ));
        return userCredential.user;
      } else {
        throw FirebaseAuthException(
          message: 'Missinhg Google ID Token',
          code: 'ERROR_MISSING_GOOGLE_ID_TOKEN',
        );
      }
    } else {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in adorted by user',
      );
    }
  }

  @override
  Future<User> signInWIthFacebook() async {
    final fb = FacebookLogin();
    try {
      final response = await fb.logIn(permissions: [
        FacebookPermission.publicProfile,
        FacebookPermission.email,
      ]);
      switch (response.status) {
        case FacebookLoginStatus.Success:
          final accessToken = response.accessToken;
          final userCredential = await _firebaseAuth.signInWithCredential(
            FacebookAuthProvider.credential(accessToken.token),
          );
          return userCredential.user;
        case FacebookLoginStatus.Cancel:
          throw FirebaseException(
            code: 'ERROR_ABORTED_BY_USER',
            message: 'SIgn in aborted by user',
          );
        case FacebookLoginStatus.Error:
          throw FirebaseException(
            code: 'ERROR_FACEBOOK_LOGIN_FAILED',
            message: response.error.developerMessage,
          );
        default:
          throw UnimplementedError();
      }
    } catch (e, st) {
      print("$e, $st");
    }
  }

  @override
  Future<void> signOut() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }
}