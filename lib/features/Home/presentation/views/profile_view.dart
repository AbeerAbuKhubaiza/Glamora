import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/core/routing/app_router.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Auth/data/users_repository.dart';
import 'package:glamora_project/core/network/realtime_api.dart';

class UserProfileView extends StatefulWidget {
  const UserProfileView({super.key});

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final UsersRepository _usersRepo = const UsersRepository();

  AppUser? _user;
  bool _loading = true;
  bool _saving = false;

  int _bookingsCount = 0;
  int _reviewsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrCreateUser();
  }

  Future<void> _loadOrCreateUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      var user = await _usersRepo.fetchUserById(fbUser.uid);

      if (user == null) {
        final displayName = (fbUser.displayName?.trim().isNotEmpty ?? false)
            ? fbUser.displayName!.trim()
            : 'User';

        user = AppUser(
          id: fbUser.uid,
          name: displayName,
          email: fbUser.email ?? '',
          role: 'client',
          phone: fbUser.phoneNumber,
          joinedAt: DateTime.now().toUtc(),
          favorites: const {},
          image: '',
          address: '',
        );

        await _usersRepo.saveUser(user);
      }

      final counts = await Future.wait<int>([
        _countUserBookings(fbUser.uid),
        _countUserReviews(fbUser.uid),
      ]);

      if (!mounted) return;
      setState(() {
        _user = user;
        _bookingsCount = counts[0];
        _reviewsCount = counts[1];
        _loading = false;
      });
    } catch (e) {
      debugPrint('Profile load/create error: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<int> _countUserBookings(String uid) async {
    try {
      final data = await getNode('bookings');
      if (data == null) return 0;
      int c = 0;
      data.forEach((_, v) {
        if (v is Map && v['userId']?.toString() == uid) c++;
      });
      return c;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _countUserReviews(String uid) async {
    try {
      final data = await getNode('reviews');
      if (data == null) return 0;
      int c = 0;
      data.forEach((_, v) {
        if (v is Map && v['userId']?.toString() == uid) c++;
      });
      return c;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _updateUserData(Map<String, dynamic> data) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null || _user == null) return;

    setState(() => _saving = true);

    try {
      final merged = _user!.toMap()..addAll(data);
      final updatedUser = AppUser.fromMap(_user!.id, merged);

      await _usersRepo.saveUser(updatedUser);

      if (!mounted) return;
      setState(() {
        _user = updatedUser;
      });
    } catch (e) {
      debugPrint('Error updating user: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update profile')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    await _uploadProfileImage(File(picked.path));
  }

  Future<void> _pickFromCamera() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) return;
    await _uploadProfileImage(File(picked.path));
  }

  Future<void> _uploadProfileImage(File file) async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return;

    setState(() => _saving = true);
    try {
      final ref = _storage.ref().child('user_profile_images/${fbUser.uid}.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await _updateUserData({'image': url});
    } catch (e) {
      debugPrint('Upload image error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to upload image')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      GoRouter.of(context).pushReplacement(AppRouter.kLoginView);
    }
  }

  Future<T?> _showAnimatedDialog<T>({
    required Widget child,
    bool dismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: 'dialog',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: Material(color: Colors.transparent, child: child),
          ),
        );
      },
      transitionBuilder: (context, anim, _, dialogChild) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
            child: dialogChild,
          ),
        );
      },
    );
  }

  void _showLogoutDialog() {
    _showAnimatedDialog(
      child: _PremiumDialog(
        title: "Are you sure?",
        subtitle: "Do you really want to log out?",
        icon: Icons.help_outline,
        iconBg: Colors.red.shade50,
        iconColor: Colors.red,
        primaryText: "Log out",
        primaryColor: Colors.red,
        secondaryText: "Cancel",
        onPrimary: () {
          Navigator.pop(context);
          _logout();
        },
        onSecondary: () => Navigator.pop(context),
      ),
    );
  }

  void _showChangePhotoDialog() {
    _showAnimatedDialog(
      child: _ActionSheetDialog(
        title: "Change your picture",
        actions: [
          _SheetAction(
            icon: Icons.camera_alt_outlined,
            title: "Take a photo",
            onTap: () {
              Navigator.pop(context);
              _pickFromCamera();
            },
          ),
          _SheetAction(
            icon: Icons.folder_open_outlined,
            title: "Choose from your file",
            onTap: () {
              Navigator.pop(context);
              _pickFromGallery();
            },
          ),
          _SheetAction(
            icon: Icons.delete_outline,
            title: "Delete Photo",
            isDestructive: true,
            onTap: () {
              Navigator.pop(context);
              _updateUserData({'image': ''});
            },
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    if (_user == null) return;

    final nameCtrl = TextEditingController(text: _user!.name);
    final addressCtrl = TextEditingController(text: _user!.address ?? '');

    _showAnimatedDialog(
      dismissible: true,
      child: _FormDialog(
        title: "Edit Profile",
        fields: [
          _DialogField(
            label: "Full Name",
            controller: nameCtrl,
            icon: Icons.person_outline,
          ),
          _DialogField(
            label: "Address",
            controller: addressCtrl,
            icon: Icons.location_on_outlined,
          ),
        ],
        primaryText: "Save changes",
        onPrimary: () async {
          final name = nameCtrl.text.trim();
          final addr = addressCtrl.text.trim();

          if (name.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Name cannot be empty')),
            );
            return;
          }

          await _updateUserData({'name': name, 'address': addr});
          if (!mounted) return;
          Navigator.pop(context);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                offset: const Offset(0, 4),
                color: Colors.black.withOpacity(0.04),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFFEFF5),
              child: Icon(icon, color: kPrimaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
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
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: kPrimaryColor)),
      );
    }

    final fbUser = _auth.currentUser;

    if (fbUser == null) {
      return _NoUserScreen(
        onGoLogin: () =>
            GoRouter.of(context).pushReplacement(AppRouter.kLoginView),
      );
    }

    if (_user == null) {
      return _NoUserScreen(
        onGoLogin: () =>
            GoRouter.of(context).pushReplacement(AppRouter.kLoginView),
      );
    }

    final name = _user!.name;
    final email = _user!.email;
    final imageUrl = _user!.image ?? '';
    final address = _user!.address ?? '';
    final phone = _user!.phone ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _showLogoutDialog,
            icon: Icon(Icons.logout, color: kPrimaryColor),
            tooltip: 'Log out',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _showChangePhotoDialog, 
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundImage: imageUrl.isNotEmpty
                                      ? NetworkImage(imageUrl)
                                      : const AssetImage(
                                              'assets/images/default_user.png',
                                            )
                                            as ImageProvider,
                                  backgroundColor: Colors.grey.shade200,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                          color: Colors.black.withOpacity(0.12),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (address.isNotEmpty) ...[
                                  const SizedBox(height: 5),
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
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _showEditProfileDialog, 
                            icon: Icon(
                              Icons.edit_outlined,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _statTile("Bookings", _bookingsCount.toString()),
                          const SizedBox(width: 10),
                          _statTile("Reviews", _reviewsCount.toString()),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _section(
                  title: "My Account",
                  children: [
                    _item(
                      icon: Icons.person_outline,
                      title: 'Personal Details',
                      subtitle: 'Name & address',
                      onTap: _showEditProfileDialog,
                    ),
                    const Divider(height: 0),
                    _item(
                      icon: Icons.phone_android_outlined,
                      title: 'Phone Number',
                      subtitle: phone.isNotEmpty ? phone : 'Add your phone',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _section(
                  title: "App",
                  children: [
                    _item(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Push & in-app notifications',
                      onTap: () {},
                    ),
                    const Divider(height: 0),
                    _item(
                      icon: Icons.help_outline,
                      title: 'Help & Contact',
                      onTap: () {},
                    ),
                    const Divider(height: 0),
                    _item(
                      icon: Icons.settings_outlined,
                      title: 'App Settings',
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),

          if (_saving)
            Container(
              color: Colors.black.withOpacity(0.10),
              child: const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              ),
            ),
        ],
      ),
    );
  }
}


class _PremiumDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  final String primaryText;
  final Color primaryColor;
  final String secondaryText;

  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const _PremiumDialog({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.primaryText,
    required this.primaryColor,
    required this.secondaryText,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPrimary,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(primaryText),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSecondary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(secondaryText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetAction {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  _SheetAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });
}

class _ActionSheetDialog extends StatelessWidget {
  final String title;
  final List<_SheetAction> actions;

  const _ActionSheetDialog({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          ...actions.map((a) {
            final color = a.isDestructive ? Colors.red : Colors.black87;
            return InkWell(
              onTap: a.onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(a.icon, color: color),
                    const SizedBox(width: 12),
                    Text(
                      a.title,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DialogField {
  final String label;
  final TextEditingController controller;
  final IconData icon;

  _DialogField({
    required this.label,
    required this.controller,
    required this.icon,
  });
}

class _FormDialog extends StatelessWidget {
  final String title;
  final List<_DialogField> fields;
  final String primaryText;
  final VoidCallback onPrimary;
  final VoidCallback onClose;

  const _FormDialog({
    required this.title,
    required this.fields,
    required this.primaryText,
    required this.onPrimary,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 6),
          ...fields.map((f) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: f.controller,
                decoration: InputDecoration(
                  labelText: f.label,
                  prefixIcon: Icon(f.icon),
                  floatingLabelStyle: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: kPrimaryColor,
                      width: 1.6,
                    ),
                  ),

                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                primaryText,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoUserScreen extends StatelessWidget {
  final VoidCallback onGoLogin;

  const _NoUserScreen({required this.onGoLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              const Text(
                'No user data found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please log in or create a new account to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onGoLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Go to Login / Create Account',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
