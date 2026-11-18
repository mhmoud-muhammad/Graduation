import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/firebase_errors.dart';
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

  /// مخطط تسلسل تسجيل الدخول:
  /// إدخال الإيميل والرقم السري ← النظام يتحقق من البيانات (Firebase Auth)
  /// ← غير صحيحة: "البيانات غير صحيحة الرجاء إعادة الإدخال" ثم رجوع
  /// ← صحيحة: النظام يفتح الشاشة الخاصة بالمستخدم أو الصيدلي (AuthGate).
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Services.I.auth.signIn(_email.text, _password.text);
    } catch (e) {
      if (mounted) {
        await showInvalidDataDialog(
          context,
          title: Msg.invalidReenter,
          reason: friendlyError(e),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    if (Validators.email(_email.text) != null) {
      showSnack(context, 'أدخل بريدك الإلكتروني أولاً', error: true);
      return;
    }
    try {
      await Services.I.auth.sendPasswordReset(_email.text);
      if (mounted) {
        showSnack(context, 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك');
      }
    } catch (e) {
      if (mounted) showSnack(context, friendlyError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WaveBackground(
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 120)),
                    const SizedBox(height: 10),
                    const Text(
                      'ابحث عن أدويتك بسهولة',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 16),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        hintText: 'البريد الإلكتروني',
                        prefixIcon: Icon(Icons.mail_outline),
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
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('نسيت كلمة المرور؟'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    LoadingButton(
                      label: 'دخول',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'ليس لديك حساب؟',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted),
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
                          fontSize: 17,
                        ),
                      ),
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
