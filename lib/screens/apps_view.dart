import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:zero_cached_image/zero_cached_image.dart';

import 'package:publicos_desktop/widgets/apps/sheets/app_profile_sheet.dart';
import 'package:publicos_desktop/widgets/apps/sheets/register_app_sheet.dart';
import 'package:publicos_desktop/widgets/explorer_chip.dart';
import 'package:publicos_desktop/widgets/glass_context_menu.dart';
import 'package:publicos_desktop/widgets/grid_settings_sheet.dart';
import 'package:publicos_desktop/l10n/l10n_ext.dart';
import 'package:publicos_desktop/router_helpers.dart';
import 'package:publicos_desktop/theme/glass_tokens.dart';

/// **Port from publicos_client** (`lib/pages/explorer_views/apps_view.dart`)
/// — imports repointed, body verbatim except the DELTA-marked lines.
/// Desktop hosts it inside the Apps big dialog
/// (`widgets/apps_dialog.dart`, opened from the rail's pinned Apps button);
/// opening an app goes through `AppNav.toApp`, whose desktop shim lands the
/// Contacts pane on the owner's profile at that app's tab, like the client's
/// route does. Keep it diffable against the client.
/// ⚠ Do NOT `dart format` this file: the client's is not
/// formatter-clean, and formatting it costs ~260 lines of spurious diff.
class AppsView extends StatefulWidget {
  /// Delegates system-app tile taps to the parent (Explorer) which owns
  /// the `_openSystemApp(String appId)` switch. App IDs: 'treasury',
  /// 'account', 'social_graph', 'settings', 'nodes'.
  final void Function(String appId)? onOpenSystemApp;

  const AppsView({super.key, this.onOpenSystemApp});

  @override
  State<AppsView> createState() => _AppsViewState();
}

enum AppsFilter { bookmarked, myApps, all }

class _AppsViewState extends State<AppsView> {
  bool _isLoading = true;
  List<AppBookmark> _bookmarkedApps = [];
  List<AppBookmark> _myApps = [];
  List<AppBookmark> _searchResults = [];
  bool _isSearching = false;
  String _lastSearchQuery = '';
  AppsFilter _selectedFilter = AppsFilter.bookmarked;
  int _gridSize = kDefaultGridSize;
  TextSizeOption _textSize = kDefaultTextSize;

  final TextEditingController _searchCtrl = TextEditingController();

  /// Cache of resolved owner contacts for the details sheet.
  final Map<String, Contact> _ownerContacts = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _loadStoredSettings();
    _loadBookmarkedApps();
    _loadMyApps();
  }

  /// Pull the stored grid + text size from Core. Shared with the Contacts
  /// tab via the same `explorer_grid_size` / `explorer_text_size` keys that
  /// publicos_client uses. Silent no-op pre-auth.
  Future<void> _loadStoredSettings() async {
    final results = await Future.wait([
      loadStoredGridSize(),
      loadStoredTextSize(),
    ]);
    if (!mounted) return;
    setState(() {
      final grid = results[0] as int?;
      final text = results[1] as TextSizeOption?;
      if (grid != null) _gridSize = grid;
      if (text != null) _textSize = text;
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_selectedFilter == AppsFilter.all) {
      _performSearch(_searchCtrl.text);
    } else {
      setState(() {}); // refresh local filter
    }
  }

  String get _query => _searchCtrl.text;

  // ---------------------------------------------------------------------------
  // Core calls — verbatim from publicos_client apps_view.dart
  // ---------------------------------------------------------------------------

  /// Resolves owner contact for an app (cached, non-blocking).
  /// Local DB first; only hits chain if the contact has never been saved.
  Future<void> _resolveOwnerContact(AppBookmark app) async {
    final addressKey = app.ownerAccountAddress.eip55With0x.toLowerCase();
    if (_ownerContacts.containsKey(addressKey)) return;

    try {
      final local = await PublicOSContacts.getContact(app.ownerAccountAddress);
      if (local != null) {
        if (mounted) {
          setState(() {
            _ownerContacts[addressKey] = local;
          });
        }
        return;
      }

      final contact = await PublicOSContacts.fetchContact(
        app.ownerAccountAddress,
      );
      if (mounted) {
        setState(() {
          _ownerContacts[addressKey] = contact;
        });
      }
    } catch (_) {}
  }

  Contact? _getOwnerContact(AppBookmark app) {
    final addressKey = app.ownerAccountAddress.eip55With0x.toLowerCase();
    return _ownerContacts[addressKey];
  }

  Future<void> _loadBookmarkedApps({bool forceChainRefresh = false}) async {
    try {
      // Step 1: Load from cache first (instant display)
      final apps = await PublicOSAppRegistry.getBookmarkedApps();
      if (mounted) {
        setState(() {
          _bookmarkedApps = apps;
        });
      }

      // Step 2: Refresh bookmarks against chain.
      // forceChainRefresh bypasses the 24h staleness window (pull-to-refresh).
      final refreshedCount = await PublicOSAppRegistry.refreshStaleBookmarks(
        force: forceChainRefresh,
      );

      // Step 3: If any apps were refreshed, reload the list.
      if (refreshedCount > 0 && mounted) {
        final updatedApps = await PublicOSAppRegistry.getBookmarkedApps();
        if (mounted) {
          setState(() {
            _bookmarkedApps = updatedApps;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _bookmarkedApps = [];
        });
      }
    }
  }

  /// Cache-first. The chain is consulted when the cache is empty, or when the
  /// caller asks (pull-to-refresh). Without the second door an owned-but-not-
  /// bookmarked app drifts forever: bookmarks heal on a 24 h TTL, "my apps"
  /// would never re-sync once the cache had anything in it.
  Future<void> _loadMyApps({bool forceChainRefresh = false}) async {
    try {
      final cachedApps = await PublicOSAppRegistry.getCachedMyApps();
      if (mounted) {
        setState(() {
          _myApps = cachedApps;
          _isLoading = false;
        });
      }

      if (cachedApps.isEmpty || forceChainRefresh) {
        final freshApps =
            await PublicOSAppRegistry.syncMyAppsWithBlockchain();
        if (mounted && freshApps != null) {
          setState(() {
            _myApps = freshApps;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([
      _loadBookmarkedApps(forceChainRefresh: true),
      _loadMyApps(forceChainRefresh: true),
    ]);

    if (_selectedFilter == AppsFilter.all && _query.trim().isNotEmpty) {
      await _performSearch(_query);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Global on-chain app search.
  Future<void> _performSearch(String query) async {
    final trimmedQuery = query.trim();

    if (trimmedQuery.length < 2) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _lastSearchQuery = '';
        });
      }
      return;
    }

    if (trimmedQuery == _lastSearchQuery) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results =
          await PublicOSAppRegistry.searchAppsWithDetails(trimmedQuery);

      if (mounted) {
        setState(() {
          _searchResults = results ?? [];
          _isSearching = false;
          _lastSearchQuery = trimmedQuery;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Sheet launchers
  // ---------------------------------------------------------------------------

  void _openRegisterSheet() {
    showRegisterAppSheet(
      context,
      onSuccess: () {
        _refreshData();
        setState(() {
          _selectedFilter = AppsFilter.myApps;
        });
      },
    );
  }

  void _openEditSheet(AppBookmark app) {
    showRegisterAppSheet(
      context,
      existingApp: app,
      onSuccess: _refreshData,
    );
  }

  // DELTA (desktop): right-click on a tile. Long-press (the client's details
  // gesture) is a touch idiom, and without this menu the dialog has no way
  // to drop a bookmark short of opening the details sheet — same shape
  // as the rail history's "Remove from history". Details stays reachable
  // from the same menu so nothing the long-press offered is lost.
  void _showAppMenu(AppBookmark app, Offset position) {
    final isBookmarked = _bookmarkedApps.any(
      (b) =>
          b.appName == app.appName &&
          b.ownerAccountAddress.eip55With0x.toLowerCase() ==
              app.ownerAccountAddress.eip55With0x.toLowerCase(),
    );
    GlassContextMenu.show(
      context,
      position: position,
      items: [
        GlassContextMenuItem(
          icon: Icons.info_outline_rounded,
          label: 'Details',
          onTap: () => _showAppDetails(app),
        ),
        if (isBookmarked)
          GlassContextMenuItem(
            icon: Icons.bookmark_remove_outlined,
            label: 'Remove bookmark',
            destructive: true,
            onTap: () async {
              final success = await PublicOSAppRegistry.removeBookmark(
                app.appName,
                app.ownerAccountAddress,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        context.l10n.appsViewRemovedSnack(app.displayName)),
                  ),
                );
                _refreshData();
              }
            },
          )
        else
          GlassContextMenuItem(
            icon: Icons.bookmark_add_outlined,
            label: 'Bookmark',
            onTap: () async {
              final success = await PublicOSAppRegistry.bookmarkApp(app);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        context.l10n.appsViewBookmarkedSnack(app.displayName)),
                  ),
                );
                _refreshData();
              }
            },
          ),
      ],
    );
  }

  void _showAppDetails(AppBookmark app) {
    final ownerContact = _getOwnerContact(app);
    final isBookmarked = _bookmarkedApps.any(
      (b) =>
          b.appName == app.appName &&
          b.ownerAccountAddress.eip55With0x.toLowerCase() ==
              app.ownerAccountAddress.eip55With0x.toLowerCase(),
    );
    showAppProfileSheet(
      context,
      app: app,
      ownerContact: ownerContact,
      onEdit: () => _openEditSheet(app),
      onRemoveBookmark: isBookmarked
          ? () async {
              final success = await PublicOSAppRegistry.removeBookmark(
                app.appName,
                app.ownerAccountAddress,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(context.l10n.appsViewRemovedSnack(app.displayName)),
                  ),
                );
                _refreshData();
              }
            }
          : null,
      onAddBookmark: !isBookmarked
          ? () async {
              final success = await PublicOSAppRegistry.bookmarkApp(app);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        context.l10n.appsViewBookmarkedSnack(app.displayName)),
                  ),
                );
                _refreshData();
              }
            }
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Launch stubs — no in-app browser yet, no system-app pages yet.
  // ---------------------------------------------------------------------------

  void _launchApp(AppBookmark app) {
    // An app with no `url` pointer has nothing to open. Registering an app and
    // pointing it somewhere are two separate transactions, so a registered app
    // with no url is a normal intermediate state, not corruption -- and the
    // Browser must never be handed one: a null-check on the missing url is a
    // raw Flutter error, which reads to the user as "I broke the app".
    //
    // Refuse here rather than downstream: opening a shell that then has nothing
    // to show is worse than not opening one, and the message says whose fault
    // it is so nobody goes looking for the mistake in their own account.
    if (app.url == null || app.url!.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.appsViewAppMisconfigured(app.displayName),
            style: const TextStyle(fontFamily: 'SpaceGrotesk'),
          ),
          duration: const Duration(milliseconds: 2600),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    AppNav.toApp(context, app.ownerAccountAddress.eip55With0x,
        appName: app.appName, app: app);
  }

  void _openSystemApp(String label) {
    const labelToId = {
      'Treasury': 'treasury',
      'Account Center': 'account',
      'Social Graph': 'social_graph',
      'Settings': 'settings',
      'Nodes': 'nodes',
    };
    final appId = labelToId[label];
    if (appId == null || widget.onOpenSystemApp == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n
                .appsViewComingSoon(_localizedSystemLabel(context, label)),
            style: const TextStyle(fontFamily: 'SpaceGrotesk'),
          ),
          duration: const Duration(milliseconds: 1800),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    widget.onOpenSystemApp!(appId);
  }

  // ---------------------------------------------------------------------------
  // Derived state
  // ---------------------------------------------------------------------------

  // Memoized filter output.
  List<AppBookmark>? _cachedFiltered;
  AppsFilter? _filteredKeyFilter;
  List<AppBookmark>? _filteredKeyBookmarked;
  List<AppBookmark>? _filteredKeyMyApps;
  List<AppBookmark>? _filteredKeySearchResults;
  String? _filteredKeyQuery;

  List<AppBookmark> get _filteredApps {
    if (_cachedFiltered != null &&
        _filteredKeyFilter == _selectedFilter &&
        identical(_filteredKeyBookmarked, _bookmarkedApps) &&
        identical(_filteredKeyMyApps, _myApps) &&
        identical(_filteredKeySearchResults, _searchResults) &&
        _filteredKeyQuery == _query) {
      return _cachedFiltered!;
    }

    List<AppBookmark> result;
    List<AppBookmark> baseList;
    switch (_selectedFilter) {
      case AppsFilter.bookmarked:
        baseList = _bookmarkedApps;
        break;
      case AppsFilter.myApps:
        baseList = _myApps;
        break;
      case AppsFilter.all:
        result = _searchResults;
        baseList = result;
        _cachedFiltered = result;
        _filteredKeyFilter = _selectedFilter;
        _filteredKeyBookmarked = _bookmarkedApps;
        _filteredKeyMyApps = _myApps;
        _filteredKeySearchResults = _searchResults;
        _filteredKeyQuery = _query;
        return result;
    }

    final trimmedQuery = _query.trim();
    if (trimmedQuery.isEmpty) {
      result = baseList;
    } else {
      final query = trimmedQuery.toLowerCase();
      result = baseList.where((app) {
        return app.displayName.toLowerCase().contains(query) ||
            app.appName.toLowerCase().contains(query) ||
            (app.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    _cachedFiltered = result;
    _filteredKeyFilter = _selectedFilter;
    _filteredKeyBookmarked = _bookmarkedApps;
    _filteredKeyMyApps = _myApps;
    _filteredKeySearchResults = _searchResults;
    _filteredKeyQuery = _query;
    return result;
  }

  void _openSettings() {
    showGridSettingsSheet(
      context,
      currentGridSize: _gridSize,
      currentTextSize: _textSize,
      onGridSizeChanged: (v) => setState(() => _gridSize = v),
      onTextSizeChanged: (v) => setState(() => _textSize = v),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: tokens.starkWhite,
      backgroundColor: tokens.surfaceElevated,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // RepaintBoundary on header slivers.
          SliverToBoxAdapter(
            child: RepaintBoundary(
              child: _SearchField(controller: _searchCtrl, tokens: tokens),
            ),
          ),
          SliverToBoxAdapter(
            child: RepaintBoundary(
              child: _AppsChipBar(
                tokens: tokens,
                selected: _selectedFilter,
                bookmarkedCount: _bookmarkedApps.length,
                myAppsCount: _myApps.length,
                allCount: _selectedFilter == AppsFilter.all &&
                        _searchResults.isNotEmpty
                    ? _searchResults.length
                    : null,
                onSelectBookmarked: () => setState(
                  () => _selectedFilter = AppsFilter.bookmarked,
                ),
                onSelectMyApps: () => setState(
                  () => _selectedFilter = AppsFilter.myApps,
                ),
                onSelectAll: () {
                  setState(() => _selectedFilter = AppsFilter.all);
                  if (_query.trim().isNotEmpty) _performSearch(_query);
                },
                onRegister: _openRegisterSheet,
                onSettings: _openSettings,
              ),
            ),
          ),
          ..._buildBodySlivers(tokens),
        ],
      ),
    );
  }

  List<Widget> _buildBodySlivers(GlassTokens tokens) {
    if (_isLoading && _bookmarkedApps.isEmpty && _myApps.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              color: tokens.starkWhite,
              strokeWidth: 2,
            ),
          ),
        ),
      ];
    }

    if (_selectedFilter == AppsFilter.all) {
      return _buildAllFilterSlivers(tokens);
    }

    // Bookmarked / My Apps — system apps grid first, then filtered apps.
    final filtered = _filteredApps;
    final systemCount = _systemApps.length;
    final totalItems = filtered.length + systemCount;

    if (totalItems == 0) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            tokens: tokens,
            filter: _selectedFilter,
            hasQuery: _query.trim().isNotEmpty,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        sliver: SliverLayoutBuilder(
          builder: (context, sliverConstraints) {
            final geom = GridGeom.forWidth(
              sliverConstraints.crossAxisExtent,
              _gridSize,
              _textSize,
            );
            return SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridSize,
                mainAxisSpacing: GridGeom.gap,
                crossAxisSpacing: GridGeom.gap,
                mainAxisExtent: geom.tileH,
              ),
              itemCount: totalItems,
              itemBuilder: (context, index) {
                if (index < systemCount) {
                  final sys = _systemApps[index];
                  return _SystemAppTile(
                    key: ValueKey('sys:${sys.label}'),
                    tokens: tokens,
                    label: _localizedSystemLabel(context, sys.label),
                    icon: sys.icon,
                    asset: sys.asset,
                    geom: geom,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _openSystemApp(sys.label);
                    },
                  );
                }
                final app = filtered[index - systemCount];
                _resolveOwnerContact(app);
                return _AppTile(
                  key: ValueKey(
                    '${app.appName}:${app.ownerAccountAddress.eip55With0x}',
                  ),
                  tokens: tokens,
                  app: app,
                  geom: geom,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _launchApp(app);
                  },
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    _showAppDetails(app);
                  },
                  // DELTA (desktop): right-click = the tile's quick menu.
                  onSecondaryTapDown: (pos) => _showAppMenu(app, pos),
                );
              },
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildAllFilterSlivers(GlassTokens tokens) {
    final hasQuery = _query.trim().length >= 2;

    if (!hasQuery) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _SearchPrompt(tokens: tokens),
        ),
      ];
    }

    if (_isSearching) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  color: tokens.starkWhite,
                  strokeWidth: 2,
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.appsViewSearching,
                  style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                    color: tokens.textDim,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (_searchResults.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            tokens: tokens,
            filter: AppsFilter.all,
            hasQuery: true,
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        sliver: SliverLayoutBuilder(
          builder: (context, sliverConstraints) {
            final geom = GridGeom.forWidth(
              sliverConstraints.crossAxisExtent,
              _gridSize,
              _textSize,
            );
            return SliverGrid.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridSize,
                mainAxisSpacing: GridGeom.gap,
                crossAxisSpacing: GridGeom.gap,
                mainAxisExtent: geom.tileH,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final app = _searchResults[index];
                _resolveOwnerContact(app);
                return _AppTile(
                  key: ValueKey(
                    '${app.appName}:${app.ownerAccountAddress.eip55With0x}',
                  ),
                  tokens: tokens,
                  app: app,
                  geom: geom,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _launchApp(app);
                  },
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    _showAppDetails(app);
                  },
                  // DELTA (desktop): right-click = the tile's quick menu.
                  onSecondaryTapDown: (pos) => _showAppMenu(app, pos),
                );
              },
            );
          },
        ),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// System apps — 6 entries. Feeds / Contacts / Messages / Wallet are omitted
// because they already live in the bottom nav as dedicated tabs.
// ---------------------------------------------------------------------------

class _SystemAppEntry {
  final String label;
  final IconData icon;

  /// Full-bleed artwork drawn edge-to-edge in the icon box instead of the
  /// static [icon]. The artwork carries its own background and framing, so the
  /// tile drops its surface fill and accent border. [icon] stays as the
  /// decode-failure fallback.
  final String? asset;

  const _SystemAppEntry(this.label, this.icon, {this.asset});
}

// DELTA (desktop): a subset of the client's five system tiles. Treasury and
// Social Graph are apps here, not rail destinations: they open their full
// panes and land in the rail history (`utils/app_history.dart` `kSystemApps`,
// wired by `apps_dialog`). Account Center + Settings are rail-footer rows, so
// they stay out. The tile widget and its launch switch are verbatim.
const List<_SystemAppEntry> _systemApps = [
  _SystemAppEntry('Treasury', Icons.account_balance_rounded,
      asset: 'assets/system_apps/treasury.png'),
  _SystemAppEntry('Social Graph', Icons.account_tree_rounded,
      asset: 'assets/system_apps/social_graph.png'),
  // Nodes lives inside Services (the 'Treasury' entry) — no tile.
];

/// Maps the const English system-app [label] — which doubles as the
/// `labelToId` lookup key and ValueKey identity — to its localized display
/// string. Identity stays English; only the rendered text is localized.
String _localizedSystemLabel(BuildContext context, String label) {
  final l10n = context.l10n;
  switch (label) {
    case 'Treasury':
      return l10n.appsViewSystemTreasury;
    case 'Account Center':
      return l10n.appsViewSystemAccountCenter;
    case 'Social Graph':
      return l10n.appsViewSystemSocialGraph;
    case 'Settings':
      return l10n.appsViewSystemSettings;
    case 'Nodes':
      return l10n.appsViewSystemNodes;
    default:
      return label;
  }
}

// ---------------------------------------------------------------------------
// Search field
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final GlassTokens tokens;

  const _SearchField({required this.controller, required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          style: TextStyle(
              fontFamily: 'SpaceGrotesk',
            color: tokens.starkWhite,
            fontSize: 14,
          ),
          cursorColor: tokens.starkWhite,
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 18,
              color: tokens.textDim,
            ),
            suffixIcon: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: tokens.textDim,
                  ),
                  splashRadius: 16,
                  onPressed: controller.clear,
                );
              },
            ),
            hintText: context.l10n.appsViewSearchHint,
            hintStyle: TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: tokens.textDim,
              fontSize: 13,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chip bar
// ---------------------------------------------------------------------------

class _AppsChipBar extends StatelessWidget {
  final GlassTokens tokens;
  final AppsFilter selected;
  final int bookmarkedCount;
  final int myAppsCount;
  final int? allCount;
  final VoidCallback onSelectBookmarked;
  final VoidCallback onSelectMyApps;
  final VoidCallback onSelectAll;
  final VoidCallback onRegister;
  final VoidCallback onSettings;

  const _AppsChipBar({
    required this.tokens,
    required this.selected,
    required this.bookmarkedCount,
    required this.myAppsCount,
    required this.allCount,
    required this.onSelectBookmarked,
    required this.onSelectMyApps,
    required this.onSelectAll,
    required this.onRegister,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return ExplorerChipBar(
      children: [
        ExplorerChip(
          label: context.l10n.appsViewChipBookmarked,
          icon: Icons.bookmark_rounded,
          count: bookmarkedCount,
          active: selected == AppsFilter.bookmarked,
          onTap: onSelectBookmarked,
        ),
        const SizedBox(width: 8),
        ExplorerChip(
          label: context.l10n.appsViewChipMyApps,
          icon: Icons.app_registration_rounded,
          count: myAppsCount,
          active: selected == AppsFilter.myApps,
          onTap: onSelectMyApps,
        ),
        const SizedBox(width: 8),
        ExplorerChip(
          label: context.l10n.appsViewChipAll,
          icon: Icons.search_rounded,
          count: allCount,
          active: selected == AppsFilter.all,
          onTap: onSelectAll,
        ),
        const SizedBox(width: 16),
        ExplorerChip(
          label: context.l10n.appsViewChipRegister,
          icon: Icons.add_rounded,
          active: false,
          accentColor: tokens.connectedAccent,
          onTap: onRegister,
        ),
        const SizedBox(width: 16),
        ExplorerChip(
          label: context.l10n.appsViewChipSettings,
          icon: Icons.tune_rounded,
          active: false,
          onTap: onSettings,
        ),
      ],
    );
  }
}


// ---------------------------------------------------------------------------
// App tile (bookmarked / my apps / search results)
// ---------------------------------------------------------------------------

/// Keep-alive so off-screen tiles aren't disposed and re-decoded; OverflowBox
/// so descenders paint into the row gap.
class _AppTile extends StatefulWidget {
  final GlassTokens tokens;
  final AppBookmark app;
  final GridGeom geom;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  /// DELTA (desktop): right-click → the tile's quick menu, at the pointer.
  final ValueChanged<Offset>? onSecondaryTapDown;

  const _AppTile({
    super.key,
    required this.tokens,
    required this.app,
    required this.geom,
    required this.onTap,
    required this.onLongPress,
    this.onSecondaryTapDown,
  });

  @override
  State<_AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<_AppTile>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // DELTA (desktop): click cursor — a GestureDetector alone never changes
    // it. The client's build body is `_tile`, untouched.
    return MouseRegion(cursor: SystemMouseCursors.click, child: _tile(context));
  }

  Widget _tile(BuildContext context) {
    final geom = widget.geom;
    final cornerRadius = geom.iconSize * 0.22;
    final hasIcon =
        widget.app.icon != null && widget.app.icon!.isNotEmpty;
    final fallbackIcon = Icon(
      Icons.apps_rounded,
      size: geom.iconSize * 0.5,
      color: widget.tokens.textDim,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      // DELTA (desktop): right-click → the quick menu.
      onSecondaryTapDown: (d) =>
          widget.onSecondaryTapDown?.call(d.globalPosition),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RepaintBoundary(
            child: Container(
              width: geom.iconSize,
              height: geom.iconSize,
              decoration: BoxDecoration(
                color: widget.tokens.glassFill,
                borderRadius: BorderRadius.circular(cornerRadius),
                border: Border.all(
                  color: widget.tokens.borderSubtle,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(cornerRadius - 1),
                child: hasIcon
                    ? ZeroCachedImage(
                        imageUrl: widget.app.icon!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => fallbackIcon,
                      )
                    : fallbackIcon,
              ),
            ),
          ),
          const SizedBox(height: GridGeom.iconToText),
          SizedBox(
            height: geom.textBlockH,
            child: OverflowBox(
              minHeight: 0,
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: Text(
                widget.app.displayName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: widget.tokens.starkWhite,
                  fontSize: geom.fontSize,
                  fontWeight: FontWeight.w600,
                  height: GridGeom.lineHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// System app tile (stub — tap shows snackbar until pages land)
// ---------------------------------------------------------------------------

/// System tiles never image-load so keep-alive is mostly belt-and-suspenders
/// here, but matching [_AppTile] keeps the grid's perf shape uniform across
/// both tile types.
class _SystemAppTile extends StatefulWidget {
  final GlassTokens tokens;
  final String label;
  final IconData icon;
  final String? asset;
  final GridGeom geom;
  final VoidCallback onTap;

  const _SystemAppTile({
    super.key,
    required this.tokens,
    required this.label,
    required this.icon,
    required this.geom,
    required this.onTap,
    this.asset,
  });

  @override
  State<_SystemAppTile> createState() => _SystemAppTileState();
}

class _SystemAppTileState extends State<_SystemAppTile>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  /// An entry with an [_SystemAppEntry.asset] paints that papercraft artwork
  /// edge-to-edge, since the art supplies its own background and frame.
  /// Everything else keeps the static glyph on the bordered surface tile.
  Widget _iconBox(BuildContext context, GridGeom geom, double cornerRadius) {
    final glyph = Icon(
      widget.icon,
      size: geom.iconSize * 0.5,
      color: widget.tokens.connectedAccent,
    );

    final asset = widget.asset;
    if (asset != null) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius),
          child: Image.asset(
            asset,
            width: geom.iconSize,
            height: geom.iconSize,
            fit: BoxFit.cover,
            cacheWidth: (geom.iconSize * dpr).round(),
            errorBuilder: (_, __, ___) => Container(
              width: geom.iconSize,
              height: geom.iconSize,
              color: widget.tokens.surfaceElevated,
              child: glyph,
            ),
          ),
        ),
      );
    }

    return Container(
      width: geom.iconSize,
      height: geom.iconSize,
      decoration: BoxDecoration(
        color: widget.tokens.surfaceElevated,
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(
          color: widget.tokens.connectedAccent.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: glyph,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final geom = widget.geom;
    final cornerRadius = geom.iconSize * 0.22;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _iconBox(context, geom, cornerRadius),
          const SizedBox(height: GridGeom.iconToText),
          SizedBox(
            height: geom.textBlockH,
            child: OverflowBox(
              minHeight: 0,
              maxHeight: double.infinity,
              alignment: Alignment.topCenter,
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  color: widget.tokens.starkWhite,
                  fontSize: geom.fontSize,
                  fontWeight: FontWeight.w600,
                  height: GridGeom.lineHeight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty / search-prompt states
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final GlassTokens tokens;
  final AppsFilter filter;
  final bool hasQuery;

  const _EmptyState({
    required this.tokens,
    required this.filter,
    required this.hasQuery,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = _copy(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: tokens.textDim),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String, String) _copy(BuildContext context) {
    final l10n = context.l10n;
    if (hasQuery) {
      return (
        Icons.search_off_rounded,
        l10n.appsViewEmptyNoMatchesTitle,
        l10n.appsViewEmptyTryDifferentTerm,
      );
    }
    switch (filter) {
      case AppsFilter.bookmarked:
        return (
          Icons.bookmark_outline_rounded,
          l10n.appsViewEmptyNoBookmarksTitle,
          l10n.appsViewEmptyNoBookmarksBody,
        );
      case AppsFilter.myApps:
        return (
          Icons.app_registration_rounded,
          l10n.appsViewEmptyNoMyAppsTitle,
          l10n.appsViewEmptyNoMyAppsBody,
        );
      case AppsFilter.all:
        return (
          Icons.search_rounded,
          l10n.appsViewEmptyNoAppsFoundTitle,
          l10n.appsViewEmptyTryDifferentTerm,
        );
    }
  }
}

class _SearchPrompt extends StatelessWidget {
  final GlassTokens tokens;
  const _SearchPrompt({required this.tokens});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: tokens.connectedAccent.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.appsViewSearchPromptTitle,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                color: tokens.starkWhite,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.appsViewSearchPromptBody,
              textAlign: TextAlign.center,
              style: TextStyle(
              fontFamily: 'SpaceGrotesk',
                color: tokens.textDim,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
