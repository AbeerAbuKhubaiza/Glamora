import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/core/routing/app_router.dart';
import 'package:glamora_project/features/Auth/presentation/widgets/auth_ui_helpers.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SignUpViewBody extends StatefulWidget {
  const SignUpViewBody({super.key});

  @override
  State<SignUpViewBody> createState() => _SignUpViewBodyState();
}

class _SignUpViewBodyState extends State<SignUpViewBody> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _navigateClientHome() {
    if (!mounted) return;
    context.go(AppRouter.kHomeView);
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'weak-password':
        return 'Password is too weak (min 6 characters).';
      case 'network-request-failed':
        return 'Network error, please check your connection.';
      default:
        return 'Sign up failed, please try again.';
    }
  }

  String _mapGoogleSignInErrorToMessage(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Sign-in was cancelled.';
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Google Sign-In configuration issue. Check Firebase & Google Console.';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google Sign-In provider is not available right now.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google Sign-In UI is unavailable on this device.';
      default:
        return 'Google Sign-In failed, please try again.';
    }
  }

  Future<void> _showSignUpErrorDialog({
    String title = 'Sign up failed',
    required String message,
  }) {
    return AuthDialogs.showGlamoraDialog(
      context: context,
      icon: Icons.error_outline_rounded,
      iconColor: Colors.redAccent,
      title: title,
      message: message,
      primaryLabel: 'Try again',
    );
  }

  Future<void> _showEmailInUseDialog(String email) {
    return AuthDialogs.showGlamoraDialog(
      context: context,
      icon: Icons.mark_email_read_outlined,
      iconColor: kPrimaryColor,
      title: 'Email already used',
      message:
          'The email "$email" already has an account.\nTry logging in instead.',
      primaryLabel: 'Go to Login',
      secondaryLabel: 'Cancel',
      onPrimaryPressed: () {
        context.go(AppRouter.kLoginView);
      },
    );
  }

  Future<void> _signupWithEmail() async {
    if (_loading) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    setState(() => _loading = true);

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      final nowIso = DateTime.now().toUtc().toIso8601String();

      await _db.child('users').child(uid).set({
        "id": uid,
        "name": name,
        "email": email,
        "phone": phone,
        "role": "client",
        "fcmToken": null,
        "joinedAt": nowIso,
        "favorites": {},
        "image": "",
        "address": "",
      });

      _navigateClientHome();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        await _showEmailInUseDialog(email);
      } else {
        await _showSignUpErrorDialog(message: _mapFirebaseAuthError(e));
      }
    } catch (_) {
      await _showSignUpErrorDialog(
        message: 'Unexpected error, please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize();

      if (!googleSignIn.supportsAuthenticate()) {
        await _showSignUpErrorDialog(
          title: 'Google not supported',
          message: 'Google Sign-In is not supported on this platform.',
        );
        return;
      }

      final googleUser = await googleSignIn.authenticate(
        scopeHint: const ['email'],
      );

      final googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCred = await _auth.signInWithCredential(credential);
      final user = userCred.user!;
      final uid = user.uid;

      final snapshot = await _db.child('users').child(uid).get();

      if (!snapshot.exists || snapshot.value is! Map) {
        final nowIso = DateTime.now().toUtc().toIso8601String();
        await _db.child('users').child(uid).set({
          "id": uid,
          "name": user.displayName ?? "",
          "email": user.email ?? "",
          "phone": user.phoneNumber ?? "",
          "role": "client",
          "fcmToken": null,
          "joinedAt": nowIso,
          "favorites": {},
          "image": user.photoURL ?? "",
          "address": "",
        });
      }

      _navigateClientHome();
    } on GoogleSignInException catch (e) {
      await _showSignUpErrorDialog(
        title: 'Google Sign-In failed',
        message: _mapGoogleSignInErrorToMessage(e),
      );
    } on FirebaseAuthException catch (e) {
      await _showSignUpErrorDialog(message: _mapFirebaseAuthError(e));
    } catch (_) {
      await _showSignUpErrorDialog(
        message: 'Google Sign-In failed, please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(
                "Glamora",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Create your Glamora account and start booking beauty services!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: AuthUI.inputDecoration(
                  "Full Name",
                  Icons.person_outline,
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Full name is required';
                  if (v.length < 3) return 'Please enter your full name';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: AuthUI.inputDecoration(
                  "Email",
                  Icons.email_outlined,
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Email is required';
                  if (!EmailValidator.validate(v)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: AuthUI.inputDecoration(
                  "Password",
                  Icons.lock_outline,
                ),
                validator: (value) {
                  final v = value ?? '';
                  if (v.isEmpty) return 'Password is required';
                  if (v.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: AuthUI.inputDecoration(
                  "Phone Number",
                  Icons.phone_outlined,
                  prefixText: "+972 ",
                ),

                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Phone number is required';
                  if (v.length < 6) return 'Enter a valid phone number';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signupWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Sign up",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              AuthUI.sectionDivider("Or continue with"),
              const SizedBox(height: 16),

              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _signUpWithGoogle,
                  icon: Image.asset(
                    'assets/images/google.png',
                    height: 22,
                    width: 22,
                  ),
                  label: const Text(
                    'Sign up with Google',
                    style: TextStyle(fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  TextButton(
                    onPressed: () {
                      context.go(AppRouter.kLoginView);
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
