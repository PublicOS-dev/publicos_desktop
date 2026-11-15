import 'package:flutter/material.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Shared glass-themed expiration picker used by channel moderation
/// (poster + whitelist `expires_at`), and the per-post comment rules sheet
/// (rule `expires_at`).
///
/// Nullable by design — `null` means "no expiration". The row shows
/// "No expiration" in that state and flips to a date string + a clear icon
/// once a value is set. Tapping the row opens the native Material date
/// picker; the chosen date is snapped to end-of-day so `expires_at` is
/// inclusive of the selected day.
class ExpirationPickerField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String label;
  final String emptyText;

  const ExpirationPickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'EXPIRES',
    this.emptyText = 'No expiration',
  });

  Future<void> _pick(BuildContext context) async {
    final tokens = GlassTokens.of(context);
    final now = DateTime.now();
    final initial = value ?? now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: tokens.starkWhite,
              onPrimary: tokens.background,
              surface: tokens.surfaceDeep,
              onSurface: tokens.starkWhite,
            ),
            dialogTheme: DialogThemeData(backgroundColor: tokens.surfaceDeep),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onChanged(
        DateTime(picked.year, picked.month, picked.day, 23, 59, 59),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: tokens.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Material(
          color: tokens.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: tokens.borderSubtle, width: 1),
          ),
          child: InkWell(
            onTap: () => _pick(context),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Icon(
                    hasValue
                        ? Icons.schedule_rounded
                        : Icons.all_inclusive_rounded,
                    size: 16,
                    color: hasValue ? tokens.starkWhite : tokens.textDim,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasValue ? _formatDate(value!) : emptyText,
                      style: TextStyle(
                        color: hasValue ? tokens.starkWhite : tokens.textDim,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (hasValue)
                    InkResponse(
                      onTap: () => onChanged(null),
                      radius: 18,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: tokens.textDim,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.keyboard_arrow_right_rounded,
                      size: 18,
                      color: tokens.textDim,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

/// Compact inline chip used on list rows to surface an existing expiration
/// (when the user set one). Renders as e.g. `exp Apr 20, 2026`.
class ExpirationChip extends StatelessWidget {
  final DateTime value;
  final String prefix;
  const ExpirationChip({
    super.key,
    required this.value,
    this.prefix = 'until ',
  });

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.borderSubtle, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 10,
            color: tokens.textDim,
          ),
          const SizedBox(width: 4),
          Text(
            '$prefix${ExpirationPickerField._formatDate(value)}',
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
