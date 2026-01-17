import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';

Future<void> showAddServiceDialog({
  required BuildContext context,
  required Salon salon,
  required DatabaseReference servicesRef,
  required DatabaseReference salonServicesRef,
  required VoidCallback onSuccess,
}) async {
  final titleController = TextEditingController();
  final priceController = TextEditingController();
  final durationController = TextEditingController();

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Add new service',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Service title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Price'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: durationController,
            decoration: const InputDecoration(
              labelText: 'Duration (e.g. 60 min)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (ok != true) return;

  final title = titleController.text.trim();
  final price = double.tryParse(priceController.text.trim()) ?? 0.0;
  final duration = durationController.text.trim();

  if (title.isEmpty) return;

  final newServiceKey = servicesRef.push().key!;
  await servicesRef.child(newServiceKey).set({
    'name': title,
    'price': price,
    'duration': duration,
  });

  final newSalonServiceKey = salonServicesRef.push().key!;
  await salonServicesRef.child(newSalonServiceKey).set({
    'salonId': salon.id,
    'serviceId': newServiceKey,
    'price': price,
    'duration': duration,
  });

  onSuccess();
}
