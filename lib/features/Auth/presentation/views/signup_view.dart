import 'package:flutter/material.dart';
import 'package:glamora_project/features/Auth/presentation/widgets/signup_view_body.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SignUpViewBody(),
    );
  }
}
