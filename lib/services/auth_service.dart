import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign up with email and password
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String userRole,
    required String address,
  }) async {
    try {
      print('🚀 Starting sign up process for: $email');

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Firebase Auth user created: ${userCredential.user!.uid}');

      if (userCredential.user != null) {
        UserModel newUser = UserModel(
          uid: userCredential.user!.uid,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          userRole: userRole,
          address: address,
          coordinates: {'latitude': 0.0, 'longitude': 0.0},
          dateJoined: DateTime.now(),
        );

        print('📝 Creating user document in Firestore...');

        // Save user to Firestore
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(newUser.toMap());

        print('✅ Firestore document created successfully');

        // Verify the document was created
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (doc.exists) {
          print('✅ User document verified in Firestore');
          return newUser;
        } else {
          print('❌ ERROR: User document not found in Firestore after creation');
          // Clean up auth user if Firestore failed
          await _auth.currentUser!.delete();
          return null;
        }
      }
      return null;
    } catch (e) {
      print('❌ Sign up error: $e');
      // Clean up auth user if Firestore failed
      if (_auth.currentUser != null) {
        try {
          await _auth.currentUser!.delete();
          print('🗑️ Deleted auth user due to Firestore error');
        } catch (deleteError) {
          print('⚠️ Could not delete auth user: $deleteError');
        }
      }
      return null;
    }
  }

  // Sign in with email and password
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting sign in for: $email');

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Auth successful, fetching user data from Firestore...');

      if (userCredential.user != null) {
        // Get user data from Firestore
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        print('📄 Firestore document exists: ${userDoc.exists}');

        if (userDoc.exists) {
          UserModel user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
          print('🎉 User logged in successfully: ${user.fullName}');
          return user;
        } else {
          print('❌ ERROR: User document not found in Firestore');
          // If Firestore document doesn't exist, sign out to prevent inconsistent state
          await _auth.signOut();
          return null;
        }
      }
      return null;
    } catch (e) {
      print('❌ Sign in error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('👋 User signed out successfully');
    } catch (e) {
      print('❌ Sign out error: $e');
      rethrow; // Re-throw to let the caller handle the error
    }
  }

  // Get current user stream
  Stream<UserModel?> get currentUser {
    return _auth.authStateChanges().asyncMap((User? user) async {
      if (user != null) {
        print('🔄 Auth state changed: User is signed in - ${user.uid}');
        try {
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            print('✅ User document found in Firestore');
            return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
          } else {
            print('❌ ERROR: User document not found for authenticated user');
            return null;
          }
        } catch (e) {
          print('❌ Error fetching user data: $e');
          return null;
        }
      } else {
        print('🔄 Auth state changed: User is signed out');
        return null;
      }
    });
  }

  // Get current user once (for one-time checks)
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        }
      } catch (e) {
        print('❌ Error getting current user: $e');
      }
    }
    return null;
  }

  // Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;
}