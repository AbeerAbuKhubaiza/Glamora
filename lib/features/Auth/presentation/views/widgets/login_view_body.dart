import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glamora_project/core/utils/app_router.dart';
import 'package:go_router/go_router.dart';

import 'package:glamora_project/models.dart'; // عشان AppUser

class LoginViewbody extends StatefulWidget {
  const LoginViewbody({super.key});

  @override
  State<LoginViewbody> createState() => _LoginViewbodyState();
}

class _LoginViewbodyState extends State<LoginViewbody> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  bool _loading = false;

  Future<void> login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(msg: "يرجى ملء جميع الحقول");
      return;
    }

    setState(() => _loading = true);
    try {
      // تسجيل الدخول عبر Firebase Auth
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;

      // قراءة بيانات اليوزر من Realtime Database
      final snapshot = await _db.child('users').child(uid).get();
      if (!snapshot.exists || snapshot.value is! Map) {
        Fluttertoast.showToast(msg: "المستخدم غير موجود في قاعدة البيانات");
        return;
      }

      final map = Map<String, dynamic>.from(snapshot.value as Map);

      // استخدام المودل AppUser
      final appUser = AppUser.fromMap(uid, map);

      final role = appUser.role; // client / owner / admin
      // isApproved لو حبّيتِ تضيفيها لاحقاً على اليوزر
      final bool isApproved = map['isApproved'] ?? true;

      if (role == 'client') {
        GoRouter.of(context).pushReplacement(AppRouter.kHomeView);
      } else if (role == 'owner') {
        if (isApproved) {
          GoRouter.of(context).pushReplacement(AppRouter.kHomeOnwer);
        } else {
          Fluttertoast.showToast(msg: "تم تسجيلك ولكن لم تتم الموافقة بعد");
        }
      } else if (role == 'admin') {
        GoRouter.of(context).pushReplacement(AppRouter.kHomeAdmin);
      } else {
        // لو صار role غريب
        Fluttertoast.showToast(msg: "دور المستخدم غير معروف");
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "حدث خطأ");
    } catch (e) {
      Fluttertoast.showToast(msg: "حدث خطأ غير متوقع");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                "تسجيل الدخول",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "البريد الإلكتروني",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "كلمة المرور"),
              ),
              const SizedBox(height: 20),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: login,
                      child: const Text("تسجيل الدخول"),
                    ),
              TextButton(
                onPressed: () {
                  GoRouter.of(
                    context,
                  ).pushReplacement(AppRouter.kForgetpassView);
                },
                child: const Text("نسيت كلمة المرور؟"),
              ),
              TextButton(
                onPressed: () {
                  GoRouter.of(context).push(AppRouter.kSignUpView);
                },
                child: const Text("إنشاء حساب جديد"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
