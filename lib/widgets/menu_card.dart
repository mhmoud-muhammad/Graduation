import 'package:material_ui/material_ui.dart';

import '../core/app_theme.dart';

/// بطاقة خيار كبيرة (البحث بالكتابة / بالصورة، بيانات الصيدلية / إدارة الأدوية).
class MenuCard extends StatelessWidget {
  const MenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.tinted = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tinted ? AppColors.skyDeep.withValues(alpha: 0.7) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      shadowColor: AppColors.navy.withValues(alpha: 0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: tinted
                      ? Colors.white.withValues(alpha: 0.6)
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(tinted ? 16 : 29),
                ),
                child: Icon(
                  icon,
                  color: tinted ? AppColors.primary : Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_left,
                color: AppColors.primary,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
