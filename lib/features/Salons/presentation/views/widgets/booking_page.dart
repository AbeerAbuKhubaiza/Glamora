import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/constants.dart';
import 'package:glamora_project/models.dart';
import 'package:intl/intl.dart';

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

  // ================== جلب خدمات الصالون من Realtime DB ==================
  Future<void> _loadServicesFromAPI() async {
    setState(() {
      _loading = true;
      _errorLoading = null;
      _services = [];
      _selectedService = null;
    });

    try {
      // 1- جلب جميع salon_services
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

      // نجمع فقط الخدمات الخاصة بالصالون الحالي
      final List<Map<String, dynamic>> tempServices = [];

      for (var entry in allSalonServices.entries) {
        final ss = Map<String, dynamic>.from(entry.value);
        if (ss['salonId'] == widget.salon.id) {
          // جلب بيانات الخدمة نفسها
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

  Future<void> _pickDate() async {
    if (_currentUser == null) return;
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    if (_currentUser == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null) setState(() => _selectedTime = time);
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
    return DateFormat.yMMMEd().add_jm().format(dt.toLocal());
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
        'datetime': dt.toIso8601String(),
        'status': 'pending',
        'paymentStatus': 'unpaid',
        'note': _noteController.text.trim(),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      await bookingsRef.set(bookingData);

      final salonBookingsRef = FirebaseDatabase.instance.ref(
        'salon_bookings/${widget.salon.id}/$bookingId',
      );
      await salonBookingsRef.set(bookingData);

      final userBookingsRef = FirebaseDatabase.instance.ref(
        'user_bookings/${_currentUser!.uid}/$bookingId',
      );
      await userBookingsRef.set(bookingData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
          content: const Text('Booking created successfully'),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
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
      appBar: AppBar(
        title: Text('Book - ${salon.name}'),
        backgroundColor: kPrimaryColor,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: _errorLoading != null
                  ? Center(child: Text(_errorLoading!))
                  : Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Service:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<Map<String, dynamic>>(
                                value: _selectedService,
                                isExpanded: true,
                                items: _services.map((s) {
                                  final title = s['title'] ?? 'Service';
                                  final price = s['price'] ?? '';
                                  return DropdownMenuItem<Map<String, dynamic>>(
                                    value: s,
                                    child: Text(
                                      '$title ${price != '' ? "– \$${price.toString()}" : ""}',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedService = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _pickDate,
                                child: Text(
                                  _selectedDate == null
                                      ? 'Pick date'
                                      : DateFormat.yMMMd().format(
                                          _selectedDate!,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _pickTime,
                                child: Text(
                                  _selectedTime == null
                                      ? 'Pick time'
                                      : _selectedTime!.format(context),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Selected: ${_formatDateTimePreview()}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Add note (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: canSubmit ? _submitBooking : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: _submitting
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text('Confirm Booking'),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}
