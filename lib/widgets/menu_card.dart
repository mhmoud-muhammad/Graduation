import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// بطاقة خيار كبيرة.
/// - العادية (البحث بالكتابة/بالصورة): بيضاء مع دائرة فيروزية للأيقونة.
/// - [tinted] (لوحة الصيدلي): زرقاء فاتحة مع أيقونة فيروزية.
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
    final radius = BorderRadius.circular(tinted ? 22 : 24);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: tinted ? 0.18 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: tinted ? AppColors.dashCard : Colors.white,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 18,
              vertical: tinted ? 26 : 22,
            ),
            child: Row(
              children: [
                if (tinted)
                  Icon(icon, color: AppColors.header, size: 46)
                else
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF3CC2C0), Color(0xFF15A9A6)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 34),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          title,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: tinted ? 22 : 23,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                          ),
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
                Icon(
                  Icons.chevron_right,
                  color: tinted ? AppColors.navySoft : AppColors.header,
                  size: 34,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
