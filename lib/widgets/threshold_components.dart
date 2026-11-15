import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_desktop/theme/theme_provider.dart';
import 'package:publicos_desktop/widgets/horizontal_wheel.dart';

/// Threshold Design System Components
///
/// "Threshold Architecture" - A design language for PublicOS that creates
/// dignified, civic-inspired interfaces. Like entering a public library
/// or municipal building, these components convey purpose and respect.

/// Consistent max content width for larger screens
const double kThresholdMaxContentWidth = 600.0;

/// Standard horizontal padding
const double kThresholdHorizontalPadding = 16.0;

/// Standard chip height
const double kPhigitalChipHeight = 56.0;

/// A filter/action chip with Phigital styling
class PhigitalChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? emoji;
  final Color? color;
  final bool isSelected;
  final bool showCheckmark;
  final int? count;
  final VoidCallback? onTap;
  final bool isAction;

  const PhigitalChip({
    super.key,
    required this.label,
    this.icon,
    this.emoji,
    this.color,
    this.isSelected = false,
    this.showCheckmark = true,
    this.count,
    this.onTap,
    this.isAction = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chipColor = color ?? theme.colorScheme.primary;
    final isActive = isSelected && !isAction;

    // Phigital colors — selected state only tints the border
    final bgColor = PhigitalStyle.cardBackground(isDark);
    final borderColor = isActive
        ? chipColor.withValues(alpha: 0.4)
        : PhigitalStyle.subtleBorder(isDark);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: PhigitalStyle.smallShadow(isDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 14), overflow: TextOverflow.visible,),
              const SizedBox(width: 6),
            ] else if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color:
                    isActive ? chipColor : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive ? chipColor : theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.visible,
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: PhigitalStyle.subtleTint(isDark),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? chipColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            if (showCheckmark && isActive && !isAction) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_rounded, size: 16, color: chipColor),
            ],
          ],
        ),
      ),
    );
  }
}

/// A horizontal scrollable chip bar
class PhigitalChipBar extends StatelessWidget {
  final List<Widget> chips;
  final EdgeInsets? padding;

  const PhigitalChipBar({
    super.key,
    required this.chips,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kPhigitalChipHeight,
      child: HorizontalWheel(child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.hardEdge,
        padding: padding ??
            const EdgeInsets.only(
              left: kThresholdHorizontalPadding,
              right: kThresholdHorizontalPadding,
              bottom: 10,
            ),
        children: [
          for (int i = 0; i < chips.length; i++) ...[
            chips[i],
            if (i < chips.length - 1) const SizedBox(width: 8),
          ],
        ],
      )),
    );
  }
}

/// Empty state with consistent Threshold styling
class ThresholdEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Widget? action;

  const ThresholdEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                size: 32,
                color: color.withValues(alpha:0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Section header with optional action
class ThresholdSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets? padding;

  const ThresholdSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: kThresholdHorizontalPadding,
            vertical: 12,
          ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Card with consistent Threshold styling
class ThresholdCard extends StatelessWidget {
  final Widget child;
  final Color? accentColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final bool showAccentBorder;

  const ThresholdCard({
    super.key,
    required this.child,
    this.accentColor,
    this.padding,
    this.margin,
    this.onTap,
    this.showAccentBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding:
          margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: showAccentBorder && accentColor != null
                  ? accentColor!.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.12),
              width: showAccentBorder ? 1.5 : 1,
            ),
            boxShadow: PhigitalStyle.smallShadow(
              theme.brightness == Brightness.dark,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A small inline action button
class ThresholdActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final Color? color;
  final bool isDestructive;

  const ThresholdActionButton({
    super.key,
    required this.icon,
    this.label,
    this.onTap,
    this.color,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = isDestructive
        ? theme.colorScheme.error
        : (color ?? theme.colorScheme.onSurfaceVariant);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: buttonColor.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: buttonColor),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: buttonColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Responsive container that centers content on larger screens
class ThresholdContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsets? padding;

  const ThresholdContainer({
    super.key,
    required this.child,
    this.maxWidth = kThresholdMaxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child:
            padding != null ? Padding(padding: padding!, child: child) : child,
      ),
    );
  }
}

/// Badge indicator (for unread counts, status, etc.)
class ThresholdBadge extends StatelessWidget {
  final String? text;
  final Color? color;
  final bool isDot;

  const ThresholdBadge({
    super.key,
    this.text,
    this.color,
    this.isDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = color ?? theme.colorScheme.primary;

    if (isDot) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: badgeColor,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text ?? '',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
