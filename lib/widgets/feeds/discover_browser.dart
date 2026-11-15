import 'package:flutter/material.dart';
import 'package:publicos_core/publicos_core.dart';

import 'package:publicos_desktop/widgets/discover_contact_row.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// Discover body for the feeds tab: a directory of PublicOS accounts rendered
/// in the messages-list visual language (banner + avatar + name + capability
/// badges). Brand-new accounts are seeded with a baked set of demo accounts on
/// first boot (see `data/demo_contacts.dart`), so this is never empty; as the
/// user adds their own contacts, those appear here too.
///
/// Loads the local contact store first (instant, like `ContactsView`), then
/// refreshes each entry from chain so avatars / banners / feeds are current.
/// Tapping a row fires that account in the in-app browser.
class DiscoverBrowser extends StatefulWidget {
  /// Retained for API compatibility with `feeds_view`; unused now that Discover
  /// shows contacts rather than followable RSS feeds.
  final VoidCallback? onFeedFollowed;

  const DiscoverBrowser({super.key, this.onFeedFollowed});

  @override
  State<DiscoverBrowser> createState() => _DiscoverBrowserState();
}

class _DiscoverBrowserState extends State<DiscoverBrowser> {
  List<Contact> _contacts = const [];
  bool _loading = true;
  int _refreshGen = 0;

  static const String _zero = '0x0000000000000000000000000000000000000000';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _nameOf(Contact c) =>
      (c.publicosDisplayName ?? c.displayName).toLowerCase();

  /// Load the local contact store, drop the zero address and the current user,
  /// then kick off a background chain refresh.
  Future<void> _load() async {
    final myAddr = PublicOS.myPublicosAddress?.toLowerCase();
    List<Contact> loaded;
    try {
      loaded = await PublicOSContacts.getStoredContacts();
    } catch (_) {
      loaded = const [];
    }
    if (!mounted) return;

    final filtered = loaded.where((c) {
      final addr = c.publicosAddress?.eip55With0x.toLowerCase();
      if (addr == null) return false;
      if (addr == _zero) return false;
      if (myAddr != null && addr == myAddr) return false;
      return true;
    }).toList()
      ..sort((a, b) => _nameOf(a).compareTo(_nameOf(b)));

    setState(() {
      _contacts = filtered;
      _loading = false;
    });

    _refreshFromChain(filtered);
  }

  /// Refresh each contact from chain in small chunks (so avatars / banners /
  /// feed records are current), persisting fresh data and updating rows in
  /// place. Best-effort — failures leave the seeded snapshot in view.
  Future<void> _refreshFromChain(List<Contact> initial) async {
    final gen = ++_refreshGen;
    const chunkSize = 5;
    for (var i = 0; i < initial.length; i += chunkSize) {
      if (gen != _refreshGen || !mounted) return;
      final slice = initial.skip(i).take(chunkSize).toList();
      final results = await Future.wait(slice.map((c) async {
        final addr = c.publicosAddress;
        if (addr == null) return null;
        try {
          final fresh = await PublicOSContacts.fetchContact(addr, requireRecords: true);
          await PublicOSContacts.saveContact(fresh);
          return fresh;
        } catch (_) {
          return null;
        }
      }));

      if (gen != _refreshGen || !mounted) return;
      final updated = List<Contact>.from(_contacts);
      var changed = false;
      for (final fresh in results) {
        if (fresh == null) continue;
        final idx = updated.indexWhere(
          (x) => x.publicosAddress == fresh.publicosAddress,
        );
        if (idx >= 0) {
          updated[idx] = fresh;
          changed = true;
        }
      }
      if (changed) setState(() => _contacts = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    // The local store resolves in a frame or two; render nothing rather than
    // flash a spinner the user shouldn't notice.
    if (_loading && _contacts.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No accounts to discover yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens.textDim, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
      itemCount: _contacts.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) return _header(tokens);
        final c = _contacts[i - 1];
        return DiscoverContactRow(
          contact: c,
          onTap: () => AppNav.toContact(context, c),
        );
      },
    );
  }

  Widget _header(GlassTokens tokens) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover',
            style: TextStyle(
              color: tokens.starkWhite,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'People building on PublicOS. Tap to open an account, then add '
            'their feeds to your lists.',
            style: TextStyle(
              color: tokens.textDim,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
