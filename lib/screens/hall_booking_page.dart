import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exam_hall_model.dart';
import '../models/hall_booking_model.dart';
import '../services/hall_booking_service.dart';
import '../main.dart';

class HallBookingPage extends StatefulWidget {
  const HallBookingPage({super.key});

  @override
  State<HallBookingPage> createState() => _HallBookingPageState();
}

class _HallBookingPageState extends State<HallBookingPage>
    with SingleTickerProviderStateMixin {
  final HallBookingService _hallBookingService = HallBookingService();
  late PageController _pageController;
  
  List<ExamHallModel> availableHalls = [];
  List<HallBookingModel> bookedHalls = [];
  
  DateTime? selectedDate;
  String? selectedTimeSlot;
  
  bool _isLoading = false;
  bool _hasSelectedFilters = false;
  int _currentPage = 0;

  final List<String> timeSlots = [
    '09:00-11:00',
    '11:00-13:00',
    '13:00-15:00',
    '15:00-17:00',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadHalls() async {
    if (selectedDate == null || selectedTimeSlot == null) return;
    
    setState(() => _isLoading = true);

    try {
      final available = await _hallBookingService.getAvailableHalls(
        selectedDate!,
        selectedTimeSlot!,
      );
      final booked = await _hallBookingService.getBookedHalls(
        selectedDate!,
        selectedTimeSlot!,
      );

      if (mounted) {
        setState(() {
          availableHalls = available;
          bookedHalls = booked;
          _hasSelectedFilters = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading halls: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF007AFF),
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      setState(() {
        selectedDate = date;
      });
      _loadHalls();
    }
  }

  void _selectTimeSlot(String timeSlot) {
    setState(() {
      selectedTimeSlot = timeSlot;
    });
    _loadHalls();
  }

  void _switchPage(int page) {
    setState(() => _currentPage = page);
    _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showBookingDialog(ExamHallModel hall) {
    final purposeController = TextEditingController();
    final studentsController = TextEditingController();
    bool isBooking = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setDialogState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
            ),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hall Name - Big and Bold
                  Text(
                    hall.hallNumber,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D1D1F),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Venue
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: Color(0xFF8E8E93)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hall.venue,
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8E8E93),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Date & Time
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Color(0xFF8E8E93)),
                              SizedBox(width: 8),
                              Text(
                                DateFormat('MMM dd').format(selectedDate!),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D1D1F),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Color(0xFFD1D1D6),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Color(0xFF8E8E93)),
                              SizedBox(width: 8),
                              Text(
                                selectedTimeSlot!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D1D1F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Capacity Info
                  Text(
                    'Capacity: ${hall.capacity} students',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8E8E93),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Number of Students Input
                  TextField(
                    controller: studentsController,
                    enabled: !isBooking,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1D1D1F),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Number of Students',
                      labelStyle: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 15,
                      ),
                      hintText: 'Enter count',
                      hintStyle: TextStyle(color: Color(0xFFC7C7CC)),
                      filled: true,
                      fillColor: Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Purpose Input
                  TextField(
                    controller: purposeController,
                    maxLines: 3,
                    enabled: !isBooking,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1D1D1F),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Purpose of Booking',
                      labelStyle: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 15,
                      ),
                      hintText: 'E.g., End Semester Exam',
                      hintStyle: TextStyle(color: Color(0xFFC7C7CC)),
                      filled: true,
                      fillColor: Color(0xFFF2F2F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: isBooking ? null : () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Color(0xFFF2F2F7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isBooking
                              ? null
                              : () async {
                                  // Validation
                                  if (studentsController.text.trim().isEmpty) {
                                    _showErrorSnackbar('Please enter number of students');
                                    return;
                                  }
                                  if (purposeController.text.trim().isEmpty) {
                                    _showErrorSnackbar('Please enter purpose');
                                    return;
                                  }

                                  final studentCount = int.tryParse(studentsController.text.trim());
                                  if (studentCount == null || studentCount <= 0) {
                                    _showErrorSnackbar('Please enter valid student count');
                                    return;
                                  }

                                  // Capacity Check
                                  if (studentCount > hall.capacity) {
                                    _showCapacityError(hall.capacity);
                                    return;
                                  }

                                  setDialogState(() => isBooking = true);

                                  final booking = await _hallBookingService.bookHall(
                                    hallId: hall.id,
                                    examDate: selectedDate!,
                                    timeSlot: selectedTimeSlot!,
                                    purpose: purposeController.text.trim(),
                                  );

                                  if (booking != null) {
                                    Navigator.pop(dialogContext);
                                    _loadHalls();
                                    _showSuccessSnackbar('Hall booked successfully!');
                                  } else {
                                    setDialogState(() => isBooking = false);
                                    _showErrorSnackbar('Failed to book hall');
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Color(0xFF007AFF),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isBooking
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Book Hall',
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
                  SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCapacityError(int capacity) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFFFF3B30).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFFF3B30),
                  size: 30,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Capacity Exceeded',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1D1F),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hall\'s capacity is only $capacity students\nand you are exceeding the limit',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF3B30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Got it',
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
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFFFF3B30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFF34C759),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Hall Booking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1D1D1F),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Compact Filter Section
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Date & Time Row
                Row(
                  children: [
                    // Date Picker
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today, size: 18, color: Color(0xFF007AFF)),
                              SizedBox(width: 8),
                              Text(
                                selectedDate != null
                                    ? DateFormat('MMM dd').format(selectedDate!)
                                    : 'Select Date',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: selectedDate != null ? Color(0xFF1D1D1F) : Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    // Time Slots Dropdown
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFFE5E7EB)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedTimeSlot,
                            hint: Text(
                              'Time Slot',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            isExpanded: true,
                            items: timeSlots.map((slot) {
                              return DropdownMenuItem(
                                value: slot,
                                child: Text(
                                  slot,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1D1D1F),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) _selectTimeSlot(value);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Switcher
          if (_hasSelectedFilters)
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchPage(0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentPage == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _currentPage == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _currentPage == 0 ? Color(0xFF007AFF) : Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _switchPage(1),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentPage == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: _currentPage == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'Booked',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _currentPage == 1 ? Color(0xFF007AFF) : Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Content
          Expanded(
            child: !_hasSelectedFilters
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.meeting_room_outlined,
                            size: 40,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Select date and time slot',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Text(
                          'to view available halls',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  )
                : _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: Color(0xFF007AFF)),
                      )
                    : PageView(
                        controller: _pageController,
                        onPageChanged: (page) => setState(() => _currentPage = page),
                        children: [
                          _buildAvailableList(),
                          _buildBookedList(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableList() {
    if (availableHalls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No halls available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: availableHalls.length,
      itemBuilder: (context, index) {
        final hall = availableHalls[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showBookingDialog(hall),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF007AFF), Color(0xFF0051D5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.meeting_room,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hall.hallNumber,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D1D1F),
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            hall.venue,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Capacity: ${hall.capacity}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookedList() {
    if (bookedHalls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: bookedHalls.length,
      itemBuilder: (context, index) {
        final booking = bookedHalls[index];
        final isOwnBooking = booking.bookedByUserId == supabase.auth.currentUser?.id;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFF34C759).withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
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
                    Expanded(
                      child: Text(
                        booking.hall?.hallNumber ?? 'Unknown Hall',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D1D1F),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF34C759).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'BOOKED',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF34C759),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (isOwnBooking) ...[
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Cancel Booking'),
                              content: Text('Are you sure you want to cancel this booking?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text('No'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('Yes', style: TextStyle(color: Color(0xFFFF3B30))),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _hallBookingService.cancelBooking(booking.id);
                            _loadHalls();
                          }
                        },
                        icon: Icon(Icons.delete_outline, color: Color(0xFFFF3B30)),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  booking.hall?.venue ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.purpose,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1D1F),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Booked by: ${booking.bookedByName}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
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
      },
    );
  }
}
