import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:glamora_project/core/constants/constants.dart';
import 'package:glamora_project/core/routing/app_router.dart';
import 'package:glamora_project/features/Auth/presentation/widgets/auth_ui_helpers.dart';
import 'package:glamora_project/features/Home/data/model/models.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginViewbody extends StatefulWidget {
  const LoginViewbody({super.key});

  @override
  State<LoginViewbody> createState() => _LoginViewbodyState();
}

class _LoginViewbodyState extends State<LoginViewbody> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  bool _loading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateByRole(String role, {bool isApproved = true}) {
    if (!mounted) return;

    if (role == 'client') {
      context.go(AppRouter.kHomeView);
    } else if (role == 'owner') {
      if (isApproved) {
        context.go(AppRouter.kHomeOnwer);
      } else {
        _showLoginErrorDialog(
          title: 'Pending approval',
          message: 'Your owner account is pending admin approval.',
        );
      }
    } else {
      _showLoginErrorDialog(
        title: 'Unknown role',
        message: 'This account role is not recognized.',
      );
    }
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'This email is not registered.';
      case 'wrong-password':
        return 'Incorrect password, please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'Network error, please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts, please wait and try again.';
      default:
        return 'Login failed, please try again.';
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

  Future<void> _showLoginErrorDialog({
    String title = 'Login failed',
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

  Future<void> _showAccountNotFoundDialog(String email) {
    return AuthDialogs.showGlamoraDialog(
      context: context,
      icon: Icons.person_off_outlined,
      iconColor: kPrimaryColor,
      title: 'Account not found',
      message:
          'The email "$email" is not registered yet.\nCreate a new account to start using Glamora.',
      primaryLabel: 'Create account',
      secondaryLabel: 'Cancel',
      onPrimaryPressed: () {
        context.go(AppRouter.kSignUpView);
      },
    );
  }

  Future<void> _loginWithEmail() async {
    if (_loading) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _loading = true);

    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      final snapshot = await _db.child('users').child(uid).get();

      if (!snapshot.exists || snapshot.value is! Map) {
        await _showLoginErrorDialog(
          message: 'User data not found in database.',
        );
        return;
      }

      final map = Map<String, dynamic>.from(snapshot.value as Map);
      final appUser = AppUser.fromMap(uid, map);

      final role = appUser.role;
      final bool isApproved = (map['isApproved'] as bool?) ?? true;

      _navigateByRole(role, isApproved: isApproved);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        await _showAccountNotFoundDialog(email);
      } else {
        await _showLoginErrorDialog(message: _mapFirebaseAuthError(e));
      }
    } catch (_) {
      await _showLoginErrorDialog(
        message: 'Unexpected error, please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize();

      if (!googleSignIn.supportsAuthenticate()) {
        await _showLoginErrorDialog(
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

      String role = 'client';
      bool isApproved = true;

      final snapshot = await _db.child('users').child(uid).get();

      if (snapshot.exists && snapshot.value is Map) {
        final map = Map<String, dynamic>.from(snapshot.value as Map);
        final appUser = AppUser.fromMap(uid, map);
        role = appUser.role;
        isApproved = (map['isApproved'] as bool?) ?? true;
      } else {
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

      _navigateByRole(role, isApproved: isApproved);
    } on GoogleSignInException catch (e) {
      await _showLoginErrorDialog(
        title: 'Google Sign-In failed',
        message: _mapGoogleSignInErrorToMessage(e),
      );
    } on FirebaseAuthException catch (e) {
      await _showLoginErrorDialog(message: _mapFirebaseAuthError(e));
    } catch (_) {
      await _showLoginErrorDialog(
        title: 'Google Sign-In failed',
        message: 'Please try again.',
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
                "Welcome back to Glamora, we’re happy to see you again.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),

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
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
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
              const SizedBox(height: 8),

              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    activeColor: kPrimaryColor,
                    onChanged: (val) {
                      setState(() => _rememberMe = val ?? false);
                    },
                  ),
                  const Text("Remember me"),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      context.go(AppRouter.kForgetpassView);
                    },
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(fontSize: 13, color: kPrimaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _loginWithEmail,
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
                          "Login",
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
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: Image.asset(
                    'assets/images/google.png',
                    height: 22,
                    width: 22,
                  ),
                  label: const Text(
                    'Continue with Google',
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
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () {
                      context.go(AppRouter.kSignUpView);
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.w600,
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
