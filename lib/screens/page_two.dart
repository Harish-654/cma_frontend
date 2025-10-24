import 'package:flutter/material.dart';
import '../models/club_model.dart';
import '../services/club_service.dart';
import 'club_detail_page.dart';

class PageTwo extends StatefulWidget {
  const PageTwo({super.key});

  @override
  State<PageTwo> createState() => _PageTwoState();
}

class _PageTwoState extends State<PageTwo> {
  final ClubService _clubService = ClubService();
  
  List<ClubModel> clubs = [];
  List<ClubModel> allAvailableClubs = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      final allClubs = await _clubService.getAllClubs();
      
      if (mounted) {
        setState(() {
          clubs = allClubs.take(6).toList();
          allAvailableClubs = allClubs.skip(6).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading clubs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF6750A4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: Color(0xFF6750A4)),
              ),
              title: Text(
                'Add Clubs',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1B1F),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAddClubsDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFEF5350).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.remove, color: Color(0xFFEF5350)),
              ),
              title: Text(
                'Remove Clubs',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1B1F),
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showRemoveClubsDialog();
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAddClubsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _AddClubsModal(
        availableClubs: allAvailableClubs,
        onClubsSelected: (selectedClubs) {
          setState(() {
            for (var club in selectedClubs) {
              clubs.add(club);
              allAvailableClubs.removeWhere((c) => c.id == club.id);
            }
          });
        },
      ),
    );
  }

  void _showRemoveClubsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _RemoveClubsModal(
        currentClubs: clubs,
        onClubsRemoved: (removedClubIds) {
          setState(() {
            final removedClubs = clubs.where((club) => removedClubIds.contains(club.id)).toList();
            for (var club in removedClubs) {
              allAvailableClubs.add(club);
            }
            clubs.removeWhere((club) => removedClubIds.contains(club.id));
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6750A4)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Clubs',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1B1F),
                        letterSpacing: -1.0,
                      ),
                    ),
                    TextButton(
                      onPressed: _showEditOptions,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6750A4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 105),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildClubCard(clubs[index]);
                  },
                  childCount: clubs.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClubCard(ClubModel club) {
    final color = Color(int.parse(club.colorHex, radix: 16));

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClubDetailPage(club: club),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(16),
        alignment: Alignment.bottomLeft,
        child: Text(
          club.name,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.95),
            letterSpacing: -0.5,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _AddClubsModal extends StatefulWidget {
  final List<ClubModel> availableClubs;
  final Function(List<ClubModel>) onClubsSelected;

  const _AddClubsModal({
    required this.availableClubs,
    required this.onClubsSelected,
  });

  @override
  State<_AddClubsModal> createState() => _AddClubsModalState();
}

class _AddClubsModalState extends State<_AddClubsModal> {
  final Set<String> selectedClubIds = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Clubs',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final selected = widget.availableClubs
                        .where((club) => selectedClubIds.contains(club.id))
                        .toList();
                    widget.onClubsSelected(selected);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6750A4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.availableClubs.isEmpty
                ? Center(
                    child: Text(
                      'All clubs added!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.availableClubs.length,
                    itemBuilder: (context, index) {
                      final club = widget.availableClubs[index];
                      final isSelected = selectedClubIds.contains(club.id);
                      final color = Color(int.parse(club.colorHex, radix: 16));

                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Color(0xFF6750A4)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          title: Text(
                            club.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1C1B1F),
                            ),
                          ),
                          subtitle: Text(
                            club.category,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Color(0xFF6750A4)
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                              color: isSelected
                                  ? Color(0xFF6750A4)
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                selectedClubIds.remove(club.id);
                              } else {
                                selectedClubIds.add(club.id);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RemoveClubsModal extends StatefulWidget {
  final List<ClubModel> currentClubs;
  final Function(Set<String>) onClubsRemoved;

  const _RemoveClubsModal({
    required this.currentClubs,
    required this.onClubsRemoved,
  });

  @override
  State<_RemoveClubsModal> createState() => _RemoveClubsModalState();
}

class _RemoveClubsModalState extends State<_RemoveClubsModal> {
  final Set<String> selectedClubIds = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remove Clubs',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1B1F),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onClubsRemoved(selectedClubIds);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF5350),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.currentClubs.length,
              itemBuilder: (context, index) {
                final club = widget.currentClubs[index];
                final isSelected = selectedClubIds.contains(club.id);
                final color = Color(int.parse(club.colorHex, radix: 16));

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? Color(0xFFEF5350) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    title: Text(
                      club.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1B1F),
                      ),
                    ),
                    subtitle: Text(
                      club.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Color(0xFFEF5350)
                              : Colors.grey[400]!,
                          width: 2,
                        ),
                        color: isSelected
                            ? Color(0xFFEF5350)
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(Icons.remove, size: 16, color: Colors.white)
                          : null,
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedClubIds.remove(club.id);
                        } else {
                          selectedClubIds.add(club.id);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
