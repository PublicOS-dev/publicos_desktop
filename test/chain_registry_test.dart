// Pins the invariants of the single chain registry. Each of these failing
// means a chain is reachable somewhere in the app while being unnamed,
// unmarked, or dialled at a different endpoint than the rest of the app uses
// for the same chain.

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_desktop/widgets/chain_icon.dart';
import 'package:publicos_desktop/data/chain_registry.dart';

void main() {
  group('hex <-> id', () {
    test('PublicOS is 0x1189', () {
      expect(chainIdToHex(kOxChainId), '0x1189');
      expect(chainIdFromHex('0x1189'), kOxChainId);
    });

    test('round-trips every registered chain', () {
      for (final c in kChainRegistry) {
        expect(chainIdFromHex(chainIdToHex(c.chainId)), c.chainId,
            reason: 'round-trip failed for ${c.name}');
      }
    });

    test('tolerates a missing or unparseable id', () {
      expect(chainIdFromHex(null), isNull);
      expect(chainIdFromHex('not-hex'), isNull);
      expect(chainNameForHex(null), isNull);
      expect(chainNameForHex('0xdead'), isNull);
    });
  });

  group('the one registry feeds every surface', () {
    test('the browser map covers every chain, keyed as EIP-1193 speaks', () {
      expect(kBridgeChainRpcMap.length, kChainRegistry.length);
      for (final c in kChainRegistry) {
        expect(kBridgeChainRpcMap[chainIdToHex(c.chainId)], c.rpcUrl,
            reason: '${c.name} missing from the browser chain map');
      }
    });

    test('the browser can always reach PublicOS', () {
      // The bridge constructs on `publicOsChainId` and throws 4901 if the map
      // has no endpoint for the chain it starts on.
      expect(kBridgeChainRpcMap.containsKey('0x1189'), isTrue);
    });

    test('every chain has a name reachable from a hex id', () {
      for (final c in kChainRegistry) {
        expect(chainNameForHex(chainIdToHex(c.chainId)), c.name);
      }
    });

    test('every chain has a real brand mark, not the fallback diamond', () {
      for (final c in kChainRegistry) {
        expect(hasChainMark(c.chainId), isTrue,
            reason: '${c.name} (${c.chainId}) has no mark in chain_icon.dart');
      }
    });
  });

  group('send is a narrower set than browse', () {
    test('send chains are a subset of the registry', () {
      for (final c in kSendChains) {
        expect(kChainRegistry.contains(c), isTrue);
      }
    });

    test('a send chain never offers an empty token list', () {
      for (final c in kSendChains) {
        expect(c.tokens, isNotEmpty, reason: '${c.name} has no tokens');
      }
    });

    test('OX is still the default and still sendable', () {
      expect(kSendChains.first.chainId, kOxChainId);
      expect(kOxChain.sendEnabled, isTrue);
    });

    test('browser-only chains stay out of the money surface', () {
      // BNB Chain and Avalanche arrived from the bridge with native-only token
      // lists; they browse but must not appear in the Send picker until their
      // token addresses are explorer-verified.
      expect(kSendChains.any((c) => c.chainId == 56), isFalse);
      expect(kSendChains.any((c) => c.chainId == 43114), isFalse);
      expect(kBridgeChainRpcMap.containsKey('0x38'), isTrue);
      expect(kBridgeChainRpcMap.containsKey('0xa86a'), isTrue);
    });
  });

  group('the testnet is gone', () {
    test('Base Sepolia is not reachable, Base mainnet is', () {
      expect(chainById(84532), isNull);
      expect(kBridgeChainRpcMap.containsKey('0x14a34'), isFalse);
      expect(chainById(8453)?.name, 'Base');
    });

    test('no endpoint carries an embedded API key', () {
      // The dead Base Sepolia entry shipped an Infura project id in the client.
      for (final c in kChainRegistry) {
        expect(c.rpcUrl.contains('infura.io'), isFalse,
            reason: '${c.name} dials a keyed endpoint: ${c.rpcUrl}');
      }
    });
  });
}
