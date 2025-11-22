import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MyOrdersPage extends StatefulWidget {
  final bool isSalonOwner; // true إذا صاحب الصالون
  final String? salonId; // معرف الصالون إذا صاحب الصالون

  const MyOrdersPage({Key? key, this.isSalonOwner = false, this.salonId})
    : super(key: key);

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Get the query depending on tab and user type
  Query? _getQueryForTab(int tabIndex) {
    if (_currentUser == null) return null;

    String status = '';
    switch (tabIndex) {
      case 0:
        status = 'pending';
        break;
      case 1:
        status = 'completed';
        break;
      case 2:
        status = 'cancelled';
        break;
    }

    if (widget.isSalonOwner && widget.salonId != null) {
      // قراءة الحجوزات لصالون المالك
      return _dbRef
          .child('salon_bookings')
          .child(widget.salonId!)
          .orderByChild('status')
          .equalTo(status);
    } else {
      // قراءة حجوزات المستخدم العادي
      return _dbRef
          .child('user_bookings')
          .child(_currentUser!.uid)
          .orderByChild('status')
          .equalTo(status);
    }
  }

  String _friendlyStatus(String? status) {
    final s = status ?? '';
    if (s.isEmpty) return 'Unknown';
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("My Orders")),
        body: const Center(
          child: Text(
            "You must be logged in to view your orders.",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          tabs: const [
            Tab(text: "Active Order"),
            Tab(text: "Complete Order"),
            Tab(text: "Cancel Order"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOrderList(0), _buildOrderList(1), _buildOrderList(2)],
      ),
    );
  }

  Widget _buildOrderList(int tabIndex) {
    final query = _getQueryForTab(tabIndex);
    if (query == null) {
      return const Center(child: Text("Cannot load orders."));
    }

    return StreamBuilder<DatabaseEvent>(
      stream: query.onValue.asBroadcastStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data?.snapshot.value;
        if (data == null) {
          return const Center(child: Text("No orders found"));
        }

        final Map<dynamic, dynamic> bookings = data as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> orders = [];

        bookings.forEach((key, value) {
          if (value is Map) {
            orders.add(Map<String, dynamic>.from(value));
          }
        });

        if (orders.isEmpty) {
          return const Center(child: Text("No orders in this category"));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final booking = orders[index];
            final salonName = booking['salonName'] ?? 'Unknown Salon';
            final serviceName = booking['serviceName'] ?? 'Service';
            final price = booking['price']?.toString() ?? '0';
            final status = booking['status']?.toString() ?? 'Unknown';
            final payment = booking['paymentStatus']?.toString() ?? 'Unpaid';
            final date = booking['date'] ?? '—';

            final paymentLabel = (payment.isNotEmpty)
                ? (payment[0].toUpperCase() + payment.substring(1))
                : 'Unknown';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                title: Text(
                  salonName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(serviceName),
                    Text("Date: $date"),
                    Text("Price: \$${price}"),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Chip(
                          label: Text(_friendlyStatus(status)),
                          backgroundColor: Colors.grey.withOpacity(0.2),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(paymentLabel),
                          backgroundColor: payment == 'paid'
                              ? Colors.green.withOpacity(0.12)
                              : Colors.grey.withOpacity(0.12),
                          labelStyle: TextStyle(
                            color: payment == 'paid'
                                ? Colors.green
                                : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Track Order"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
