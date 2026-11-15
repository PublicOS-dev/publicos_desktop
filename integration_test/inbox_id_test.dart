import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:xmtp_plugin/src/rust/api/client.dart' as rust_client;
import 'package:xmtp_plugin/src/rust/api/inbox.dart' as rust_inbox;
import 'package:xmtp_plugin/src/rust/api/signing.dart' as rust_signing;
import 'package:xmtp_plugin/src/rust/api/conversations.dart'
    as rust_conversations;
import 'package:xmtp_plugin/src/rust/frb_generated.dart';

/// Generate a random 32-byte key for XMTP DB encryption.
Uint8List _randomDbKey() {
  final rng = Random.secure();
  return Uint8List.fromList(List.generate(32, (_) => rng.nextInt(256)));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
  });

  group('Inbox ID Management', () {
    late Uint8List keyA;
    late Uint8List keyB;
    late Uint8List dbKeyA;
    late String addressA;
    late String addressB;

    setUp(() async {
      // Generate two fresh private keys
      keyA = await rust_client.generatePrivateKey();
      keyB = await rust_client.generatePrivateKey();
      dbKeyA = _randomDbKey();

      // Derive addresses
      addressA = await rust_client.addressFromPrivateKey(
          privateKey: keyA.toList());
      addressB = await rust_client.addressFromPrivateKey(
          privateKey: keyB.toList());

      print('--- Test Setup ---');
      print('Key A address: $addressA');
      print('Key B address: $addressB');
    });

    testWidgets('Generated keys produce unique addresses and inbox IDs',
        (tester) async {
      // Keys should be different
      expect(keyA, isNot(equals(keyB)));

      // Addresses should be different
      expect(addressA, isNot(equals(addressB)));

      // Compute local inbox IDs (deterministic: sha256(address + nonce))
      final localInboxIdA =
          await rust_client.computeInboxId(address: addressA);
      final localInboxIdB =
          await rust_client.computeInboxId(address: addressB);

      print('Local inbox ID A: $localInboxIdA');
      print('Local inbox ID B: $localInboxIdB');

      // Each address should produce a different inbox ID
      expect(localInboxIdA, isNotEmpty);
      expect(localInboxIdB, isNotEmpty);
      expect(localInboxIdA, isNot(equals(localInboxIdB)));
    });

    testWidgets(
        'Initialize client A and verify inbox ID matches local computation',
        (tester) async {
      // Initialize client with key A
      final clientAddress = await rust_client.initializeClient(
        privateKey: keyA.toList(),
        dbEncryptionKey: dbKeyA.toList(),
      );
      print('Client initialized, address: $clientAddress');
      expect(clientAddress.toLowerCase(), equals(addressA.toLowerCase()));

      // Get the client's inbox ID from the network
      final clientInboxId = await rust_client.getClientInboxId();
      print('Client inbox ID: $clientInboxId');

      // Should match local computation
      final localInboxId =
          await rust_client.computeInboxId(address: addressA);
      expect(clientInboxId, equals(localInboxId));

      // Check inbox state — should have exactly 1 identity (address A)
      final state =
          await rust_inbox.getInboxState(refreshFromNetwork: true);
      print('Inbox state: ${state.inboxId}');
      print('Identities: ${state.identities.map((i) => '${i.kind}:${i.identifier}').toList()}');
      print('Installations: ${state.installations.length}');

      expect(state.inboxId, equals(clientInboxId));
      expect(state.identities.length, greaterThanOrEqualTo(1));
      // At least one identity should be address A
      final hasAddressA = state.identities.any(
        (id) => id.identifier.toLowerCase() == addressA.toLowerCase(),
      );
      expect(hasAddressA, isTrue,
          reason: 'Inbox should contain address A as an identity');
    });

    testWidgets('canMessage works for initialized address', (tester) async {
      // Initialize client A
      await rust_client.initializeClient(
        privateKey: keyA.toList(),
        dbEncryptionKey: dbKeyA.toList(),
      );

      // Client A should be messageable
      final canMessageA =
          await rust_conversations.canMessage(address: addressA);
      print('Can message A ($addressA): $canMessageA');
      expect(canMessageA, isTrue);

      // Address B has never been initialized — should NOT be messageable
      final canMessageB =
          await rust_conversations.canMessage(address: addressB);
      print('Can message B ($addressB): $canMessageB');
      expect(canMessageB, isFalse);
    });

    testWidgets('Add key B to inbox A, both share the same inbox ID',
        (tester) async {
      // Step 1: Initialize client with key A
      await rust_client.initializeClient(
        privateKey: keyA.toList(),
        dbEncryptionKey: dbKeyA.toList(),
      );
      final inboxIdA = await rust_client.getClientInboxId();
      print('Step 1 - Client A inbox ID: $inboxIdA');

      // Step 2: Get initial inbox state
      final stateBefore =
          await rust_inbox.getInboxState(refreshFromNetwork: true);
      final identitiesBefore = stateBefore.identities.length;
      print('Step 2 - Identities before addAccount: $identitiesBefore');
      print('  ${stateBefore.identities.map((i) => '${i.kind}:${i.identifier}').toList()}');

      // Step 3: Add key B as a second account/identity to this inbox
      print('Step 3 - Adding key B to inbox A...');
      final addResult =
          await rust_signing.addAccount(newAccountPrivateKey: keyB.toList());
      print('  addAccount result: $addResult');

      // Step 4: Verify inbox state now has 2 identities
      final stateAfter =
          await rust_inbox.getInboxState(refreshFromNetwork: true);
      print('Step 4 - Identities after addAccount: ${stateAfter.identities.length}');
      print('  ${stateAfter.identities.map((i) => '${i.kind}:${i.identifier}').toList()}');

      expect(stateAfter.identities.length,
          equals(identitiesBefore + 1),
          reason: 'Should have one more identity after addAccount');

      // Both addresses should be in the identity list
      final hasA = stateAfter.identities.any(
        (id) => id.identifier.toLowerCase() == addressA.toLowerCase(),
      );
      final hasB = stateAfter.identities.any(
        (id) => id.identifier.toLowerCase() == addressB.toLowerCase(),
      );
      expect(hasA, isTrue, reason: 'Address A should still be in inbox');
      expect(hasB, isTrue, reason: 'Address B should now be in inbox');

      // Inbox ID should NOT have changed
      expect(stateAfter.inboxId, equals(inboxIdA),
          reason: 'Inbox ID should remain the same after adding account');

      // Step 5: Address B should now be messageable
      final canMessageB =
          await rust_conversations.canMessage(address: addressB);
      print('Step 5 - Can message B after addAccount: $canMessageB');
      expect(canMessageB, isTrue,
          reason: 'Address B should be messageable after being added to inbox');

      // Step 6: Reinitialize client with key B to verify it joins the same inbox
      print('Step 6 - Reinitializing with key B...');
      final dbKeyB = _randomDbKey();
      final clientAddressB = await rust_client.initializeClient(
        privateKey: keyB.toList(),
        dbEncryptionKey: dbKeyB.toList(),
      );
      print('  Client B address: $clientAddressB');
      expect(clientAddressB.toLowerCase(), equals(addressB.toLowerCase()));

      final inboxIdB = await rust_client.getClientInboxId();
      print('  Client B inbox ID: $inboxIdB');

      // THE KEY ASSERTION: Both keys should resolve to the same inbox ID
      expect(inboxIdB, equals(inboxIdA),
          reason:
              'After addAccount, key B should join the same inbox as key A');

      // Step 7: Verify inbox state from key B's perspective
      final stateFromB =
          await rust_inbox.getInboxState(refreshFromNetwork: true);
      print('Step 7 - Inbox state from B perspective:');
      print('  Inbox ID: ${stateFromB.inboxId}');
      print('  Identities: ${stateFromB.identities.map((i) => '${i.kind}:${i.identifier}').toList()}');

      expect(stateFromB.inboxId, equals(inboxIdA));
      final bHasA = stateFromB.identities.any(
        (id) => id.identifier.toLowerCase() == addressA.toLowerCase(),
      );
      final bHasB = stateFromB.identities.any(
        (id) => id.identifier.toLowerCase() == addressB.toLowerCase(),
      );
      expect(bHasA, isTrue, reason: 'B should see A in shared inbox');
      expect(bHasB, isTrue, reason: 'B should see itself in shared inbox');
    });
  });
}
