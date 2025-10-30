import 'package:cloud_firestore/cloud_firestore.dart';

class HelpRequest {
  final String id;
  final String title;
  final String description;
  final String requestorId;
  final String status; // 'open', 'accepted', 'completed', 'cancelled'
  final String category;
  final String urgency; // 'low', 'medium', 'high'
  final String address;
  final Map<String, double> coordinates;
  final DateTime dateCreated;
  final DateTime dateNeeded;
  final String? acceptedVolunteerId;
  final List<String>? images;

  HelpRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.requestorId,
    required this.status,
    required this.category,
    required this.urgency,
    required this.address,
    required this.coordinates,
    required this.dateCreated,
    required this.dateNeeded,
    this.acceptedVolunteerId,
    this.images,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requestorId': requestorId,
      'status': status,
      'category': category,
      'urgency': urgency,
      'address': address,
      'coordinates': coordinates,
      'dateCreated': Timestamp.fromDate(dateCreated),
      'dateNeeded': Timestamp.fromDate(dateNeeded),
      'acceptedVolunteerId': acceptedVolunteerId,
      'images': images,
    };
  }

  factory HelpRequest.fromMap(Map<String, dynamic> map) {
    try {
      // Handle date conversion safely
      DateTime parseDate(dynamic dateField) {
        if (dateField is Timestamp) {
          return dateField.toDate();
        } else if (dateField is DateTime) {
          return dateField;
        } else {
          return DateTime.now();
        }
      }

      // Handle coordinates conversion safely
      Map<String, double> parseCoordinates(dynamic coordField) {
        if (coordField is Map<String, dynamic>) {
          return coordField.map((key, value) => MapEntry(key, value.toDouble()));
        } else if (coordField is Map<String, double>) {
          return coordField;
        } else {
          return {'latitude': 0.0, 'longitude': 0.0};
        }
      }

      return HelpRequest(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        requestorId: map['requestorId']?.toString() ?? '',
        status: map['status']?.toString() ?? 'open',
        category: map['category']?.toString() ?? 'other',
        urgency: map['urgency']?.toString() ?? 'medium',
        address: map['address']?.toString() ?? '',
        coordinates: parseCoordinates(map['coordinates']),
        dateCreated: parseDate(map['dateCreated']),
        dateNeeded: parseDate(map['dateNeeded']),
        acceptedVolunteerId: map['acceptedVolunteerId']?.toString(),
        images: map['images'] != null ? List<String>.from(map['images']!) : null,
      );
    } catch (e) {
      print('Error parsing HelpRequest: $e');
      // Return a default help request if parsing fails
      return HelpRequest(
        id: map['id']?.toString() ?? 'error',
        title: 'Error Loading Request',
        description: 'There was an error loading this request.',
        requestorId: '',
        status: 'open',
        category: 'other',
        urgency: 'medium',
        address: '',
        coordinates: {'latitude': 0.0, 'longitude': 0.0},
        dateCreated: DateTime.now(),
        dateNeeded: DateTime.now(),
      );
    }
  }

  HelpRequest copyWith({
    String? status,
    String? acceptedVolunteerId,
  }) {
    return HelpRequest(
      id: id,
      title: title,
      description: description,
      requestorId: requestorId,
      status: status ?? this.status,
      category: category,
      urgency: urgency,
      address: address,
      coordinates: coordinates,
      dateCreated: dateCreated,
      dateNeeded: dateNeeded,
      acceptedVolunteerId: acceptedVolunteerId ?? this.acceptedVolunteerId,
      images: images,
    );
  }

  @override
  String toString() {
    return 'HelpRequest(id: $id, title: $title, status: $status)';
  }
}