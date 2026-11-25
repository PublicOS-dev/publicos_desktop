import 'package:flutter/foundation.dart' show debugPrint;
import 'package:publicos_core/publicos_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The social inbox pull. DESKTOP DELTA: the
/// client's `utils/social_notifs.dart` also carries the OS-popup helpers for
/// its background isolates; desktop has no push and no worker, so only the
/// pull is here, run by the shell's 10-min activity sweep into the same
/// `ActivityEvents` table the bell and the list read.

const _cursorPrefix = 'social_inbox_cursor_';

/// Pull the home inbox past the stored cursor, store every item that is new
/// (idempotent on the notification id) and advance the cursor. Returns the
/// NEW rows only. [home] is the account's home SSP base URL; the caller
/// resolves it (`PublicOSSsp.homeForIsolate()`, cache then chain).
Future<List<ActivityEvent>> pullSocialInbox({
  required String account,
  required String home,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final key = '$_cursorPrefix${account.toLowerCase()}';
  if (!prefs.containsKey(key)) {
    return _firstInboxPull(prefs: prefs, key: key, home: home);
  }
  final after = prefs.getInt(key) ?? 0;
  final page = await PublicOSPush.listNotifications(
    after: after,
    limit: 100,
    serverAddress: home,
  );
  final fresh = <ActivityEvent>[];
  for (final n in page.items) {
    final ev = ActivityEvent.social(n.toPushData());
    if (await PublicOSActivity.storeIfNew(ev)) fresh.add(ev);
  }
  if (page.next > after) await prefs.setInt(key, page.next);
  return fresh;
}

/// How many of the newest rows a device's first pull leaves unread.
const firstPullUnread = 3;

/// The FIRST pull of an account's inbox on this device (no cursor stored):
/// the whole inbox goes into the list, but only the newest [firstPullUnread]
/// rows stay unread and only those are returned as new (a new install must
/// not replay every old notification as unread), so they see where they
/// left off. Everything older is
/// stored already read. The rule is here, in the pull, so it holds for
/// whichever caller reaches a new install first.
///
/// The cursor is written only after every page was read and stored: a failed
/// page throws, nothing is marked done, and the next call starts over (the
/// store ignores rows it already has).
Future<List<ActivityEvent>> _firstInboxPull({
  required SharedPreferences prefs,
  required String key,
  required String home,
}) async {
  final all = <ActivityEvent>[];
  var after = 0;
  for (var pages = 0; pages < 200; pages++) {
    final page = await PublicOSPush.listNotifications(
      after: after,
      limit: 100,
      serverAddress: home,
    );
    for (final n in page.items) {
      all.add(ActivityEvent.social(n.toPushData()));
    }
    if (page.items.isEmpty || page.next <= after) break;
    after = page.next;
  }
  all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  final fresh = <ActivityEvent>[];
  for (var i = 0; i < all.length; i++) {
    final keep = i < firstPullUnread;
    final isNew = await PublicOSActivity.storeIfNew(all[i], read: !keep);
    if (isNew && keep) fresh.add(all[i]);
  }
  await prefs.setInt(key, after);
  debugPrint('[social] first inbox pull: ${all.length} stored, '
      '${fresh.length} left unread');
  return fresh;
}

/// The inbox pull when the notifications screen opens (the client's twin,
/// minus the popups: desktop pops no OS notifications for social rows). The
/// shell's 10-min sweep stays the regular reader. Returns how many rows were
/// new. Never throws.
Future<int> pullSocialInboxNow() async {
  try {
    if (!await PublicOSSettings.getSocialNotifications()) return 0;
    final me = PublicOS.myPublicosAddress;
    final home = await PublicOSSsp.homeForIsolate();
    if (me == null || home == null) return 0;
    return (await pullSocialInbox(account: me, home: home)).length;
  } catch (e) {
    debugPrint('[social] foreground pull failed: $e');
    return 0;
  }
}
