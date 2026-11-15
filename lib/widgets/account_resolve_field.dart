import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

const _zeroAddress = '0x0000000000000000000000000000000000000000';

/// Resolve free-form moderation input to an address the feeds server accepts.
///
///   - `0x…` input passes through as-is (outsider signers stay addressable
///     even when no contact matches).
///   - Anything else is treated as a PublicOS username: exact match against
///     local contacts first (displayName / publicosDisplayName), then the
///     on-chain display-name registry.
///
/// Returns null when a name resolves to nothing — callers surface that as
/// "no account found", never submit the raw name.
Future<String?> resolveAccountInput(String input) async {
  final t = input.trim();
  if (t.isEmpty) return null;
  if (t.startsWith('0x')) return t;

  final q = t.toLowerCase();
  try {
    final all = await PublicOSContacts.getStoredContacts();
    for (final c in all) {
      final addr = c.publicosAddress?.eip55With0x;
      if (addr == null || addr.toLowerCase() == _zeroAddress) continue;
      if (c.displayName.toLowerCase() == q ||
          c.publicosDisplayName?.toLowerCase() == q) {
        return addr;
      }
    }
  } catch (_) {}

  try {
    final addr =
        await PublicOSContacts.getPublicosAddressByPublicosDisplayName(t);
    return addr?.eip55With0x;
  } catch (_) {
    return null;
  }
}

/// Moderation-list entry field that accepts a PublicOS username or a raw
/// `0x` address. While typing it searches local contacts (name, publicos
/// name, account / session addresses, inbox IDs) and shows the matches in a
/// panel floating above the field; picking one fills the field with that
/// contact's account address. A pasted address that belongs to a known
/// contact shows the contact row as identity confirmation; an unknown
/// address is simply left as typed (outsider signers).
///
/// The match panel is an [OverlayEntry] anchored to the field via
/// [CompositedTransformFollower] — it takes no layout space, so it never
/// grows the (often non-scrolling) section the field sits in when the
/// keyboard is up. It floats over whatever is above the field instead.
class AccountResolveField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool dense;

  const AccountResolveField({
    super.key,
    required this.controller,
    required this.hint,
    this.dense = false,
  });

  @override
  State<AccountResolveField> createState() => _AccountResolveFieldState();
}

class _AccountResolveFieldState extends State<AccountResolveField> {
  final _focus = FocusNode();
  final _link = LayerLink();
  OverlayEntry? _overlay;

  List<Contact> _all = const [];
  bool _loaded = false;
  bool _loading = false;

  List<Contact> _matches = const [];

  /// Text last written by a panel selection — suppresses re-opening the
  /// panel for the exact value the user just picked.
  String? _committed;

  static const _maxMatches = 5;
  static const _panelMaxHeight = 220.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_recompute);
    _focus.addListener(_recompute);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_recompute);
    _removeOverlay();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _ensureContacts() async {
    if (_loaded || _loading) return;
    _loading = true;
    try {
      final all = await PublicOSContacts.getStoredContacts();
      _all = all.where((c) {
        final addr = c.publicosAddress?.eip55With0x.toLowerCase();
        return addr != null && addr != _zeroAddress;
      }).toList();
      _loaded = true;
    } catch (_) {
      // Panel just stays empty — the field still works as a raw input.
    } finally {
      _loading = false;
    }
    if (mounted) _recompute();
  }

  void _recompute() {
    if (!mounted) return;
    final q = widget.controller.text.trim().toLowerCase();
    if (!_focus.hasFocus || q.isEmpty || q == _committed?.toLowerCase()) {
      _setMatches(const []);
      return;
    }
    if (!_loaded) {
      _ensureContacts();
      return;
    }

    // Same identifier surface as the contacts view search.
    final hits = _all.where((c) {
      if (c.displayName.toLowerCase().contains(q)) return true;
      if (c.publicosDisplayName?.toLowerCase().contains(q) == true) {
        return true;
      }
      if (c.publicosAddress?.eip55With0x.toLowerCase().contains(q) == true) {
        return true;
      }
      final inboxHit = c.registeredInboxIDs
              ?.any((e) => e.inboxId.toLowerCase().contains(q)) ??
          false;
      if (inboxHit) return true;
      return c.sessions
              ?.any((cl) => cl.address.eip55With0x.toLowerCase().contains(q)) ??
          false;
    }).toList()
      ..sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    _setMatches(hits.take(_maxMatches).toList());
  }

  void _setMatches(List<Contact> matches) {
    _matches = matches;
    if (matches.isEmpty) {
      _removeOverlay();
    } else if (_overlay == null) {
      _insertOverlay();
    } else {
      _overlay!.markNeedsBuild();
    }
  }

  void _insertOverlay() {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    _overlay = OverlayEntry(builder: _buildPanel);
    overlay.insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _select(Contact c) {
    final addr = c.publicosAddress?.eip55With0x;
    if (addr == null) return;
    _committed = addr;
    widget.controller.text = addr;
    widget.controller.selection =
        TextSelection.collapsed(offset: addr.length);
    _setMatches(const []);
  }

  Widget _buildPanel(BuildContext overlayContext) {
    final tokens = GlassTokens.of(context);
    final fieldBox = context.findRenderObject() as RenderBox?;
    final width = fieldBox?.size.width ?? 280.0;
    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: _link,
        showWhenUnlinked: false,
        targetAnchor: Alignment.topLeft,
        followerAnchor: Alignment.bottomLeft,
        offset: const Offset(0, -6),
        child: TextFieldTapRegion(
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: _panelMaxHeight),
              decoration: BoxDecoration(
                color: tokens.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66000000),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _matches.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: tokens.borderSubtle,
                  ),
                  itemBuilder: (_, i) => _MatchRow(
                    contact: _matches[i],
                    onTap: () => _select(_matches[i]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final fontSize = widget.dense ? 12.0 : 13.0;
    return CompositedTransformTarget(
      link: _link,
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        maxLines: 1,
        style: TextStyle(
          color: tokens.starkWhite,
          fontSize: fontSize,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: tokens.textDim,
            fontSize: fontSize,
            fontFamily: 'monospace',
          ),
          filled: true,
          fillColor: tokens.surfaceElevated,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: widget.dense ? 10 : 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: tokens.borderSubtle),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: tokens.borderSubtle),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: tokens.borderMedium, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;

  const _MatchRow({required this.contact, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final addr = contact.publicosAddress?.eip55With0x ?? '';
    final short = addr.length > 14
        ? '${addr.substring(0, 8)}…${addr.substring(addr.length - 4)}'
        : addr;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            GlassContactIcon(contact: contact, address: addr, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.starkWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    short,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textDim,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
