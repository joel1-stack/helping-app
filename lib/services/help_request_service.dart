import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/help_request_model.dart';

class HelpRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new help request
  Future<bool> createHelpRequest({
    required String title,
    required String description,
    required String requestorId,
    required String category,
    required String urgency,
    required String address,
    required DateTime dateNeeded,
  }) async {
    try {
      final docRef = _firestore.collection('help_requests').doc();

      final helpRequest = HelpRequest(
        id: docRef.id,
        title: title,
        description: description,
        requestorId: requestorId,
        status: 'open',
        category: category,
        urgency: urgency,
        address: address,
        coordinates: {'latitude': 0.0, 'longitude': 0.0},
        dateCreated: DateTime.now(),
        dateNeeded: dateNeeded,
      );

      await docRef.set(helpRequest.toMap());
      return true;
    } catch (e) {
      print('Error creating help request: $e');
      return false;
    }
  }

  // Get all open help requests
  Stream<List<HelpRequest>> getOpenHelpRequests() {
    return _firestore
        .collection('help_requests')
        .where('status', isEqualTo: 'open')
        .orderBy('dateCreated', descending: true)
        .snapshots()
        .map((snapshot) {
      final requests = <HelpRequest>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final request = HelpRequest.fromMap(data);
          requests.add(request);
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
        }
      }
      return requests;
    });
  }

  // Get requests for a specific requestor - TEMPORARY FIX FOR INDEX ISSUE
  Stream<List<HelpRequest>> getMyRequests(String requestorId) {
    return _firestore
        .collection('help_requests')
        .where('requestorId', isEqualTo: requestorId)
    // .orderBy('dateCreated', descending: true) // TEMPORARILY COMMENTED OUT - INDEX BUILDING
        .snapshots()
        .map((snapshot) {
      final requests = <HelpRequest>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final request = HelpRequest.fromMap(data);
          requests.add(request);
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
        }
      }

      // Manual sorting as temporary workaround
      requests.sort((a, b) => b.dateCreated!.compareTo(a.dateCreated!));

      return requests;
    });
  }

  // Get tasks accepted by a volunteer
  Stream<List<HelpRequest>> getMyTasks(String volunteerId) {
    return _firestore
        .collection('help_requests')
        .where('acceptedVolunteerId', isEqualTo: volunteerId)
        .orderBy('dateCreated', descending: true)
        .snapshots()
        .map((snapshot) {
      final requests = <HelpRequest>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final request = HelpRequest.fromMap(data);
          requests.add(request);
        } catch (e) {
          print('Error parsing document ${doc.id}: $e');
        }
      }
      return requests;
    });
  }

  // Accept a help request
  Future<bool> acceptHelpRequest(String requestId, String volunteerId) async {
    try {
      await _firestore.collection('help_requests').doc(requestId).update({
        'status': 'accepted',
        'acceptedVolunteerId': volunteerId,
      });
      return true;
    } catch (e) {
      print('Error accepting help request: $e');
      return false;
    }
  }

  // Mark request as completed
  Future<bool> completeHelpRequest(String requestId) async {
    try {
      await _firestore.collection('help_requests').doc(requestId).update({
        'status': 'completed',
      });
      return true;
    } catch (e) {
      print('Error completing help request: $e');
      return false;
    }
  }

  // Cancel a help request
  Future<bool> cancelHelpRequest(String requestId) async {
    try {
      await _firestore.collection('help_requests').doc(requestId).update({
        'status': 'cancelled',
        'acceptedVolunteerId': null,
      });
      return true;
    } catch (e) {
      print('Error cancelling help request: $e');
      return false;
    }
  }

  // Get help request by ID
  Future<HelpRequest?> getHelpRequestById(String requestId) async {
    try {
      final doc = await _firestore.collection('help_requests').doc(requestId).get();
      if (doc.exists) {
        return HelpRequest.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting help request: $e');
      return null;
    }
  }
}