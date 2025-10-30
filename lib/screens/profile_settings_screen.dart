import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import '../services/auth_service.dart';
import '../screens/user_reviews_screen.dart'; // Add this import

class ProfileSettingsScreen extends StatefulWidget {
  final UserModel user;

  const ProfileSettingsScreen({super.key, required this.user});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();

  late UserModel _currentUser;
  File? _profileImage;
  bool _isLoading = false;
  bool _isProfilePublic = true;
  bool _showContactInfo = true;
  bool _showLocation = true;
  List<String> _skills = [];
  double _trustScore = 0.0;
  bool _isProfileComplete = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _initializeForm();
    _calculateTrustScore();
  }

  void _initializeForm() {
    _fullNameController.text = _currentUser.fullName;
    _phoneController.text = _currentUser.phoneNumber;
    _addressController.text = _currentUser.address;
    _bioController.text = _currentUser.bio ?? '';
    _availabilityController.text = _currentUser.availability ?? '';
    _isProfilePublic = _currentUser.isProfilePublic ?? true;
    _showContactInfo = _currentUser.showContactInfo ?? true;
    _showLocation = _currentUser.showLocation ?? true;
    _skills = _currentUser.skills ?? [];
  }

  void _calculateTrustScore() {
    setState(() {
      _trustScore = _currentUser.trustScore;
      _isProfileComplete = _currentUser.isProfileComplete;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      await _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_profileImage == null) return;

    setState(() => _isLoading = true);

    try {
      final profileService = Provider.of<ProfileService>(context, listen: false);
      final imageUrl = await profileService.uploadProfilePicture(_profileImage!, _currentUser.uid);

      if (imageUrl != null) {
        await profileService.updateProfilePictureUrl(_currentUser.uid, imageUrl);

        setState(() {
          _currentUser = _currentUser.copyWith(profilePictureUrl: imageUrl);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        _calculateTrustScore();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload picture: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profileService = Provider.of<ProfileService>(context, listen: false);

      final updatedUser = _currentUser.copyWith(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        bio: _bioController.text.trim(),
        skills: _skills,
        availability: _availabilityController.text.trim(),
        isProfilePublic: _isProfilePublic,
        showContactInfo: _showContactInfo,
        showLocation: _showLocation,
      );

      final success = await profileService.updateProfile(updatedUser);

      if (success && mounted) {
        setState(() {
          _currentUser = updatedUser;
        });

        _calculateTrustScore();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Failed to update profile in database');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addSkill() {
    final skill = _skillsController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillsController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green[800]!,
            Colors.green[600]!,
          ],
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.file(_profileImage!, fit: BoxFit.cover)
                      : _currentUser.profilePictureUrl != null
                      ? Image.network(
                    _currentUser.profilePictureUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return _buildDefaultAvatar();
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultAvatar();
                    },
                  )
                      : _buildDefaultAvatar(),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(Icons.camera_alt, size: 20, color: Colors.green[800]),
                  onPressed: _isLoading ? null : _pickImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _currentUser.fullName,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            _currentUser.email,
            style: GoogleFonts.poppins(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentUser.userRole.toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.green[100],
      child: Icon(
        Icons.person,
        size: 50,
        color: Colors.green[800],
      ),
    );
  }

  Widget _buildTrustBadges() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trust & Verification',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _isProfileComplete ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isProfileComplete ? Colors.green : Colors.orange,
                  ),
                ),
                child: Text(
                  _isProfileComplete ? 'Complete' : 'Incomplete',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isProfileComplete ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ADDED RATING DISPLAY SECTION
          if (_currentUser.rating != null && _currentUser.rating! > 0) ...[
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Rating',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_currentUser.rating!.toStringAsFixed(1)}/5.0 • ${_currentUser.totalRatings ?? 0} reviews',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // View Reviews Button
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserReviewsScreen(
                          userId: _currentUser.uid,
                          userName: _currentUser.fullName,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'View Reviews',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Trust Score Progress
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trust Score',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(_trustScore * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _trustScore,
                backgroundColor: Colors.grey[200],
                color: _getTrustScoreColor(_trustScore),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Text(
                _getTrustLevelText(_trustScore),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrustItem('✅', 'Email Verified', 'Your email address is confirmed'),
          _buildTrustItem('📱', 'Phone Verified', 'Your phone number is verified'),
          if (_currentUser.rating != null && _currentUser.rating! > 0)
            _buildTrustItem('⭐', 'Community Rating', '${_currentUser.rating!.toStringAsFixed(1)}/5.0 from ${_currentUser.totalRatings ?? 0} reviews'),
          if (_currentUser.totalTasksCompleted != null && _currentUser.totalTasksCompleted! > 0)
            _buildTrustItem('🎯', 'Tasks Completed', '${_currentUser.totalTasksCompleted} tasks helped'),
          _buildTrustItem('👥', 'Member Since', '${_currentUser.dateJoined.year}'),
        ],
      ),
    );
  }

  Color _getTrustScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.blue;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _getTrustLevelText(double score) {
    if (score >= 0.8) return 'High Trust - Your profile inspires confidence!';
    if (score >= 0.6) return 'Medium Trust - Good profile completeness';
    if (score >= 0.4) return 'Basic Trust - Add more details to build trust';
    return 'New Member - Complete your profile to build trust';
  }

  Widget _buildTrustItem(String emoji, String title, String subtitle) {
    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 20)),
      title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: GoogleFonts.poppins(color: Colors.grey[600])),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildPersonalInfoSection() {
    return _buildSection(
      title: 'Personal Information',
      icon: Icons.person_outline,
      children: [
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _bioController,
          decoration: const InputDecoration(
            labelText: 'Bio (About You)',
            prefixIcon: Icon(Icons.description),
            hintText: 'Tell others about yourself and how you can help...',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildRoleSpecificSection() {
    if (_currentUser.userRole == 'volunteer') {
      return _buildSection(
        title: 'Volunteer Information',
        icon: Icons.volunteer_activism,
        children: [
          TextFormField(
            controller: _availabilityController,
            decoration: const InputDecoration(
              labelText: 'Availability',
              prefixIcon: Icon(Icons.calendar_today),
              hintText: 'e.g., Weekends, Evenings, Flexible',
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skills & Expertise',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                        hintText: 'Add a skill (e.g., Gardening, Driving)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addSkill,
                  ),
                ],
              ),
              if (_skills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      onDeleted: () => _removeSkill(skill),
                      backgroundColor: Colors.green[50],
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ],
      );
    } else {
      return _buildSection(
        title: 'Requestor Information',
        icon: Icons.help_outline,
        children: [
          if (_currentUser.completedRequests != null)
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Completed Requests'),
              subtitle: Text('${_currentUser.completedRequests} requests helped'),
            ),
        ],
      );
    }
  }

  Widget _buildPrivacySection() {
    return _buildSection(
      title: 'Privacy Settings',
      icon: Icons.privacy_tip_outlined,
      children: [
        SwitchListTile(
          title: const Text('Public Profile'),
          subtitle: const Text('Allow others to see your profile'),
          value: _isProfilePublic,
          onChanged: (value) => setState(() => _isProfilePublic = value),
          activeColor: Colors.green,
        ),
        SwitchListTile(
          title: const Text('Show Contact Information'),
          subtitle: const Text('Display your phone number to trusted members'),
          value: _showContactInfo,
          onChanged: (value) => setState(() => _showContactInfo = value),
          activeColor: Colors.green,
        ),
        SwitchListTile(
          title: const Text('Show Location'),
          subtitle: const Text('Share your general location with the community'),
          value: _showLocation,
          onChanged: (value) => setState(() => _showLocation = value),
          activeColor: Colors.green,
        ),
        const SizedBox(height: 16),
        Text(
          'Privacy Note: Your information is protected and only shared with community members you interact with. We never share your data with third parties.',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green[700]),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Stack(
          children: [
            // Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F9B0F),
                    Color(0xFF0A7A0A),
                  ],
                ),
              ),
            ),

            // Content
            Column(
              children: [
                // Custom App Bar
                Container(
                  padding: const EdgeInsets.only(top: 50, bottom: 16, left: 16, right: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green[900]!,
                        Colors.green[800]!,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Profile Settings',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(25),
                        topRight: Radius.circular(25),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Column(
                        children: [
                          _buildProfileHeader(),
                          _buildTrustBadges(),
                          _buildPersonalInfoSection(),
                          _buildRoleSpecificSection(),
                          _buildPrivacySection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Save Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text(
                      'Save Changes',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }
}