import 'package:flutter/material.dart';
import 'package:habitos_app/config/config.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isHorizontal;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.size = 64,
    this.showText = true,
    this.isHorizontal = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final logoIcon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary,
            AppTheme.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.favorite_rounded,
              size: size * 0.52,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            Icon(
              Icons.bolt_rounded,
              size: size * 0.45,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );

    if (!showText) return logoIcon;

    final textColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isHorizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            text: 'Vital',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : AppTheme.textPrimaryLight,
            ),
            children: [
              TextSpan(
                text: 'Habit',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: (size * 0.2).clamp(11.0, 14.0),
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );

    if (isHorizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          logoIcon,
          SizedBox(width: size * 0.25),
          textColumn,
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoIcon,
        SizedBox(height: size * 0.2),
        textColumn,
      ],
    );
  }
}
