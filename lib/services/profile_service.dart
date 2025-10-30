import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/user_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Update user profile with enhanced error handling
  Future<bool> updateProfile(UserModel user) async {
    try {
      // Validate required fields
      if (user.uid.isEmpty) {
        throw Exception('User ID is required');
      }

      final userMap = user.toMap();

      // Remove null values to avoid Firestore errors
      final cleanMap = _removeNullValues(userMap);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update(cleanMap);

      print('Profile updated successfully for user: ${user.uid}');
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      print('Stack trace: ${e.toString()}');
      return false;
    }
  }

  // Remove null values from map to prevent Firestore errors
  Map<String, dynamic> _removeNullValues(Map<String, dynamic> map) {
    final cleanMap = <String, dynamic>{};

    map.forEach((key, value) {
      if (value != null) {
        cleanMap[key] = value;
      }
    });

    return cleanMap;
  }

  // Upload profile picture with compression and error handling
  Future<String?> uploadProfilePicture(File imageFile, String userId) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID is required for profile picture upload');
      }

      // Check file size (max 5MB)
      if (await imageFile.length() > 5 * 1024 * 1024) {
        throw Exception('Image file too large. Maximum size is 5MB.');
      }

      final Reference storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child('$userId.jpg');

      // Upload the file
      final UploadTask uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploaded_by': userId},
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        print('Upload progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100}%');
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      print('Profile picture uploaded successfully for user: $userId');
      return downloadUrl;

    } catch (e) {
      print('Error uploading profile picture: $e');
      print('Stack trace: ${e.toString()}');
      return null;
    }
  }

  // Update profile picture URL in user document
  Future<bool> updateProfilePictureUrl(String userId, String imageUrl) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'profilePictureUrl': imageUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('Profile picture URL updated for user: $userId');
      return true;
    } catch (e) {
      print('Error updating profile picture URL: $e');
      return false;
    }
  }

  // Get user by ID with enhanced error handling
  Future<UserModel?> getUserById(String userId) async {
    try {
      if (userId.isEmpty) {
        return null;
      }

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final userData = doc.data()!;
        return UserModel.fromMap({...userData, 'uid': doc.id});
      } else {
        print('User document not found for ID: $userId');
        return null;
      }
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Update user statistics
  Future<bool> updateUserStats(String userId, Map<String, dynamic> stats) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      final cleanStats = _removeNullValues(stats);

      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        ...cleanStats,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('User stats updated for: $userId');
      return true;
    } catch (e) {
      print('Error updating user stats: $e');
      return false;
    }
  }

  // Get user profile with real-time updates
  Stream<UserModel?> getUserProfileStream(String userId) {
    if (userId.isEmpty) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        try {
          return UserModel.fromMap({...doc.data()!, 'uid': doc.id});
        } catch (e) {
          print('Error parsing user stream: $e');
          return null;
        }
      }
      return null;
    })
        .handleError((error) {
      print('Error in user profile stream: $error');
      return null;
    });
  }

  // Update specific profile fields
  Future<bool> updateProfileFields({
    required String userId,
    required Map<String, dynamic> fields,
  }) async {
    try {
      if (userId.isEmpty) {
        throw Exception('User ID is required');
      }

      final cleanFields = _removeNullValues(fields);

      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        ...cleanFields,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('Profile fields updated for user: $userId');
      return true;
    } catch (e) {
      print('Error updating profile fields: $e');
      return false;
    }
  }

  // Delete user profile (admin function)
  Future<bool> deleteUserProfile(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();

      // Also delete profile picture from storage
      try {
        await _storage
            .ref()
            .child('profile_pictures')
            .child('$userId.jpg')
            .delete();
      } catch (e) {
        print('Note: Could not delete profile picture (might not exist): $e');
      }

      print('User profile deleted: $userId');
      return true;
    } catch (e) {
      print('Error deleting user profile: $e');
      return false;
    }
  }

  // Verify profile completeness
  Future<Map<String, dynamic>> getProfileCompleteness(String userId) async {
    try {
      final user = await getUserById(userId);
      if (user == null) {
        return {'complete': false, 'score': 0.0, 'missingFields': []};
      }

      final missingFields = <String>[];
      double score = user.trustScore;

      if (user.fullName.isEmpty) missingFields.add('Full Name');
      if (user.phoneNumber.isEmpty) missingFields.add('Phone Number');
      if (user.address.isEmpty) missingFields.add('Address');
      if (user.bio?.isEmpty ?? true) missingFields.add('Bio');
      if (user.profilePictureUrl == null) missingFields.add('Profile Picture');

      return {
        'complete': missingFields.isEmpty,
        'score': score,
        'missingFields': missingFields,
        'trustLevel': _getTrustLevel(score),
      };
    } catch (e) {
      print('Error checking profile completeness: $e');
      return {'complete': false, 'score': 0.0, 'missingFields': []};
    }
  }

  String _getTrustLevel(double score) {
    if (score >= 0.8) return 'High Trust';
    if (score >= 0.6) return 'Medium Trust';
    if (score >= 0.4) return 'Basic Trust';
    return 'New Member';
  }
}