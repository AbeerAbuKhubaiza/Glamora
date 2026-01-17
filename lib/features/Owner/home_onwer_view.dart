import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Home/data/repo/salons_repository.dart';
import 'package:glamora_project/features/Owner/showsalonpicker.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';


class HomeOnwerView extends StatefulWidget {
  const HomeOnwerView({super.key});

  @override
  State<HomeOnwerView> createState() => _HomeOnwerViewState();
}

class _HomeOnwerViewState extends State<HomeOnwerView> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();
  final _salonsRepo = const SalonsRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _auth.currentUser;
    if (user == null) {
      context.go(AppRouter.kLoginView);
      return;
    }

    final snap = await _db.child('users').child(user.uid).get();
    final owner = AppUser.fromMap(
      user.uid,
      Map<String, dynamic>.from(snap.value as Map),
    );

    final salons = await _salonsRepo.fetchOwnerSalonsByOwnerId(user.uid);

    if (!mounted) return;

    if (salons.length == 1) {
      context.goNamed(
        AppRouter.kOwnerSalonDashboard,
        extra: {'owner': owner, 'salon': salons.first, 'salons': salons},
      );
      return;
    }

    final selected = await showSalonPickerSheet(
      context: context,
      salons: salons,
    );

    if (selected != null) {
      context.goNamed(
        AppRouter.kOwnerSalonDashboard,
        extra: {'owner': owner, 'salon': selected, 'salons': salons},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
    );
  }
}
