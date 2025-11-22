import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:glamora_project/core/utils/app_router.dart';
import 'package:glamora_project/models.dart'; // تأكدي من المسار الصحيح لمودل AppUser

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();
  final _storage = FirebaseStorage.instance;

  AppUser? _user;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final snapshot = await _db.child('users').child(fbUser.uid).get();
      if (snapshot.exists && snapshot.value is Map) {
        final map = Map<String, dynamic>.from(snapshot.value as Map);
        setState(() {
          _user = AppUser.fromMap(fbUser.uid, map);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _loading = false);
    }
  }

  /// تحديث جزء من بيانات اليوزر في الـ DB وفي الـ state
  Future<void> _updateUserData(Map<String, dynamic> data) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null || _user == null) return;

    setState(() => _saving = true);

    try {
      await _db.child('users').child(fbUser.uid).update(data);

      // نعمل merge للبيانات القديمة + الجديدة ونبني AppUser جديد
      final merged = _user!.toMap()..addAll(data);
      _user = AppUser.fromMap(_user!.id, merged);

      setState(() {});
    } catch (e) {
      debugPrint('Error updating user data: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// تغيير صورة البروفايل ورفعها على Firebase Storage
  Future<void> _changeProfileImage() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _saving = true);

    try {
      final file = File(picked.path);
      final ref = _storage
          .ref()
          .child('user_profile_images')
          .child('${fbUser.uid}.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await _updateUserData({'image': url});
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// BottomSheet لتعديل الاسم والعنوان
  void _showEditProfileSheet() {
    if (_user == null) return;

    final nameController = TextEditingController(text: _user!.name);
    final addressController = TextEditingController(text: _user!.address ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final address = addressController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name cannot be empty')),
                      );
                      return;
                    }

                    await _updateUserData({'name': name, 'address': address});

                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated')),
                    );
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _logout() async {
    await _auth.signOut();
    if (mounted) {
      GoRouter.of(context).pushReplacement(AppRouter.kLoginView);
    }
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                offset: const Offset(0, 2),
                color: Colors.black.withOpacity(0.05),
              ),
            ],
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildListItem(
    IconData icon,
    String title, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFEFF5),
              child: Icon(icon, color: const Color(0xFFB00063), size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          centerTitle: true,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('No user data found')),
      );
    }

    final name = _user!.name;
    final email = _user!.email;
    final imageUrl = _user!.image ?? '';
    final address = _user!.address ?? '';
    final phone = _user!.phone ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFDF5F8),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ===== Header =====
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _changeProfileImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundImage: imageUrl.isNotEmpty
                                  ? NetworkImage(imageUrl)
                                  : const AssetImage('assets/default_user.png')
                                        as ImageProvider,
                              backgroundColor: Colors.grey.shade200,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Color(0xFFB00063),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                            if (address.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _showEditProfileSheet,
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFFB00063),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ===== My Account =====
                _buildSectionCard(
                  title: "My Account",
                  children: [
                    _buildListItem(
                      Icons.person_outline,
                      'Personal Details',
                      subtitle: 'Name, email & address',
                      onTap: _showEditProfileSheet,
                    ),
                    const Divider(height: 0),
                    _buildListItem(
                      Icons.phone_android_outlined,
                      'Phone Number',
                      subtitle: phone.isNotEmpty ? phone : 'Add your phone',
                      onTap: () {
                        // تقدرِ لاحقاً تعملي Sheet لتعديل رقم الجوال
                      },
                    ),
                    const Divider(height: 0),
                    _buildListItem(
                      Icons.account_balance_wallet_outlined,
                      'My Wallet',
                      subtitle: 'Balance, coupons & offers',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Wallet screen coming soon'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 0),
                    _buildListItem(
                      Icons.payment_outlined,
                      'Payment',
                      subtitle: 'Cards & payment methods',
                      onTap: () {
                        // لما تعملي شاشة دفع: GoRouter.of(context).push(AppRouter.kPaymentView);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connect to payment screen here'),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // ===== Settings =====
                _buildSectionCard(
                  title: "Settings",
                  children: [
                    _buildListItem(
                      Icons.notifications_none,
                      'Notifications',
                      subtitle: 'Push & in-app notifications',
                    ),
                    const Divider(height: 0),
                    _buildListItem(Icons.help_outline, 'Help & Contact'),
                    const Divider(height: 0),
                    _buildListItem(Icons.question_answer_outlined, 'FAQ'),
                    const Divider(height: 0),
                    _buildListItem(Icons.settings_outlined, 'App Settings'),
                  ],
                ),

                // ===== About =====
                _buildSectionCard(
                  title: "About",
                  children: [
                    _buildListItem(Icons.info_outline, 'About App'),
                    const Divider(height: 0),
                    _buildListItem(
                      Icons.privacy_tip_outlined,
                      'Privacy Policy',
                    ),
                    const Divider(height: 0),
                    _buildListItem(
                      Icons.description_outlined,
                      'Terms & Conditions',
                    ),
                  ],
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),

          if (_saving)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),

      // زر تسجيل الخروج تحت
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              elevation: 0,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Log out',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
