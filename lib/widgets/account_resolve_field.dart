import 'dart:async';

import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/glass_contact_icon.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
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
/// contact's account address. A typed name is also asked to the chain
/// (exact account name): the account that holds it is the first row, saved
/// contact or not, and a saved contact with exactly that name comes before
/// the ones that only contain it. A pasted address that belongs to a known
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

  // The chain half of the search (picker canon: styling guide, "On-chain
  // identifier resolution in contact pickers").
  String _query = '';
  bool _isSearching = false;
  Contact? _searchResult;
  int _resolveGeneration = 0;
  Timer? _debounce;

  /// Text last written by a panel selection — suppresses re-opening the
  /// panel for the exact value the user just picked.
  String? _committed;

  static const _maxMatches = 5;
  static const _panelMaxHeight = 220.0;
  static const _chainDebounce = Duration(milliseconds: 350);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_recompute);
    _focus.addListener(_recompute);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_recompute);
    _debounce?.cancel();
    _resolveGeneration++;
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
    final raw = widget.controller.text.trim();
    final q = raw.toLowerCase();
    if (!_focus.hasFocus || q.isEmpty || q == _committed?.toLowerCase()) {
      _clearChainSearch();
      _setMatches(const []);
      return;
    }
    if (!_loaded) {
      _ensureContacts();
      return;
    }

    // New text: forget the last chain answer and ask again. An address is
    // not a name, so it stays a local match only.
    if (q != _query) {
      _clearChainSearch();
      _query = q;
      if (!q.startsWith('0x')) {
        _isSearching = true;
        final gen = _resolveGeneration;
        _debounce = Timer(_chainDebounce, () => _resolveOnChain(raw, gen));
      }
    }

    bool exact(Contact c) =>
        c.displayName.toLowerCase() == q ||
        c.publicosDisplayName?.toLowerCase() == q;

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
      ..sort((a, b) {
        // The exact name first: with a cap of five and a short query (a
        // 1-letter name), an alphabetical list would push it out of sight.
        final ea = exact(a), eb = exact(b);
        if (ea != eb) return ea ? -1 : 1;
        return a.displayName
            .toLowerCase()
            .compareTo(b.displayName.toLowerCase());
      });

    // The account the chain says holds this name is the first row.
    final found = _searchResult;
    final foundAddr = found?.publicosAddress?.eip55With0x.toLowerCase();
    if (found != null && foundAddr != null) {
      hits.removeWhere(
          (c) => c.publicosAddress?.eip55With0x.toLowerCase() == foundAddr);
      hits.insert(0, found);
    }

    _setMatches(hits.take(_maxMatches).toList());
  }

  void _clearChainSearch() {
    _debounce?.cancel();
    _debounce = null;
    _resolveGeneration++;
    _query = '';
    _isSearching = false;
    _searchResult = null;
  }

  Future<void> _resolveOnChain(String name, int gen) async {
    Contact? hit;
    try {
      final addr =
          await PublicOSContacts.getPublicosAddressByPublicosDisplayName(name);
      if (addr != null) {
        final lower = addr.eip55With0x.toLowerCase();
        for (final c in _all) {
          if (c.publicosAddress?.eip55With0x.toLowerCase() == lower) {
            hit = c;
            break;
          }
        }
        // Not a saved contact: read it for the row (shown, not saved).
        hit ??= await PublicOSContacts.fetchContact(addr);
      }
    } catch (_) {
      // No row from the chain; the add button still resolves the name.
    }
    if (!mounted || gen != _resolveGeneration) return;
    _isSearching = false;
    _searchResult = hit;
    _recompute();
  }

  void _setMatches(List<Contact> matches) {
    _matches = matches;
    if (matches.isEmpty && !_isSearching) {
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
                  itemCount: _matches.length + (_isSearching ? 1 : 0),
                  separatorBuilder: (_, __) => Divider(
                    height: 0.5,
                    thickness: 0.5,
                    color: tokens.borderSubtle,
                  ),
                  itemBuilder: (_, i) {
                    // While the chain is asked, the first row says so.
                    if (_isSearching && i == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Text(
                          context.l10n.accountCenterSearchingOnChain,
                          style: TextStyle(
                            color: tokens.textDim,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }
                    final c = _matches[_isSearching ? i - 1 : i];
                    return _MatchRow(contact: c, onTap: () => _select(c));
                  },
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
