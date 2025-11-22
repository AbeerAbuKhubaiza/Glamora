import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:email_validator/email_validator.dart';
import 'package:glamora_project/core/utils/app_router.dart';
import 'package:go_router/go_router.dart';

class SignUpViewBody extends StatefulWidget {
  const SignUpViewBody({super.key});

  @override
  State<SignUpViewBody> createState() => _SignUpViewBodyState();
}

class _SignUpViewBodyState extends State<SignUpViewBody> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loading = false;

  void signup() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      Fluttertoast.showToast(msg: "يرجى ملء جميع الحقول");
      return;
    }
    if (!EmailValidator.validate(email)) {
      Fluttertoast.showToast(msg: "البريد الإلكتروني غير صالح");
      return;
    }
    if (password.length < 6) {
      Fluttertoast.showToast(msg: "كلمة المرور يجب أن تكون 6 أحرف على الأقل");
      return;
    }

    setState(() => _loading = true);
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      final nowIso = DateTime.now().toUtc().toIso8601String();

      // ✅ تخزين اليوزر بنفس شكل الجيسون + المودل AppUser
      await _db.child('users').child(uid).set({
        "id": uid,
        "name": name,
        "email": email,
        "phone": phone,
        "role": "client",
        "fcmToken": null,
        "joinedAt": nowIso,
        "favorites": {}, // مبدئياً فاضي
        "image": "", // ما في صورة لسه
        "address": "", // يقدر يضيفها من البروفايل
      });

      Fluttertoast.showToast(msg: "تم إنشاء الحساب بنجاح");
      GoRouter.of(context).pushReplacement(AppRouter.kHomeView);
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "حدث خطأ");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget socialButton(String asset, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Image.asset(asset, height: 24, width: 24)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Glamora",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6C1E4E),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Sign up\nLorem ipsum dolor sit amet consectetur it...",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // 🆕 Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Phone
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                  prefixText: "+966 ",
                ),
              ),
              const SizedBox(height: 24),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C1E4E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Sign up",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),

              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "Or continue with",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  socialButton('assets/google.png', () {}),
                  socialButton('assets/apple.png', () {}),
                  socialButton('assets/facebook.png', () {}),
                ],
              ),
              const SizedBox(height: 24),

              TextButton(
                onPressed: () {
                  GoRouter.of(context).pushReplacement(AppRouter.kLoginView);
                },
                child: const Text(
                  "Don't have an account? Login",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6C1E4E)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
