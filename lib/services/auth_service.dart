import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service handling Google Sign-In and Firebase Authentication.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  /// Current Firebase user (null if signed out).
  User? get currentUser => _auth.currentUser;

  /// Whether a user is currently signed in.
  bool get isSignedIn => currentUser != null;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Google and return the Firebase User.
  Future<User?> signInWithGoogle() async {
    // Trigger the Google Sign-In flow
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    // Obtain the auth details from the request
    final googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google credential
    final userCredential = await _auth.signInWithCredential(credential);
    return userCredential.user;
  }

  /// Get the Google user's display name.
  String? get displayName => currentUser?.displayName;

  /// Get the Google user's photo URL.
  String? get photoUrl => currentUser?.photoURL;

  /// Get the Google user's email.
  String? get email => currentUser?.email;

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
