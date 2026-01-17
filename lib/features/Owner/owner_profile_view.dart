import 'dart:io';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/core/routing/app_router.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:glamora_project/features/Auth/data/users_repository.dart';
import 'package:glamora_project/core/network/realtime_api.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class OwnerProfileTab extends StatefulWidget {
  final AppUser owner;
  final Salon salon;

  const OwnerProfileTab({super.key, required this.owner, required this.salon});

  @override
  State<OwnerProfileTab> createState() => _OwnerProfileTabState();
}

class _OwnerProfileTabState extends State<OwnerProfileTab> {
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final _usersRepo = const UsersRepository();

  late AppUser _currentOwner;
  late Salon _currentSalon;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _currentOwner = widget.owner;
    _currentSalon = widget.salon;
  }

  Future<void> _updateOwnerData(Map<String, dynamic> data) async {
    setState(() => _saving = true);
    try {
      final merged = _currentOwner.toMap()..addAll(data);
      final updated = AppUser.fromMap(_currentOwner.id, merged);
      await _usersRepo.saveUser(updated);
      if (mounted) setState(() => _currentOwner = updated);
    } catch (e) {
      _showSnackBar('Owner update failed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateSalonData(Map<String, dynamic> data) async {
    setState(() => _saving = true);
    try {
      await updateNode('salons/${_currentSalon.id}', data);
      if (mounted) {
        setState(() {
          _currentSalon = _currentSalon.copyWith(
            name: data['name'] ?? _currentSalon.name,
            city: data['address'] ?? _currentSalon.city,
          );
        });
      }
    } catch (e) {
      _showSnackBar('Salon update failed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 70,
    );
    if (picked == null) return;

    setState(() => _saving = true);
    try {
      final ref = _storage.ref().child(
        'owner_profiles/${_currentOwner.id}.jpg',
      );
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await _updateOwnerData({'image': url});
    } catch (e) {
      _showSnackBar('Upload failed');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),

                    _buildSection(
                      title: "Salon Details",
                      children: [
                        _infoItem(
                          Icons.storefront_outlined,
                          'Salon Name',
                          _currentSalon.name,
                          onTap: _showEditSalonNameDialog,
                        ),
                        _infoItem(
                          Icons.location_on_outlined,
                          'Location / City',
                          _currentSalon.city,
                          onTap: _showEditSalonCityDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      title: "Personal Account",
                      children: [
                        _infoItem(
                          Icons.person_outline_rounded,
                          'Full Name',
                          _currentOwner.name,
                          onTap: _showEditOwnerNameDialog,
                        ),
                        _infoItem(
                          Icons.alternate_email_rounded,
                          'Email Address',
                          _currentOwner.email,
                          onTap: _showEditEmailDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildStickyLogoutButton(),
          ],
        ),
        if (_saving) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildHeader() {
    final img = _currentOwner.image ?? '';
    return Row(
      children: [
        GestureDetector(
          onTap: _showPhotoOptions,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kPrimaryColor.withOpacity(0.2),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: kPrimaryColor.withOpacity(0.05),
                  backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
                  child: img.isEmpty
                      ? Text(
                          _currentOwner.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentOwner.name,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currentSalon.name,
                style: TextStyle(
                  fontSize: 14,
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _infoItem(
    IconData icon,
    String title,
    String value, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.black54, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.edit_note_rounded,
              size: 22,
              color: kPrimaryColor.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyLogoutButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
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
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          onPressed: _showLogoutConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.logout_rounded, size: 20),
          label: const Text(
            'Logout Account',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.2),
      child: const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      ),
    );
  }
  void _showEditSalonNameDialog() => _showSingleFieldDialog(
    title: "Salon Name",
    initialValue: _currentSalon.name,
    onSave: (val) => _updateSalonData({'name': val}),
  );

  void _showEditSalonCityDialog() => _showSingleFieldDialog(
    title: "Salon Location",
    initialValue: _currentSalon.city,
    onSave: (val) =>
        _updateSalonData({'address': val}),
  );

  void _showEditOwnerNameDialog() => _showSingleFieldDialog(
    title: "Owner Full Name",
    initialValue: _currentOwner.name,
    onSave: (val) => _updateOwnerData({'name': val}),
  );

  void _showEditEmailDialog() => _showSingleFieldDialog(
    title: "Email Address",
    initialValue: _currentOwner.email,
    onSave: (val) => _updateOwnerData({'email': val}),
  );

  void _showSingleFieldDialog({
    required String title,
    required String initialValue,
    required Function(String) onSave,
  }) {
    final ctrl = TextEditingController(text: initialValue);
    _showAnimatedDialog(
      child: _FormDialog(
        title: "Edit $title",
        fields: [
          _DialogField(
            label: title,
            controller: ctrl,
            icon: Icons.edit_outlined,
          ),
        ],
        primaryText: "Save Changes",
        onPrimary: () {
          if (ctrl.text.trim().isNotEmpty) {
            Navigator.pop(context);
            onSave(ctrl.text.trim());
          }
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showPhotoOptions() {
    _showAnimatedDialog(
      child: _ActionSheetDialog(
        title: "Profile Picture",
        actions: [
          _SheetAction(
            icon: Icons.camera_alt_outlined,
            title: "Use Camera",
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          _SheetAction(
            icon: Icons.photo_library_outlined,
            title: "Choose from Gallery",
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirm() {
    _showAnimatedDialog(
      child: _PremiumDialog(
        title: "Sign Out?",
        subtitle: "You will need to login again to manage your salon.",
        icon: Icons.logout_rounded,
        iconBg: Colors.red.shade50,
        iconColor: Colors.red,
        primaryText: "Logout",
        primaryColor: Colors.red,
        secondaryText: "Cancel",
        onPrimary: () async {
          await _auth.signOut();
          if (mounted) context.go(AppRouter.kLoginView);
        },
        onSecondary: () => Navigator.pop(context),
      ),
    );
  }

  Future<T?> _showAnimatedDialog<T>({required Widget child}) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: Material(color: Colors.transparent, child: child),
        ),
      ),
      transitionBuilder: (ctx, anim, anim2, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
    );
  }
}


class _FormDialog extends StatelessWidget {
  final String title, primaryText;
  final List<_DialogField> fields;
  final VoidCallback onPrimary, onClose;

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
      width: 350,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 22, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...fields.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: f.controller,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  labelText: f.label,
                  prefixIcon: Icon(f.icon, color: kPrimaryColor, size: 20),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: kPrimaryColor,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  labelStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                primaryText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumDialog extends StatelessWidget {
  final String title, subtitle, primaryText, secondaryText;
  final IconData icon;
  final Color iconBg, iconColor, primaryColor;
  final VoidCallback onPrimary, onSecondary;
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
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onSecondary,
                  child: Text(
                    secondaryText,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onPrimary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(primaryText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionSheetDialog extends StatelessWidget {
  final String title;
  final List<_SheetAction> actions;
  const _ActionSheetDialog({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...actions.map(
            (a) => InkWell(
              onTap: a.onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(a.icon, color: kPrimaryColor, size: 22),
                    const SizedBox(width: 14),
                    Text(
                      a.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
  _SheetAction({required this.icon, required this.title, required this.onTap});
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
