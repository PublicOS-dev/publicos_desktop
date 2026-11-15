import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_mentions/zero_mentions.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// One pickable row in the mention autocomplete panel.
class MentionCandidate {
  const MentionCandidate({
    required this.address,
    required this.display,
    this.contact,
  });

  /// `0x` + 40 hex — becomes the wire token on insert.
  final String address;

  /// Name shown in the row and spliced into the field.
  final String display;

  /// When known locally, drives the avatar; otherwise the icon falls back to
  /// its address rendering.
  final Contact? contact;
}

/// Mention autocomplete panel — rendered directly ABOVE the composer input:
/// a left-aligned column of options, mini avatar + display name with the
/// shortened address in a smaller dim font. Scrolls past 5 rows.
class MentionSuggestionsPanel extends StatelessWidget {
  const MentionSuggestionsPanel({
    super.key,
    required this.candidates,
    required this.onPick,
  });

  final List<MentionCandidate> candidates;
  final ValueChanged<MentionCandidate> onPick;

  static const double _rowHeight = 44;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return Container(
      constraints: const BoxConstraints(maxHeight: _rowHeight * 5),
      decoration: BoxDecoration(
        color: tokens.surfaceDeep,
        border: Border(
          top: BorderSide(color: tokens.borderSubtle, width: 0.5),
          bottom: BorderSide(color: tokens.borderSubtle, width: 0.5),
        ),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: candidates.length,
        itemBuilder: (context, i) {
          final c = candidates[i];
          return InkWell(
            onTap: () => onPick(c),
            child: SizedBox(
              height: _rowHeight,
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  if (c.contact != null)
                    GlassContactIcon(contact: c.contact!, size: 24)
                  else
                    GlassContactIcon(address: c.address, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            c.display,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.starkWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          truncatedAddress(c.address),
                          style: TextStyle(
                            color: tokens.textDim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
