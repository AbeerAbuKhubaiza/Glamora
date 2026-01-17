import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:glamora_project/core/constants/constants.dart';

class MyOrdersPage extends StatefulWidget {
  final bool isSalonOwner;
  final String? salonId;

  const MyOrdersPage({super.key, this.isSalonOwner = false, this.salonId});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  User? _currentUser;

  Map<String, String> _salonNames = {};
  Map<String, String> _serviceNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUser = FirebaseAuth.instance.currentUser;
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final salonsSnap = await _dbRef.child('salons').get();
      final servicesSnap = await _dbRef.child('services').get();

      final Map<String, String> salons = {};
      final Map<String, String> services = {};

      final salonsVal = salonsSnap.value;
      if (salonsVal is Map) {
        salonsVal.forEach((key, value) {
          if (value is Map) {
            final name = value['name']?.toString().trim();
            if (name != null && name.isNotEmpty) {
              salons[key.toString()] = name;
            }
          }
        });
      }

      final servicesVal = servicesSnap.value;
      if (servicesVal is Map) {
        servicesVal.forEach((key, value) {
          if (value is Map) {
            final title = (value['title'] ?? value['name'])?.toString().trim();
            if (title != null && title.isNotEmpty) {
              services[key.toString()] = title;
            }
          }
        });
      }

      if (!mounted) return;
      setState(() {
        _salonNames = salons;
        _serviceNames = services;
      });
    } catch (_) {
      if (!mounted) return;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Query? _baseQuery() {
    if (_currentUser == null) return null;

    if (widget.isSalonOwner && widget.salonId != null) {
      return _dbRef
          .child('bookings')
          .orderByChild('salonId')
          .equalTo(widget.salonId);
    } else {
      return _dbRef
          .child('bookings')
          .orderByChild('userId')
          .equalTo(_currentUser!.uid);
    }
  }

  String _statusForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'pending';
      case 1:
        return 'completed';
      case 2:
        return 'cancelled';
      default:
        return 'pending';
    }
  }

  String _formatDate(dynamic dt) {
    final raw = dt?.toString();
    if (raw == null || raw.isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '—';
    return DateFormat('MMM d, yyyy • HH:mm').format(parsed.toLocal());
  }

  String _cap(String v) =>
      v.isEmpty ? v : (v[0].toUpperCase() + v.substring(1));

  Widget _fancyTabs() {
    final labels = const ["Active Order", "Complete Order", "Cancel Order"];

    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        final currentIndex = _tabController.index;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: List.generate(labels.length, (i) {
              final isActive = i == currentIndex;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == labels.length - 1 ? 0 : 10,
                  ),
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: isActive ? kPrimaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive
                              ? kPrimaryColor
                              : Colors.black.withOpacity(0.18),
                          width: 1,
                        ),
                        boxShadow: [
                          if (isActive)
                            BoxShadow(
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                              color: kPrimaryColor.withOpacity(0.18),
                            )
                          else
                            BoxShadow(
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                              color: Colors.black.withOpacity(0.05),
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.black,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0.4,
          title: Text(
            "My Orders",
            style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w700),
          ),
        ),
        body: const Center(
          child: Text("You must be logged in to view your orders."),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "My Orders",
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _fancyTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(0),
                _buildOrderList(1),
                _buildOrderList(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(int tabIndex) {
    final query = _baseQuery();
    if (query == null) {
      return const Center(child: Text("Cannot load orders."));
    }

    final wantedStatus = _statusForTab(tabIndex);

    return StreamBuilder<DatabaseEvent>(
      stream: query.onValue.asBroadcastStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kPrimaryColor),
          );
        }

        final data = snapshot.data?.snapshot.value;
        if (data == null) {
          return const Center(child: Text("No orders found"));
        }

        if (data is! Map) {
          return const Center(child: Text("No orders found"));
        }

        final List<Map<String, dynamic>> orders = [];
        data.forEach((key, value) {
          if (value is Map) {
            final map = Map<String, dynamic>.from(value);
            if ((map['status']?.toString() ?? '') == wantedStatus) {
              orders.add(map);
            }
          }
        });

        orders.sort((a, b) {
          final ad =
              DateTime.tryParse(a['datetime']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bd =
              DateTime.tryParse(b['datetime']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

        if (orders.isEmpty) {
          return const Center(child: Text("No orders in this category"));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final booking = orders[index];

            final salonId = booking['salonId']?.toString() ?? '';
            final serviceId = booking['serviceId']?.toString() ?? '';

            final salonName = _salonNames[salonId] ?? 'Unknown Salon';
            final serviceName = _serviceNames[serviceId] ?? 'Service';

            final price = booking['price']?.toString();
            final showPrice = price != null && price.trim().isNotEmpty;
            final priceLabel = showPrice ? '\$$price' : '';

            final status = booking['status']?.toString() ?? 'unknown';
            final payment = booking['paymentStatus']?.toString() ?? 'unpaid';
            final date = _formatDate(booking['datetime']);

            final bool paid = payment == 'paid';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.10)),
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
                    width: 4,
                    height: 86,
                    decoration: BoxDecoration(
                      color: kPrimaryColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          salonName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              serviceName,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.65),
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                            if (showPrice) ...[
                              const SizedBox(width: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                child: Text(
                                  priceLabel,
                                  style: TextStyle(
                                    color: kPrimaryColor,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 6),
                        Text(
                          date,
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.55),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _pill(
                              _cap(status),
                              bg: Colors.black.withOpacity(0.06),
                              fg: Colors.black,
                              height: 38,
                              radius: 14,
                            ),
                            const SizedBox(width: 8),
                            _pill(
                              _cap(payment),
                              bg: paid
                                  ? kPrimaryColor.withOpacity(0.12)
                                  : Colors.black.withOpacity(0.06),
                              fg: paid ? kPrimaryColor : Colors.black,
                              height: 38,
                              radius: 14,
                            ),
                            const Spacer(),

                            InkWell(
                              onTap: () {},
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                height: 38,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: kPrimaryColor,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                      color: kPrimaryColor.withOpacity(0.22),
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  "Track",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _pill(
    String text, {
    required Color bg,
    required Color fg,
    double height = 38,
    double radius = 14,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.black.withOpacity(0.10)),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
