import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Home/data/repo/services_repository.dart';

class OwnerServicesTab extends StatefulWidget {
  final Salon salon;

  const OwnerServicesTab({super.key, required this.salon});

  @override
  State<OwnerServicesTab> createState() => _OwnerServicesTabState();
}

class _OwnerServicesTabState extends State<OwnerServicesTab> {
  final _repo = const ServicesRepository();
  final _salonServicesRef = FirebaseDatabase.instance.ref('salon_services');
  final _servicesRef = FirebaseDatabase.instance.ref('services');

  late Future<List<Service>> _future;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _future = _repo.fetchSalonServices(widget.salon.id);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  Future<void> _deleteService(Service s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Service?'),
        content: Text('Are you sure you want to delete "${s.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _salonServicesRef.child(s.id).remove();
      await _refresh();
    }
  }

  Future<void> _showServiceDialog({Service? service}) async {
    final isEdit = service != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: service?.name ?? '');
    final priceController = TextEditingController(
      text: service?.price.toStringAsFixed(0) ?? '',
    );
    final durationController = TextEditingController(
      text: (service?.extra?['duration'] ?? '').toString(),
    );

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit_rounded : Icons.add_business_rounded,
                color: kPrimaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Edit Service' : 'New Service',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildValidatedField(
                    controller: nameController,
                    label: 'Service Name',
                    icon: Icons.title,
                    validator: (v) => v!.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    controller: priceController,
                    label: 'Price (\$)',
                    icon: Icons.attach_money,
                    isNumber: true,
                    validator: (v) {
                      if (v!.isEmpty) return 'Enter price';
                      if (double.tryParse(v) == null)
                        return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildValidatedField(
                    controller: durationController,
                    label: 'Duration (min)',
                    icon: Icons.timer_outlined,
                    validator: (v) => v!.isEmpty ? 'Enter duration' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final name = nameController.text.trim();
                  final price = double.parse(priceController.text.trim());
                  final duration = durationController.text.trim();

                  if (isEdit) {
                    final sId = service.extra?['serviceId']?.toString();
                    if (sId != null) {
                      await _servicesRef.child(sId).update({
                        'name': name,
                        'title': name,
                      });
                    }
                    await _salonServicesRef.child(service.id).update({
                      'price': price,
                      'duration': duration,
                      'serviceName': name,
                    });
                  } else {
                    final newServiceKey = _servicesRef.push().key!;
                    await _servicesRef.child(newServiceKey).set({
                      'title': name,
                      'name': name,
                      'price': price,
                      'duration': duration,
                    });
                    final newSalonServiceKey = _salonServicesRef.push().key!;
                    await _salonServicesRef.child(newSalonServiceKey).set({
                      'salonId': widget.salon.id,
                      'serviceId': newServiceKey,
                      'price': price,
                      'duration': duration,
                    });
                  }
                  Navigator.pop(ctx);
                  await _refresh();
                }
              },
              child: Text(
                isEdit ? 'Update' : 'Add Service',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFD),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Service>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: kPrimaryColor),
                  );
                }
                final services = snap.data ?? [];
                if (services.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_motion_outlined,
                          size: 70,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Your service list is empty',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      return _buildServiceCard(services[i]);
                    },
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity, 
                height: 54, 
                child: ElevatedButton.icon(
                  onPressed: () => _showServiceDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  label: const Text(
                    'Add New Service',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Service s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 4, color: kPrimaryColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: kPrimaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _badge(
                                  '\$${s.price.toStringAsFixed(0)}',
                                  Colors.green,
                                  Icons.attach_money,
                                ),
                                const SizedBox(width: 6),
                                _badge(
                                  '${(s.extra?['duration'] ?? '0')} min',
                                  Colors.blueGrey,
                                  Icons.timer_outlined,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _actionBtn(
                        Icons.edit_rounded,
                        Colors.blue,
                        () => _showServiceDialog(service: s),
                      ),
                      const SizedBox(width: 8),
                      _actionBtn(
                        Icons.delete_rounded,
                        Colors.red,
                        () => _deleteService(s),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidatedField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimaryColor, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
