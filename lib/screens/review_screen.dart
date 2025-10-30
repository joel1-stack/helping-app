import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/ratings_service.dart';

class ReviewScreen extends StatefulWidget {
  final String targetUserId;
  final String targetUserName;
  final String requestId;
  final String requestTitle;
  final String category;

  const ReviewScreen({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
    required this.requestId,
    required this.requestTitle,
    required this.category,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _canReview = false;

  @override
  void initState() {
    super.initState();
    _checkReviewEligibility();
  }

  Future<void> _checkReviewEligibility() async {
    final currentUser = Provider.of<UserModel?>(context, listen: false);
    if (currentUser == null) return;

    final ratingsService = Provider.of<RatingsService>(context, listen: false);
    final canReview = await ratingsService.canUserReview(
      currentUser.uid,
      widget.targetUserId,
      widget.requestId,
    );

    setState(() {
      _canReview = canReview;
    });
  }

  Future<void> _submitReview() async {
    if (!_canReview) return;

    setState(() => _isSubmitting = true);

    try {
      final currentUser = Provider.of<UserModel?>(context, listen: false);
      final ratingsService = Provider.of<RatingsService>(context, listen: false);

      if (currentUser == null) return;

      final success = await ratingsService.submitReview(
        targetUserId: widget.targetUserId,
        reviewerId: currentUser.uid,
        reviewerName: currentUser.fullName,
        reviewerPhotoUrl: currentUser.profilePictureUrl ?? '',
        requestId: widget.requestId,
        requestTitle: widget.requestTitle,
        category: widget.category,
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return success
      } else {
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave a Review'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: !_canReview
          ? _buildCannotReview()
          : _buildReviewForm(),
    );
  }

  Widget _buildCannotReview() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Cannot Review',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You can only review users you have completed tasks with.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              child: Text(
                'Go Back',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.people, color: Colors.green[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review for ${widget.targetUserName}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.green[800],
                        ),
                      ),
                      Text(
                        widget.requestTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Rating Section
          Text(
            'How was your experience?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Star Rating
          Center(
            child: Column(
              children: [
                Text(
                  _rating.toStringAsFixed(1),
                  style: GoogleFonts.poppins(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () {
                        setState(() {
                          _rating = (index + 1).toDouble();
                        });
                      },
                      icon: Icon(
                        index < _rating.floor() ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _getRatingText(_rating),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Comment Section
          Text(
            'Share your experience (optional)',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Tell others about your experience working with ${widget.targetUserName}...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),

          const SizedBox(height: 30),

          // Review Guidelines
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Review Guidelines',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Be honest and constructive\n• Focus on the task experience\n• Help build a trustworthy community',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                'Submit Review',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent - Outstanding service!';
    if (rating >= 4.0) return 'Great - Very good experience';
    if (rating >= 3.0) return 'Good - Solid performance';
    if (rating >= 2.0) return 'Fair - Could be better';
    return 'Poor - Needs improvement';
  }
}