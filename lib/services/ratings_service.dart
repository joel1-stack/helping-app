import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class RatingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a review for a user
  Future<bool> submitReview({
    required String targetUserId,
    required String reviewerId,
    required String reviewerName,
    required String reviewerPhotoUrl,
    required String requestId,
    required String requestTitle,
    required String category,
    required double rating,
    required String comment,
  }) async {
    try {
      final reviewId = _firestore.collection('reviews').doc().id;

      final review = UserReview(
        id: reviewId,
        reviewerId: reviewerId,
        reviewerName: reviewerName,
        reviewerPhotoUrl: reviewerPhotoUrl,
        requestId: requestId,
        requestTitle: requestTitle,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      // Add review to reviews collection
      await _firestore.collection('reviews').doc(reviewId).set(review.toMap());

      // Update user's overall rating
      await _updateUserRating(targetUserId, rating, category);

      // Add review to user's reviews subcollection
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .collection('user_reviews')
          .doc(reviewId)
          .set(review.toMap());

      return true;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    }
  }

  // Update user's overall rating and category ratings
  Future<void> _updateUserRating(String userId, double newRating, String category) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) return;

      final currentRating = (userData['rating'] as num?)?.toDouble() ?? 0.0;
      final totalRatings = (userData['totalRatings'] as num?)?.toInt() ?? 0;
      final currentCategoryRatings = Map<String, double>.from(userData['categoryRatings'] ?? {});

      // Calculate new overall rating
      final newOverallRating = ((currentRating * totalRatings) + newRating) / (totalRatings + 1);

      // Update category rating
      final currentCategoryRating = currentCategoryRatings[category] ?? 0.0;
      final categoryTotalRatings = (userData['${category}_ratings'] as num?)?.toInt() ?? 0;
      final newCategoryRating = ((currentCategoryRating * categoryTotalRatings) + newRating) / (categoryTotalRatings + 1);

      currentCategoryRatings[category] = newCategoryRating;

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'rating': newOverallRating,
        'totalRatings': totalRatings + 1,
        'categoryRatings': currentCategoryRatings,
        '${category}_ratings': categoryTotalRatings + 1,
      });

    } catch (e) {
      print('Error updating user rating: $e');
    }
  }

  // Get reviews for a user
  Stream<List<UserReview>> getUserReviews(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('user_reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => UserReview.fromMap(doc.data()))
        .toList());
  }

  // Check if user can review (completed request together)
  Future<bool> canUserReview(String reviewerId, String targetUserId, String requestId) async {
    try {
      final requestDoc = await _firestore.collection('help_requests').doc(requestId).get();

      if (!requestDoc.exists) return false;

      final requestData = requestDoc.data()!;
      final status = requestData['status'] as String;
      final requestorId = requestData['requestorId'] as String;
      final volunteerId = requestData['acceptedVolunteerId'] as String;

      // Check if request is completed and users were involved
      if (status != 'completed') return false;

      // Check if reviewer was involved in the request
      final wasInvolved = (reviewerId == requestorId && targetUserId == volunteerId) ||
          (reviewerId == volunteerId && targetUserId == requestorId);

      // Check if review already exists
      if (wasInvolved) {
        final existingReview = await _firestore
            .collection('reviews')
            .where('reviewerId', isEqualTo: reviewerId)
            .where('requestId', isEqualTo: requestId)
            .get();

        return existingReview.docs.isEmpty;
      }

      return false;
    } catch (e) {
      print('Error checking review eligibility: $e');
      return false;
    }
  }

  // Get user's average rating by category
  Future<Map<String, double>> getUserCategoryRatings(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      return Map<String, double>.from(userData?['categoryRatings'] ?? {});
    } catch (e) {
      print('Error getting category ratings: $e');
      return {};
    }
  }

  // Add response to a review
  Future<bool> addReviewResponse(String reviewId, String response) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'response': response,
      });

      // Also update in user's subcollection
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      final reviewData = reviewDoc.data();
      final targetUserId = reviewData?['reviewerId']; // Actually the reviewed user's ID

      if (targetUserId != null) {
        await _firestore
            .collection('users')
            .doc(targetUserId)
            .collection('user_reviews')
            .doc(reviewId)
            .update({
          'response': response,
        });
      }

      return true;
    } catch (e) {
      print('Error adding review response: $e');
      return false;
    }
  }
}