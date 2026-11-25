@TestOn('windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_desktop/utils/windows_credential_store.dart';

/// Round trip through the real Windows Credential Manager with a throwaway
/// entry (`PublicOS/unit_test_probe`), removed at the end.
void main() {
  const key = 'unit_test_probe';

  tearDown(() => WindowsCredentialStore.delete(key));

  test('write, read back, overwrite, delete', () async {
    await WindowsCredentialStore.delete(key);
    expect(await WindowsCredentialStore.read(key), isNull);

    await WindowsCredentialStore.write(key, 'first value');
    expect(await WindowsCredentialStore.read(key), 'first value');

    await WindowsCredentialStore.write(key, 'second');
    expect(await WindowsCredentialStore.read(key), 'second');

    await WindowsCredentialStore.delete(key);
    expect(await WindowsCredentialStore.read(key), isNull);
  });
}
