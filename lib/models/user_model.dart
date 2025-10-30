import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String userRole;
  final String address;
  final Map<String, double> coordinates;
  final DateTime dateJoined;
  final String? profilePictureUrl;
  final String? bio;
  final double? rating;
  final int? totalRatings;
  final int? totalTasksCompleted;
  final List<UserReview>? reviews;
  final Map<String, double>? categoryRatings;
  final bool? isProfilePublic;
  final bool? showContactInfo;
  final bool? showLocation;
  final List<String>? skills;
  final String? availability;
  final int? completedRequests;
  final double? responseRate;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.userRole,
    required this.address,
    required this.coordinates,
    required this.dateJoined,
    this.profilePictureUrl,
    this.bio,
    this.rating,
    this.totalRatings,
    this.totalTasksCompleted,
    this.reviews,
    this.categoryRatings,
    this.isProfilePublic = true,
    this.showContactInfo = true,
    this.showLocation = true,
    this.skills,
    this.availability,
    this.completedRequests,
    this.responseRate,
  });

  /// Convert model to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'userRole': userRole,
      'address': address,
      'coordinates': coordinates,
      'dateJoined': Timestamp.fromDate(dateJoined),
      'profilePictureUrl': profilePictureUrl,
      'bio': bio,
      'rating': rating,
      'totalRatings': totalRatings,
      'totalTasksCompleted': totalTasksCompleted,
      'reviews': reviews?.map((review) => review.toMap()).toList(),
      'categoryRatings': categoryRatings,
      'isProfilePublic': isProfilePublic,
      'showContactInfo': showContactInfo,
      'showLocation': showLocation,
      'skills': skills ?? <String>[],
      'availability': availability,
      'completedRequests': completedRequests,
      'responseRate': responseRate,
    };
  }

  /// Helper - safely parse date field
  static DateTime _parseDateJoined(dynamic dateField) {
    if (dateField is Timestamp) {
      return dateField.toDate();
    } else if (dateField is DateTime) {
      return dateField;
    } else if (dateField is String) {
      try {
        return DateTime.parse(dateField);
      } catch (e) {
        return DateTime.now();
      }
    } else {
      return DateTime.now();
    }
  }

  /// Helper - safely parse coordinates
  static Map<String, double> _parseCoordinates(dynamic coordField) {
    try {
      if (coordField is Map<String, dynamic>) {
        return coordField.map((key, value) {
          if (value is num) {
            return MapEntry(key, value.toDouble());
          } else if (value is String) {
            return MapEntry(key, double.tryParse(value) ?? 0.0);
          } else {
            return MapEntry(key, 0.0);
          }
        });
      } else if (coordField is Map<String, double>) {
        return coordField;
      } else {
        return {'latitude': 0.0, 'longitude': 0.0};
      }
    } catch (e) {
      return {'latitude': 0.0, 'longitude': 0.0};
    }
  }

  /// Helper to parse UserReview list safely
  static List<UserReview>? _parseReviews(dynamic reviewsField) {
    if (reviewsField == null) return null;
    if (reviewsField is List) {
      try {
        return reviewsField.map((item) {
          if (item is Map<String, dynamic>) {
            return UserReview.fromMap(item);
          }
          return UserReview(
            id: '',
            reviewerId: '',
            reviewerName: '',
            reviewerPhotoUrl: '',
            requestId: '',
            requestTitle: '',
            rating: 0.0,
            comment: '',
            createdAt: DateTime.now(),
          );
        }).toList();
      } catch (e) {
        print('Error parsing reviews: $e');
        return null;
      }
    }
    return null;
  }

  /// Helper to parse category ratings safely
  static Map<String, double>? _parseCategoryRatings(dynamic ratingsField) {
    if (ratingsField == null) return null;
    try {
      if (ratingsField is Map<String, dynamic>) {
        return ratingsField.map((key, value) {
          if (value is num) {
            return MapEntry(key, value.toDouble());
          } else if (value is String) {
            return MapEntry(key, double.tryParse(value) ?? 0.0);
          } else {
            return MapEntry(key, 0.0);
          }
        });
      } else if (ratingsField is Map<String, double>) {
        return ratingsField;
      }
    } catch (e) {
      print('Error parsing category ratings: $e');
    }
    return null;
  }

  /// Create model from Firestore map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    try {
      return UserModel(
        uid: map['uid']?.toString() ?? '',
        email: map['email']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? '',
        phoneNumber: map['phoneNumber']?.toString() ?? '',
        userRole: map['userRole']?.toString() ?? 'volunteer',
        address: map['address']?.toString() ?? '',
        coordinates: _parseCoordinates(map['coordinates']),
        dateJoined: _parseDateJoined(map['dateJoined']),
        profilePictureUrl: map['profilePictureUrl']?.toString(),
        bio: map['bio']?.toString(),
        rating: _parseDouble(map['rating']),
        totalRatings: _parseInt(map['totalRatings']),
        totalTasksCompleted: _parseInt(map['totalTasksCompleted']),
        reviews: _parseReviews(map['reviews']),
        categoryRatings: _parseCategoryRatings(map['categoryRatings']),
        isProfilePublic: map['isProfilePublic'] as bool? ?? true,
        showContactInfo: map['showContactInfo'] as bool? ?? true,
        showLocation: map['showLocation'] as bool? ?? true,
        skills: map['skills'] != null
            ? List<String>.from(map['skills'])
            : <String>[],
        availability: map['availability']?.toString(),
        completedRequests: _parseInt(map['completedRequests']),
        responseRate: _parseDouble(map['responseRate']),
      );
    } catch (e) {
      print('Error parsing UserModel: $e');
      // Return a default user model with basic info
      return UserModel(
        uid: map['uid']?.toString() ?? 'unknown',
        email: map['email']?.toString() ?? '',
        fullName: map['fullName']?.toString() ?? 'Unknown User',
        phoneNumber: map['phoneNumber']?.toString() ?? '',
        userRole: map['userRole']?.toString() ?? 'volunteer',
        address: map['address']?.toString() ?? '',
        coordinates: {'latitude': 0.0, 'longitude': 0.0},
        dateJoined: DateTime.now(),
      );
    }
  }

  /// Helper to parse double safely
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper to parse int safely
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Create updated copy
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? userRole,
    String? address,
    Map<String, double>? coordinates,
    DateTime? dateJoined,
    String? profilePictureUrl,
    String? bio,
    double? rating,
    int? totalRatings,
    int? totalTasksCompleted,
    List<UserReview>? reviews,
    Map<String, double>? categoryRatings,
    bool? isProfilePublic,
    bool? showContactInfo,
    bool? showLocation,
    List<String>? skills,
    String? availability,
    int? completedRequests,
    double? responseRate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userRole: userRole ?? this.userRole,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      dateJoined: dateJoined ?? this.dateJoined,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      reviews: reviews ?? this.reviews,
      categoryRatings: categoryRatings ?? this.categoryRatings,
      isProfilePublic: isProfilePublic ?? this.isProfilePublic,
      showContactInfo: showContactInfo ?? this.showContactInfo,
      showLocation: showLocation ?? this.showLocation,
      skills: skills ?? this.skills,
      availability: availability ?? this.availability,
      completedRequests: completedRequests ?? this.completedRequests,
      responseRate: responseRate ?? this.responseRate,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, fullName: $fullName, email: $email, role: $userRole, rating: $rating, totalRatings: $totalRatings)';
  }

  /// Check if user profile is complete for trust building
  bool get isProfileComplete {
    return fullName.isNotEmpty &&
        phoneNumber.isNotEmpty &&
        address.isNotEmpty &&
        (bio?.isNotEmpty ?? false);
  }

  /// Get trust score based on profile completeness and activity
  double get trustScore {
    double score = 0.0;

    // Basic info (40%)
    if (fullName.isNotEmpty) score += 0.2;
    if (phoneNumber.isNotEmpty) score += 0.1;
    if (address.isNotEmpty) score += 0.1;

    // Profile completeness (30%)
    if (profilePictureUrl != null) score += 0.15;
    if (bio?.isNotEmpty ?? false) score += 0.15;

    // Activity & Ratings (30%)
    if (totalTasksCompleted != null && totalTasksCompleted! > 0) score += 0.1;
    if (rating != null && rating! > 0) score += 0.1;
    if (totalRatings != null && totalRatings! > 0) score += 0.1;

    return score;
  }

  /// Get display rating with fallback
  double get displayRating {
    return rating ?? 0.0;
  }

  /// Get display total ratings with fallback
  int get displayTotalRatings {
    return totalRatings ?? 0;
  }

  /// Check if user has any reviews
  bool get hasReviews {
    return reviews != null && reviews!.isNotEmpty;
  }
}

class UserReview {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String reviewerPhotoUrl;
  final String requestId;
  final String requestTitle;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? response;

  UserReview({
    required this.id,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewerPhotoUrl,
    required this.requestId,
    required this.requestTitle,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.response,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewerPhotoUrl': reviewerPhotoUrl,
      'requestId': requestId,
      'requestTitle': requestTitle,
      'rating': rating,
      'comment': comment,
      'createdAt': Timestamp.fromDate(createdAt),
      'response': response,
    };
  }

  factory UserReview.fromMap(Map<String, dynamic> map) {
    try {
      return UserReview(
        id: map['id']?.toString() ?? '',
        reviewerId: map['reviewerId']?.toString() ?? '',
        reviewerName: map['reviewerName']?.toString() ?? '',
        reviewerPhotoUrl: map['reviewerPhotoUrl']?.toString() ?? '',
        requestId: map['requestId']?.toString() ?? '',
        requestTitle: map['requestTitle']?.toString() ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        comment: map['comment']?.toString() ?? '',
        createdAt: map['createdAt'] is Timestamp
            ? (map['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        response: map['response']?.toString(),
      );
    } catch (e) {
      print('Error parsing UserReview: $e');
      return UserReview(
        id: '',
        reviewerId: '',
        reviewerName: '',
        reviewerPhotoUrl: '',
        requestId: '',
        requestTitle: '',
        rating: 0.0,
        comment: '',
        createdAt: DateTime.now(),
      );
    }
  }

  UserReview copyWith({
    String? id,
    String? reviewerId,
    String? reviewerName,
    String? reviewerPhotoUrl,
    String? requestId,
    String? requestTitle,
    double? rating,
    String? comment,
    DateTime? createdAt,
    String? response,
  }) {
    return UserReview(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerPhotoUrl: reviewerPhotoUrl ?? this.reviewerPhotoUrl,
      requestId: requestId ?? this.requestId,
      requestTitle: requestTitle ?? this.requestTitle,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      response: response ?? this.response,
    );
  }

  @override
  String toString() {
    return 'UserReview(id: $id, reviewer: $reviewerName, rating: $rating, comment: $comment)';
  }
}