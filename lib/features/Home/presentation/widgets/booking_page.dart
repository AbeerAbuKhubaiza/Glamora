import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:intl/intl.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

class BookingPage extends StatefulWidget {
  final Salon salon;
  const BookingPage({super.key, required this.salon});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool _loading = true;
  bool _submitting = false;
  String? _errorLoading;

  List<Map<String, dynamic>> _services = [];
  Map<String, dynamic>? _selectedService;

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _noteController = TextEditingController();

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser == null) {
      _errorLoading = 'You must be logged in to make a booking.';
      _loading = false;
    } else {
      _loadServicesFromAPI();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadServicesFromAPI() async {
    setState(() {
      _loading = true;
      _errorLoading = null;
      _services = [];
      _selectedService = null;
    });

    try {
      final ssSnap = await FirebaseDatabase.instance
          .ref('salon_services')
          .get();
      if (!ssSnap.exists || ssSnap.value == null) {
        setState(() {
          _loading = false;
          _errorLoading = 'No services found for this salon';
        });
        return;
      }

      final allSalonServices = Map<String, dynamic>.from(ssSnap.value as Map);
      final List<Map<String, dynamic>> tempServices = [];

      for (var entry in allSalonServices.entries) {
        final ss = Map<String, dynamic>.from(entry.value);
        if (ss['salonId'] == widget.salon.id) {
          final serviceSnap = await FirebaseDatabase.instance
              .ref('services/${ss['serviceId']}')
              .get();

          if (serviceSnap.exists && serviceSnap.value != null) {
            final sData = Map<String, dynamic>.from(serviceSnap.value as Map);
            tempServices.add({
              'id': ss['id'] ?? '',
              'serviceId': ss['serviceId'] ?? '',
              'title': sData['title'] ?? 'Service',
              'price': ss['price'] ?? sData['price'] ?? 0,
              'duration': ss['duration'] ?? sData['duration'] ?? 0,
              'extra': sData,
            });
          }
        }
      }

      setState(() {
        _services = tempServices;
        _selectedService = tempServices.isNotEmpty ? tempServices.first : null;
        _loading = false;
        _errorLoading = tempServices.isEmpty
            ? 'No services found for this salon'
            : null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorLoading = 'Failed to load services: $e';
      });
    }
  }

  String _formatDateTimePreview() {
    if (_selectedDate == null || _selectedTime == null)
      return 'Select date & time';
    final dt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    return DateFormat('EEE, MMM d • HH:mm').format(dt.toLocal());
  }

  Future<void> _pickDate() async {
    if (_currentUser == null) return;

    final now = DateTime.now();

    final result = await showCalendarDatePicker2Dialog(
      context: context,
      dialogSize: const Size(340, 420),
      borderRadius: BorderRadius.circular(22),
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
        selectedDayHighlightColor: kPrimaryColor,
        selectedDayTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        dayTextStyle: const TextStyle(fontWeight: FontWeight.w600),
        weekdayLabelTextStyle: TextStyle(
          color: Colors.black.withOpacity(0.6),
          fontWeight: FontWeight.w700,
        ),
        controlsTextStyle: const TextStyle(fontWeight: FontWeight.w800),
        okButtonTextStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
        cancelButtonTextStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          color: Colors.black54,
        ),
      ),
      value: _selectedDate != null ? [_selectedDate] : [now],
    );

    if (!mounted) return;

    if (result != null && result.isNotEmpty && result.first != null) {
      setState(() => _selectedDate = result.first);
    }
  }

  Future<void> _pickTime() async {
    if (_currentUser == null) return;

    final initial = _selectedTime ?? const TimeOfDay(hour: 10, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              dialHandColor: AppColors.primary,
              dialBackgroundColor: Colors.grey.shade100,
              hourMinuteTextColor: AppColors.primary,
              hourMinuteColor: Colors.grey.shade100,
              dayPeriodTextColor: AppColors.primary,
              dayPeriodColor: Colors.grey.shade100,
              entryModeIconColor: AppColors.primary,
              helpTextStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submitBooking() async {
    if (_currentUser == null) return;

    if (_selectedService == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a service')));
      return;
    }
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose date and time')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final dt = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      ).toUtc();

      final bookingsRef = FirebaseDatabase.instance.ref('bookings').push();
      final bookingId = bookingsRef.key ?? '';

      final bookingData = {
        'id': bookingId,
        'userId': _currentUser!.uid,
        'salonId': widget.salon.id,
        'serviceId': _selectedService!['serviceId'] ?? '',
        'salonServiceId': _selectedService!['id'] ?? '',
        'serviceTitle': _selectedService!['title'] ?? '',
        'price': _selectedService!['price'] ?? 0,
        'datetime': dt.toIso8601String(),
        'status': 'pending',
        'paymentStatus': 'unpaid',
        'note': _noteController.text.trim(),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      await bookingsRef.set(bookingData);

      await FirebaseDatabase.instance
          .ref('salon_bookings/${widget.salon.id}/$bookingId')
          .set(bookingData);

      await FirebaseDatabase.instance
          .ref('user_bookings/${_currentUser!.uid}/$bookingId')
          .set(bookingData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
          content: const Text('Booking created successfully'),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final salon = widget.salon;

    final canSubmit =
        !_submitting &&
        !_loading &&
        _selectedService != null &&
        _selectedDate != null &&
        _selectedTime != null &&
        _currentUser != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              )
            : _errorLoading != null
            ? Center(child: Text(_errorLoading!))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Book appointment",
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                salon.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle("Choose a service"),
                          const SizedBox(height: 10),

                          ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _services.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              final s = _services[i];
                              final isSelected =
                                  _selectedService?['serviceId'] ==
                                  s['serviceId'];
                              final title = (s['title'] ?? 'Service')
                                  .toString();
                              final price = (s['price'] ?? 0).toString();
                              final duration = (s['duration'] ?? 0).toString();

                              return InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () =>
                                    setState(() => _selectedService = s),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOut,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Color(0xFFD8B5C6).withOpacity(0.25)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: isSelected
                                          ? kPrimaryColor
                                          : Colors.black.withOpacity(0.12),
                                      width: isSelected ? 1.4 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                        color: Colors.black.withOpacity(0.05),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF2F2F2),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.spa_outlined,
                                          color: kPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14.5,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              duration == '0'
                                                  ? "Duration: —"
                                                  : "Duration: $duration min",
                                              style: TextStyle(
                                                color: Colors.black.withOpacity(
                                                  0.55,
                                                ),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "\$$price",
                                            style: TextStyle(
                                              color: kPrimaryColor,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: isSelected
                                                ? Icon(
                                                    Icons.check_circle,
                                                    color: kPrimaryColor,
                                                    key: const ValueKey(1),
                                                  )
                                                : Icon(
                                                    Icons.circle_outlined,
                                                    color: Colors.black
                                                        .withOpacity(0.25),
                                                    key: const ValueKey(2),
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 18),
                          _sectionTitle("Pick date & time"),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: _choiceButton(
                                  icon: Icons.calendar_month_outlined,
                                  title: _selectedDate == null
                                      ? "Pick date"
                                      : DateFormat(
                                          'MMM d, yyyy',
                                        ).format(_selectedDate!),
                                  onTap: _pickDate,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _choiceButton(
                                  icon: Icons.access_time,
                                  title: _selectedTime == null
                                      ? "Pick time"
                                      : _selectedTime!.format(context),
                                  onTap: _pickTime,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.08),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_available,
                                  color: kPrimaryColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _formatDateTimePreview(),
                                    style: TextStyle(
                                      color: Colors.black.withOpacity(0.7),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),
                          _sectionTitle("Note (optional)"),
                          const SizedBox(height: 10),

                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                  color: Colors.black.withOpacity(0.05),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _noteController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Any notes for the salon…',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(14),
                                hintStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.35),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: canSubmit ? _submitBooking : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Confirm Booking',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                      ),
                                    ),
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

  Widget _sectionTitle(String t) {
    return Text(
      t,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
    );
  }

  Widget _choiceButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: kPrimaryColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
