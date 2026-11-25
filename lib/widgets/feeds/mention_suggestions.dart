import 'dart:async';

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

/// The chain half of a mention list (so a short account name can be
/// mentioned even when its holder is not a saved contact). The
/// text after the `@` is asked to the chain as an exact account name; the
/// holder becomes the first row. Shown only: nothing is saved.
///
/// One per composer. [resultFor] is safe to call from build: it starts a
/// read only when the text changes, and [onChanged] fires when an answer
/// for the current text lands.
class MentionChainLookup {
  MentionChainLookup(this.onChanged);

  final VoidCallback onChanged;

  String _query = '';
  int _resolveGeneration = 0;
  Timer? _debounce;
  MentionCandidate? _searchResult;
  bool _disposed = false;

  /// [query] is the open trigger's text, null when no `@` run is open.
  MentionCandidate? resultFor(String? query) {
    final raw = (query ?? '').trim();
    final q = raw.toLowerCase();
    if (q == _query) return _searchResult;
    _debounce?.cancel();
    _resolveGeneration++;
    _query = q;
    _searchResult = null;
    // An address is not a name: the local list matches it by prefix.
    if (q.isEmpty || q.startsWith('0x')) return null;
    final gen = _resolveGeneration;
    _debounce =
        Timer(const Duration(milliseconds: 350), () => _resolve(raw, gen));
    return null;
  }

  Future<void> _resolve(String name, int gen) async {
    MentionCandidate? hit;
    try {
      final addr =
          await PublicOSContacts.getPublicosAddressByPublicosDisplayName(name);
      if (addr != null) {
        Contact? c;
        try {
          c = await PublicOSContacts.fetchContact(addr);
        } catch (_) {}
        hit = MentionCandidate(
          address: addr.eip55With0x,
          display: (c != null && c.displayName.isNotEmpty) ? c.displayName : name,
          contact: c,
        );
      }
    } catch (_) {}
    if (_disposed || gen != _resolveGeneration || hit == null) return;
    _searchResult = hit;
    onChanged();
  }

  void dispose() {
    _disposed = true;
    _debounce?.cancel();
  }
}

/// Order a mention list: the account the chain says holds the typed name
/// first, then local rows whose name IS the text, then the ones that only
/// contain it; cut to [cap]. Pass every local match, uncut, so an exact
/// name is never lost to the cap.
List<MentionCandidate> rankMentionCandidates(
  List<MentionCandidate> found,
  String query,
  MentionCandidate? chainHit, {
  int cap = 8,
}) {
  final q = query.trim().toLowerCase();
  final chainAddr = chainHit?.address.toLowerCase();
  MentionCandidate? first = chainHit;
  final exact = <MentionCandidate>[];
  final rest = <MentionCandidate>[];
  for (final c in found) {
    if (chainAddr != null && c.address.toLowerCase() == chainAddr) {
      first = c; // the local row carries the saved contact
      continue;
    }
    (q.isNotEmpty && c.display.toLowerCase() == q ? exact : rest).add(c);
  }
  return [if (first != null) first, ...exact, ...rest].take(cap).toList();
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
