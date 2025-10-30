import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'BrowseRequestsScreen.dart';
import 'CreateRequestScreen.dart';
import 'MyRequestsScreen.dart';
import 'MyTasksScreen.dart';
import 'profile_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoPlayerController;
  late ChewieController? _chewieController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoggingOut = false;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeAnimations();
  }

  void _initializeVideo() {
    // Using a reliable community-focused video
    _videoPlayerController = VideoPlayerController.network(
      'https://assets.mixkit.co/videos/preview/mixkit-people-helping-each-other-41537-large.mp4',
    );

    _videoPlayerController.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        // Initialize ChewieController AFTER video is initialized
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: true,
          looping: true,
          showControls: false,
          allowMuting: false,
          errorBuilder: (context, errorMessage) {
            return Container(
              color: Colors.green[900],
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 50),
                    SizedBox(height: 10),
                    Text(
                      'Video not available',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        _videoPlayerController.setVolume(0.0); // Mute the video
        _videoPlayerController.play();
      }
    }).catchError((error) {
      print('Video initialization error: $error');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  // ... (Keep all your existing methods: _logout, _showLogoutDialog, _showProfileDialog, etc.)

  @override
  void dispose() {
    _animationController.dispose();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Video Background with Fallback - SIMPLIFIED VERSION
          if (_isVideoInitialized && _chewieController != null)
            SizedBox.expand(
              child: Chewie(controller: _chewieController!),
            )
          else
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.green[800]!,
                    Colors.green[600]!,
                    Colors.green[400]!,
                  ],
                ),
              ),
            ),

          // Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // Content
          SafeArea(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Custom App Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.help_outline,
                                  color: Colors.green[800],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Helping Hands',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[800],
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      'Community Support',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.person, color: Colors.green[700]),
                                onPressed: _showProfileDialog,
                              ),
                              _isLoggingOut
                                  ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                  ),
                                ),
                              )
                                  : IconButton(
                                icon: Icon(Icons.logout, color: Colors.green[700]),
                                onPressed: _showLogoutDialog,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Welcome Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                widget.user.fullName,
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: widget.user.userRole == 'volunteer'
                                      ? Colors.blue.shade50
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: widget.user.userRole == 'volunteer'
                                        ? Colors.blue.shade200
                                        : Colors.orange.shade200,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.user.userRole == 'volunteer'
                                          ? Icons.volunteer_activism
                                          : Icons.help,
                                      color: widget.user.userRole == 'volunteer'
                                          ? Colors.blue.shade800
                                          : Colors.orange.shade800,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.user.userRole == 'volunteer' ? '🌟 Volunteer' : '🙋 Requestor',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: widget.user.userRole == 'volunteer'
                                            ? Colors.blue.shade800
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ready to make a difference in your community!',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Quick Actions
                        Text(
                          'Quick Actions',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Action Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            if (widget.user.userRole == 'requestor')
                              _buildActionCard(
                                icon: Icons.add_circle_outline,
                                title: 'Post Request',
                                subtitle: 'Ask for help',
                                color: Colors.green,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateRequestScreen(user: widget.user),
                                  ),
                                ),
                              ),
                            _buildActionCard(
                              icon: Icons.list_alt,
                              title: widget.user.userRole == 'volunteer' ? 'My Tasks' : 'My Requests',
                              subtitle: widget.user.userRole == 'volunteer' ? 'View assignments' : 'Track requests',
                              color: Colors.blue,
                              onTap: () {
                                if (widget.user.userRole == 'volunteer') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyTasksScreen(user: widget.user),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyRequestsScreen(user: widget.user),
                                    ),
                                  );
                                }
                              },
                            ),
                            _buildActionCard(
                              icon: Icons.search,
                              title: 'Find Help',
                              subtitle: 'Browse nearby',
                              color: Colors.orange,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BrowseRequestsScreen(user: widget.user),
                                ),
                              ),
                            ),
                            _buildActionCard(
                              icon: Icons.chat,
                              title: 'Messages',
                              subtitle: 'Communicate',
                              color: Colors.purple,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Chat Feature - Navigate from Requests/Tasks'),
                                    backgroundColor: Colors.purple,
                                  ),
                                );
                              },
                            ),
                            // Profile Settings Card
                            _buildActionCard(
                              icon: Icons.settings,
                              title: 'Profile Settings',
                              subtitle: 'Manage your account',
                              color: Colors.teal,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProfileSettingsScreen(user: widget.user),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Community Stats
                        Text(
                          'Community Impact',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          children: [
                            _buildStatCard(
                              value: '1.2K+',
                              label: 'Active Volunteers',
                              color: Colors.green,
                              icon: Icons.people,
                            ),
                            _buildStatCard(
                              value: '3.5K+',
                              label: 'Requests Helped',
                              color: Colors.blue,
                              icon: Icons.help,
                            ),
                            _buildStatCard(
                              value: '98%',
                              label: 'Satisfaction Rate',
                              color: Colors.orange,
                              icon: Icons.star,
                            ),
                            _buildStatCard(
                              value: '50+',
                              label: 'Communities',
                              color: Colors.purple,
                              icon: Icons.location_city,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.user.userRole == 'requestor'
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateRequestScreen(user: widget.user),
            ),
          );
        },
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  // ... (Keep your existing _buildActionCard and _buildStatCard methods)

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add your existing methods here (_logout, _showLogoutDialog, _showProfileDialog, etc.)
  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.green[800],
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green, width: 3),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user.fullName,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  Text(
                    widget.user.email,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildProfileInfo('Phone', widget.user.phoneNumber),
                  _buildProfileInfo('Role', widget.user.userRole.toUpperCase()),
                  _buildProfileInfo('Address', widget.user.address),
                  _buildProfileInfo(
                    'Member Since',
                    '${widget.user.dateJoined.day}/${widget.user.dateJoined.month}/${widget.user.dateJoined.year}',
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}