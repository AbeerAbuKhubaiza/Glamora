import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Bookings/data/bookings_repository.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Owner/booking_helpers.dart';

final Map<String, String> _serviceTitleCache = {};

Future<String> getServiceTitle(String serviceId) async {
  if (_serviceTitleCache.containsKey(serviceId)) {
    return _serviceTitleCache[serviceId]!;
  }

  final snap = await FirebaseDatabase.instance.ref('services/$serviceId').get();

  if (!snap.exists || snap.value is! Map) return 'Service';

  final map = Map<String, dynamic>.from(snap.value as Map);
  final title = map['title']?.toString() ?? 'Service';

  _serviceTitleCache[serviceId] = title;
  return title;
}

class OwnerBookingsTab extends StatefulWidget {
  final Salon salon;
  const OwnerBookingsTab({super.key, required this.salon});

  @override
  State<OwnerBookingsTab> createState() => _OwnerBookingsTabState();
}

class _OwnerBookingsTabState extends State<OwnerBookingsTab> {
  final _bookingsRepo = const BookingsRepository();
  // final _usersRepo = const UsersRepository();

  late Future<_BookingsBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  Future<_BookingsBundle> _loadAll() async {
    print("Loading bookings for Salon ID: ${widget.salon.id}");

    final bookings = await _bookingsRepo.fetchSalonBookings(widget.salon.id);
    return _BookingsBundle(bookings: bookings, users: {});
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BookingsBundle>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        }

        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        if (!snap.hasData || snap.data!.bookings.isEmpty) {
          return const Center(
            child: Text(
              'No bookings yet',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          );
        }

        final bookings = snap.data!.bookings;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final booking = bookings[i];

              return FutureBuilder<List<String>>(
                future: Future.wait([
                  getUserName(booking.userId),
                  getServiceTitle(booking.serviceId),
                ]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return BookingLuxuryCard(
                      booking: booking,
                      userName: '...',
                      serviceTitle: '...',
                      onStatusChanged: _updateStatus,
                      onPaymentChanged: _updatePayment,
                    );
                  }

                  final userName = snapshot.data?[0] ?? 'Client';
                  final serviceTitle = snapshot.data?[1] ?? 'Service';

                  return BookingLuxuryCard(
                    booking: booking,
                    userName: userName,
                    serviceTitle: serviceTitle,
                    onStatusChanged: _updateStatus,
                    onPaymentChanged:
                        _updatePayment,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _updateStatus(Booking booking, String status) async {
    await FirebaseDatabase.instance.ref('bookings/${booking.id}').update({
      'status': status,
    });
    _refresh();
  }

  Future<void> _updatePayment(Booking booking, String status) async {
    await FirebaseDatabase.instance.ref('bookings/${booking.id}').update({
      'paymentStatus': status,
    });
    _refresh();
  }
}

class _BookingsBundle {
  final List<Booking> bookings;
  final Map<String, String> users;

  _BookingsBundle({required this.bookings, required this.users});
}

class BookingLuxuryCard extends StatelessWidget {
  final Booking booking;
  final String userName;
  final String serviceTitle;
  final Function(Booking, String) onStatusChanged;
  final Function(Booking, String) onPaymentChanged;

  const BookingLuxuryCard({
    super.key,
    required this.booking,
    required this.userName,
    required this.serviceTitle,
    required this.onStatusChanged,
    required this.onPaymentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: kPrimaryColor.withOpacity(0.1),
                          child: const Icon(
                            Icons.person_outline,
                            size: 20,
                            color: kPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                        ),

                        _buildActionMenu(
                          icon: Icons.event_available,
                          currentValue: booking.status,
                          items: [
                            'pending',
                            'accepted',
                            'completed',
                            'cancelled',
                          ],
                          onSelected: (v) => onStatusChanged(booking, v),
                        ),

                        _buildActionMenu(
                          icon: Icons.payments_outlined,
                          currentValue: booking.paymentStatus,
                          items: ['paid', 'unpaid'],
                          onSelected: (v) => onPaymentChanged(booking, v),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.content_cut,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  serviceTitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  booking.dateTime
                                      .toLocal()
                                      .toString()
                                      .substring(0, 16),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _miniBadge(booking.status, statusColor),
                            const SizedBox(height: 4),
                            _miniBadge(
                              booking.paymentStatus,
                              booking.paymentStatus == 'paid'
                                  ? Colors.green
                                  : Colors.redAccent,
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildActionMenu({
    required IconData icon,
    required String currentValue,
    required List<String> items,
    required Function(String) onSelected,
  }) {
    return PopupMenuButton<String>(
      icon: Icon(icon, size: 20, color: Colors.grey.shade400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      onSelected: onSelected,
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem(
              value: item,
              child: Text(
                item.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: item == currentValue ? kPrimaryColor : Colors.black87,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _miniBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

