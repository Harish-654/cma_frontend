import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PageFour extends StatefulWidget {
  const PageFour({super.key});

  @override
  State<PageFour> createState() => _PageFourState();
}

class _PageFourState extends State<PageFour> with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final PageController _pageController = PageController();
  
  List<Map<String, dynamic>> grievances = [];
  bool isLoading = true;
  bool hasPosted = false;
  String? userGrievanceId;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadGrievances();
    _checkIfUserHasPosted();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkIfUserHasPosted() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('grievances')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          hasPosted = response != null;
          userGrievanceId = response?['id'];
        });
      }
    } catch (e) {
      print('Error checking if user posted: $e');
    }
  }

  Future<void> _loadGrievances() async {
    try {
      setState(() => isLoading = true);

      final response = await _supabase
          .from('grievances')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          grievances = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading grievances: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get sortedByTime {
    List<Map<String, dynamic>> sorted = List.from(grievances);
    sorted.sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
    return sorted;
  }

  List<Map<String, dynamic>> get sortedByUpvotes {
    List<Map<String, dynamic>> sorted = List.from(grievances);
    sorted.sort((a, b) => (b['upvotes'] ?? 0).compareTo(a['upvotes'] ?? 0));
    return sorted;
  }

  Future<void> _toggleUpvote(String grievanceId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final existingVote = await _supabase
          .from('grievance_upvotes')
          .select()
          .eq('grievance_id', grievanceId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingVote != null) {
        await _supabase
            .from('grievance_upvotes')
            .delete()
            .eq('grievance_id', grievanceId)
            .eq('user_id', userId);

        final currentGrievance = await _supabase
            .from('grievances')
            .select('upvotes')
            .eq('id', grievanceId)
            .single();

        await _supabase
            .from('grievances')
            .update({'upvotes': (currentGrievance['upvotes'] ?? 1) - 1})
            .eq('id', grievanceId);
      } else {
        await _supabase.from('grievance_upvotes').insert({
          'grievance_id': grievanceId,
          'user_id': userId,
        });

        final currentGrievance = await _supabase
            .from('grievances')
            .select('upvotes')
            .eq('id', grievanceId)
            .single();

        await _supabase
            .from('grievances')
            .update({'upvotes': (currentGrievance['upvotes'] ?? 0) + 1})
            .eq('id', grievanceId);
      }

      await _loadGrievances();
    } catch (e) {
      print('Error toggling upvote: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating upvote: $e')),
      );
    }
  }

  Future<bool> _hasUserUpvoted(String grievanceId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('grievance_upvotes')
          .select()
          .eq('grievance_id', grievanceId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking upvote: $e');
      return false;
    }
  }

  void _showAddGrievanceDialog() {
    if (hasPosted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only post one grievance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddGrievanceSheet(
        onGrievanceAdded: () {
          _loadGrievances();
          _checkIfUserHasPosted();
        },
      ),
    );
  }

  void _switchToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and add button
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grievances',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  if (!hasPosted)
                    IconButton(
                      onPressed: _showAddGrievanceDialog,
                      icon: Icon(
                        Icons.add_circle,
                        color: Color(0xFF6750A4),
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),

            // Toggle Switch
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    // Animated background slider
                    AnimatedPositioned(
                      duration: Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      left: currentPage == 0 ? 4 : null,
                      right: currentPage == 1 ? 4 : null,
                      top: 4,
                      bottom: 4,
                      width: MediaQuery.of(context).size.width / 2 - 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF424242),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchToPage(0),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                'All',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: currentPage == 0
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchToPage(1),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                'Priority',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: currentPage == 1
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // PageView for swipeable content
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => currentPage = index);
                      },
                      children: [
                        // All (sorted by time)
                        _buildGrievancesList(sortedByTime),
                        // Priority (sorted by upvotes)
                        _buildGrievancesList(sortedByUpvotes),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrievancesList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No grievances yet',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final grievance = list[index];
        return FutureBuilder<bool>(
          future: _hasUserUpvoted(grievance['id']),
          builder: (context, snapshot) {
            final hasUpvoted = snapshot.data ?? false;
            return _GrievanceCard(
              userName: grievance['user_name'] ?? 'Anonymous',
              timestamp: grievance['created_at'],
              message: grievance['message'] ?? '',
              upvotes: grievance['upvotes'] ?? 0,
              hasUpvoted: hasUpvoted,
              onUpvote: () => _toggleUpvote(grievance['id']),
            );
          },
        );
      },
    );
  }
}

class _GrievanceCard extends StatelessWidget {
  final String userName;
  final String timestamp;
  final String message;
  final int upvotes;
  final bool hasUpvoted;
  final VoidCallback onUpvote;

  const _GrievanceCard({
    required this.userName,
    required this.timestamp,
    required this.message,
    required this.upvotes,
    required this.hasUpvoted,
    required this.onUpvote,
  });

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF6750A4).withOpacity(0.2),
                child: Text(
                  userName[0].toUpperCase(),
                  style: TextStyle(
                    color: Color(0xFF6750A4),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF1D1D1F),
              height: 1.5,
            ),
          ),
          SizedBox(height: 12),
          GestureDetector(
            onTap: onUpvote,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: hasUpvoted
                    ? Color(0xFF6750A4).withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasUpvoted ? Color(0xFF6750A4) : Colors.grey,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'I too face the same issue',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: hasUpvoted ? Color(0xFF6750A4) : Color(0xFF6B7280),
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_upward,
                    size: 16,
                    color: hasUpvoted ? Color(0xFF6750A4) : Color(0xFF6B7280),
                  ),
                  SizedBox(width: 4),
                  Text(
                    upvotes.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: hasUpvoted ? Color(0xFF6750A4) : Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddGrievanceSheet extends StatefulWidget {
  final VoidCallback onGrievanceAdded;

  const _AddGrievanceSheet({required this.onGrievanceAdded});

  @override
  State<_AddGrievanceSheet> createState() => _AddGrievanceSheetState();
}

class _AddGrievanceSheetState extends State<_AddGrievanceSheet> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController messageController = TextEditingController();
  bool isProcessing = false;

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> _submitGrievance() async {
    if (messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your grievance'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isProcessing = true);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Not authenticated');
      }

      final existing = await _supabase
          .from('grievances')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('You have already posted a grievance');
      }

      final userData = await _supabase
          .from('users')
          .select('full_name')
          .eq('id', userId)
          .single();

      await _supabase.from('grievances').insert({
        'user_id': userId,
        'user_name': userData['full_name'] ?? 'Anonymous',
        'message': messageController.text.trim(),
        'upvotes': 0,
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onGrievanceAdded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Grievance posted successfully!')),
        );
      }
    } catch (e) {
      print('Error submitting grievance: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post a Grievance',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1D1F),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You can only post one grievance',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: messageController,
              enabled: !isProcessing,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Your Grievance',
                hintText: 'Describe the issue...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Color(0xFFF9FAFB),
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isProcessing ? null : _submitGrievance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6750A4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isProcessing
                    ? CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2)
                    : Text(
                        'Post Grievance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
