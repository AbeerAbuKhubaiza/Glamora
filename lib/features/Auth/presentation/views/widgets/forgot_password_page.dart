import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _loading = false;

  void sendOtp() async {
    String email = _emailController.text.trim();
    if (email.isEmpty) {
      Fluttertoast.showToast(msg: "أدخل البريد الإلكتروني");
      return;
    }

    setState(() => _loading = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      Fluttertoast.showToast(
        msg: "تم إرسال رابط إعادة تعيين كلمة المرور للبريد",
      );
      Navigator.pushNamed(context, '/otp', arguments: email);/////////////////////////////////////
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "حدث خطأ");
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("نسيت كلمة المرور")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "البريد الإلكتروني"),
            ),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: sendOtp,
                    child: const Text("إرسال رابط إعادة تعيين"),
                  ),
          ],
        ),
      ),
    );
  }
}
