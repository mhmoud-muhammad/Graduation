import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/app_theme.dart';
import '../../models/app_user.dart';
import '../../services/services.dart';
import '../../widgets/common.dart';
import '../pharmacist/dashboard_screen.dart';
import '../user/home_screen.dart';
import 'login_screen.dart';

/// توجيه المستخدم إلى الواجهة المناسبة حسب حالة الدخول ونوع الحساب (FR-03).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.I;
    return StreamBuilder<User?>(
      stream: s.auth.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final user = authSnap.data;
        if (user == null) return const LoginScreen();
        return StreamBuilder<AppUser?>(
          key: ValueKey(user.uid),
          stream: s.users.watch(user.uid),
          builder: (context, snap) {
            if (snap.hasError) {
              return _ProfileError(message: snap.error.toString());
            }
            final profile = snap.data;
            // أثناء إنشاء الحساب قد تصل حالة الدخول قبل حفظ وثيقة المستخدم.
            if (profile == null) return const _Splash(showSignOut: true);
            return profile.isPharmacist
                ? PharmacistDashboard(user: profile)
                : HomeScreen(user: profile);
          },
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({this.showSignOut = false});
  final bool showSignOut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WaveBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 130),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.primary),
              if (showSignOut) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: Services.I.auth.signOut,
                  child: const Text('تسجيل الخروج'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: EmptyState(
        icon: Icons.error_outline,
        title: 'تعذر تحميل بيانات الحساب',
        message: message,
        action: OutlinedButton(
          onPressed: Services.I.auth.signOut,
          child: const Text('تسجيل الخروج'),
        ),
      ),
    );
  }
}
