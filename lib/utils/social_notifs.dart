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
