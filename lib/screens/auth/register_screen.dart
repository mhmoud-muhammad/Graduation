import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../core/messages.dart';
import '../../core/validators.dart';
import '../../models/app_user.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';

/// واجهة إنشاء حساب جديد مع تحديد نوع الحساب (FR-01).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UserType _type = UserType.user;
  bool _loading = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  /// تسلسل إنشاء حساب (المستخدم / الصيدلي): إدخال الاسم والبريد وكلمة المرور
  /// ورقم الهاتف واختيار نوع الحساب ← الضغط على "إنشاء الحساب" ← التحقق:
  /// - ضعف الاتصال: "فشلت عملية إنشاء الحساب، الرجاء المحاولة مرة أخرى..."
  /// - بيانات غير صحيحة أو بريد مستخدم مسبقاً: رسالة ثم التصحيح
  /// - صحيحة: إنشاء الحساب في Firebase Authentication وحفظ بياناته ونوعه في
  ///   users ← "تم إنشاء الحساب بنجاح" والتوجيه إلى شاشة تسجيل الدخول.
  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final ok = await runWithRetry(
      context,
      () => Services.I.auth.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
        phone: _phone.text,
        userType: _type,
      ),
      networkMessage: Msg.registerNetwork,
      errorTitle: Msg.registerInvalid,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      showSnack(context, Msg.registerSuccess);
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  InputDecoration _field(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    suffixIcon: Icon(icon, color: AppColors.logoutBlue),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.registerBg,
      appBar: AppBar(
        title: const Text('إنشاء حساب جديد'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          color: AppColors.navy,
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: WaveBackground(
        top: false,
        style: WaveStyle.teal,
        color: AppColors.registerBg,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 130),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Illustration('register_header', height: 150),
                const SizedBox(height: 6),
                const Text(
                  'انضم إلينا للبحث عن الأدوية بسهولة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: _field('الاسم الكامل', Icons.person),
                  validator: (v) => Validators.required(v, 'الاسم'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _field('البريد الإلكتروني', Icons.mail_outline),
                  validator: Validators.email,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: _field('رقم الهاتف (اختياري)', Icons.phone),
                  validator: Validators.optionalPhone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  decoration: _field('كلمة المرور', Icons.lock_outline),
                  validator: Validators.password,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: _field('تأكيد كلمة المرور', Icons.lock_outline),
                  validator: (v) =>
                      v != _password.text ? 'كلمتا المرور غير متطابقتين' : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'نوع الحساب:',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final t in UserType.values) ...[
                      Expanded(
                        child: _TypeChip(
                          type: t,
                          selected: _type == t,
                          onTap: () => setState(() => _type = t),
                        ),
                      ),
                      if (t != UserType.values.last) const SizedBox(width: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                LoadingButton(
                  label: 'إنشاء الحساب',
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Expanded(child: Divider(indent: 30, endIndent: 12)),
                    Text(
                      'أو',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    Expanded(child: Divider(indent: 12, endIndent: 30)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('لديك حساب بالفعل؟'),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final UserType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.primaryDark;
    return Material(
      color: selected ? const Color(0xFF14858C) : Colors.white,
      elevation: selected ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.primary),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                type == UserType.pharmacist
                    ? Icons.medical_information_outlined
                    : Icons.person,
                color: fg,
              ),
              const SizedBox(width: 8),
              Text(
                type.label,
                style: TextStyle(color: fg, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
