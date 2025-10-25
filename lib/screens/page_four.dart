import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/grievance_model.dart';
import '../services/grievance_service.dart';
import '../main.dart';

class PageFour extends StatefulWidget {
  const PageFour({super.key});

  @override
  State<PageFour> createState() => _PageFourState();
}

class _PageFourState extends State<PageFour>
    with SingleTickerProviderStateMixin {
  final GrievanceService _grievanceService = GrievanceService();
  
  List<GrievanceModel> allGrievances = [];
  List<GrievanceModel> priorityGrievances = [];
  Map<String, bool> userUpvotes = {};
  
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _grievanceService.subscribeToGrievances((grievances) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final all = await _grievanceService.getAllGrievances();
      final priority = await _grievanceService.getPriorityGrievances();

      Map<String, bool> upvotes = {};
      for (var grievance in all) {
        upvotes[grievance.id] = await _grievanceService.hasUserUpvoted(grievance.id);
      }

      if (mounted) {
        setState(() {
          allGrievances = all;
          priorityGrievances = priority;
          userUpvotes = upvotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading grievances: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleUpvote(GrievanceModel grievance) async {
    final hasUpvoted = userUpvotes[grievance.id] ?? false;

    if (hasUpvoted) {
      final success = await _grievanceService.removeUpvote(grievance.id);
      if (success) {
        setState(() {
          userUpvotes[grievance.id] = false;
        });
        _loadData();
      }
    } else {
      final success = await _grievanceService.upvoteGrievance(grievance.id);
      if (success) {
        setState(() {
          userUpvotes[grievance.id] = true;
        });
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You have already upvoted this grievance'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showAddGrievanceDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddGrievanceDialog(
        onSubmit: (message) async {
          final grievance = await _grievanceService.createGrievance(message);
          if (grievance != null) {
            _loadData();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Grievance posted successfully'),
                  backgroundColor: Color(0xFF6750A4),
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grievances',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1B1F),
                      letterSpacing: -1.0,
                    ),
                  ),
                  IconButton(
                    onPressed: _showAddGrievanceDialog,
                    icon: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF6750A4),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(100),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Color(0xFF4A4A4A),
                  borderRadius: BorderRadius.circular(100),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'All'),
                  Tab(text: 'Priority'),
                ],
              ),
            ),

            SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: Color(0xFF6750A4)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildGrievancesList(allGrievances),
                        _buildGrievancesList(priorityGrievances),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrievancesList(List<GrievanceModel> grievances) {
    if (grievances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.feedback_outlined, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              'No grievances yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: grievances.length,
      itemBuilder: (context, index) {
        return _buildGrievanceCard(grievances[index]);
      },
    );
  }

  Widget _buildGrievanceCard(GrievanceModel grievance) {
    final hasUpvoted = userUpvotes[grievance.id] ?? false;
    final isOwnGrievance = grievance.userId == supabase.auth.currentUser?.id;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF6750A4).withOpacity(0.1),
                  child: Text(
                    grievance.userName.isNotEmpty
                        ? grievance.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: Color(0xFF6750A4),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grievance.userName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1B1F),
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(grievance.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwnGrievance)
                  IconButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Delete Grievance'),
                          content: Text('Are you sure you want to delete this grievance?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _grievanceService.deleteGrievance(grievance.id);
                        _loadData();
                      }
                    },
                    icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey[600]),
                  ),
              ],
            ),

            SizedBox(height: 12),

            Text(
              grievance.message,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF1C1B1F),
              ),
            ),

            SizedBox(height: 16),

            InkWell(
              onTap: () => _handleUpvote(grievance),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasUpvoted
                      ? Color(0xFF6750A4).withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasUpvoted
                        ? Color(0xFF6750A4)
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasUpvoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
                      size: 18,
                      color: hasUpvoted ? Color(0xFF6750A4) : Colors.grey[700],
                    ),
                    SizedBox(width: 6),
                    Text(
                      '${grievance.upvoteCount}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: hasUpvoted ? Color(0xFF6750A4) : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGrievanceDialog extends StatefulWidget {
  final Function(String) onSubmit;

  const _AddGrievanceDialog({required this.onSubmit});

  @override
  State<_AddGrievanceDialog> createState() => _AddGrievanceDialogState();
}

class _AddGrievanceDialogState extends State<_AddGrievanceDialog> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post Grievance',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1B1F),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 5,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Describe your grievance or feedback...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF6750A4), width: 2),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (_controller.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Please enter a message')),
                              );
                              return;
                            }

                            setState(() => _isSubmitting = true);
                            await widget.onSubmit(_controller.text.trim());
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Color(0xFF6750A4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
