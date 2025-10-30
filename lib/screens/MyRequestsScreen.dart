import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/help_request_service.dart';
import '../models/help_request_model.dart';
import '../models/user_model.dart';

class MyRequestsScreen extends StatefulWidget {
  final UserModel user;

  const MyRequestsScreen({super.key, required this.user});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1559027615-cd4628902d4a?ixlib=rb-4.0.3&auto=format&fit=crop&w=2074&q=80',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black38,
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          children: [
            AppBar(
              title: Text(
                'My Requests',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            Expanded(
              child: StreamBuilder<List<HelpRequest>>(
                stream: Provider.of<HelpRequestService>(context, listen: false)
                    .getMyRequests(widget.user.uid),
                builder: (context, snapshot) {
                  // Handle loading state
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingState();
                  }

                  // Handle errors
                  if (snapshot.hasError) {
                    print('🔥 Stream error: ${snapshot.error}');
                    print('📱 Stack trace: ${snapshot.stackTrace}');
                    return _buildErrorState(
                        'Failed to load requests. Please check your connection.');
                  }

                  // Handle data
                  if (!snapshot.hasData) {
                    return _buildEmptyState();
                  }

                  final requests = snapshot.data!;

                  if (requests.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _buildRequestsList(requests);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading your requests...',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            Text(
              'Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {}); // Retry by rebuilding
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.help_outline,
            size: 80,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 20),
          Text(
            'No requests yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Create your first help request\nand make a difference!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            ),
            child: Text(
              'Create Request',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList(List<HelpRequest> requests) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(HelpRequest request) {
    // Safe status handling
    Color statusColor = Colors.orange;
    String statusText = 'Open';
    String statusEmoji = '⏳';

    final status = request.status?.toLowerCase() ?? 'open';
    switch (status) {
      case 'accepted':
        statusColor = Colors.blue;
        statusText = 'Accepted';
        statusEmoji = '✅';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Completed';
        statusEmoji = '🎉';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Cancelled';
        statusEmoji = '❌';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Open';
        statusEmoji = '⏳';
    }

    // Safe date handling
    String neededByDate = 'Not set';
    String postedDate = 'Unknown';

    try {
      if (request.dateNeeded != null) {
        neededByDate = '${request.dateNeeded!.day}/${request.dateNeeded!.month}/${request.dateNeeded!.year}';
      }
    } catch (e) {
      print('⚠️ Error parsing dateNeeded: $e');
      neededByDate = 'Date error';
    }

    try {
      if (request.dateCreated != null) {
        postedDate = '${request.dateCreated!.day}/${request.dateCreated!.month}/${request.dateCreated!.year}';
      }
    } catch (e) {
      print('⚠️ Error parsing dateCreated: $e');
      postedDate = 'Date error';
    }

    // Safe category handling
    String category = 'Uncategorized';
    try {
      if (request.category != null && request.category!.isNotEmpty) {
        category = request.category![0].toUpperCase() + request.category!.substring(1);
      }
    } catch (e) {
      print('⚠️ Error parsing category: $e');
    }

    // Safe urgency handling
    final urgency = request.urgency?.toLowerCase() ?? 'medium';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title ?? 'Untitled Request',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request.description ?? 'No description provided',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          statusEmoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Request Details with safe data access
              _buildDetailRow(Icons.category, 'Category', category),

              _buildDetailRow(Icons.location_on, 'Location',
                  request.address ?? 'Location not specified'),

              _buildDetailRow(Icons.calendar_today, 'Needed By', neededByDate),

              _buildDetailRow(Icons.schedule, 'Posted', postedDate),

              // Urgency Indicator
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getUrgencyColor(urgency).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getUrgencyColor(urgency).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: _getUrgencyColor(urgency),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${urgency.toUpperCase()} Priority',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getUrgencyColor(urgency),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[800],
                fontWeight: FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}