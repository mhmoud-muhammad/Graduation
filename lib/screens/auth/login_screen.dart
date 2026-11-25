import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/messages.dart';
import '../../core/validators.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import 'register_screen.dart';

/// واجهة تسجيل الدخول (FR-02).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// تسلسل تسجيل الدخول: إدخال البريد وكلمة المرور ← الضغط على "دخول" ←
  /// إرسال البيانات للتحقق منها عبر Firebase Authentication:
  /// - ضعف الإنترنت: "تعذر تسجيل الدخول، الرجاء إعادة المحاولة عند توفر اتصال"
  /// - بيانات غير صحيحة: "البيانات غير صحيحة، قم بتصحيحها" ويبقى في الشاشة
  /// - صحيحة: يقرأ النظام نوع الحساب من users ويوجّه المستخدم إلى واجهة
  ///   البحث والصيدلي إلى لوحة التحكم (AuthGate).
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    await runWithRetry(
      context,
      () => Services.I.auth.signIn(_email.text, _password.text),
      networkMessage: Msg.loginNetwork,
      errorTitle: Msg.loginInvalid,
    );
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: WaveBackground(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 96, 30, 20),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: BrandMark()),
                    const SizedBox(height: 30),
                    const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        hintText: 'البريد الإلكتروني',
                        suffixIcon: Icon(
                          Icons.mail_outline,
                          color: AppColors.primary,
                        ),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        hintText: 'كلمة المرور',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.lock : Icons.lock_open,
                            color: AppColors.primary,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 22),
                    LoadingButton(
                      label: 'دخول',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ليس لديك حساب؟',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF4A5568)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      child: const Text(
                        'إنشاء حساب',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Illustration('pharmacy_building', height: 120),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
