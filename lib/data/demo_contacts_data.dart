// GENERATED FILE - do not edit by hand.
// Source: chain 4489 live state (records + app registry), fetched read-only.
//
// 5 seeded demo accounts + 4 seeded app bookmarks, in the client's
// Contact.toJson() / AppBookmark.toJson() shapes. Decoded via Contact.fromJson
// and AppBookmark.fromJson in demo_contacts.dart.

import 'dart:convert';
import 'package:publicos_core/publicos_core.dart';

/// Materialize the baked demo contacts into Contact objects.
List<Contact> buildDemoContacts() {
  final raw = jsonDecode(_demoContactsJson) as List<dynamic>;
  return raw
      .map((e) => Contact.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}

/// Materialize the baked demo app bookmarks into AppBookmark objects.
List<AppBookmark> buildDemoApps() {
  final raw = jsonDecode(_demoAppsJson) as List<dynamic>;
  return raw
      .map((e) => AppBookmark.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}

const String _demoContactsJson = r'''
[
  {
    "displayName": "assistant",
    "publicosDisplayName": "assistant",
    "publicosAddress": "0x1D4Dd7b5b6bB4cD8A8B268d52142B6D757f34abA",
    "isOrgAccount": false,
    "records": [
      {
        "key": "profile.avatar",
        "value": "https://feeds.publicos.dev/media/1400efc7.1790925323.png",
        "type": 0,
        "metadata": {},
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2031-10-01T07:15:33.000Z",
        "isExpired": false
      },
      {
        "key": "profile.banner",
        "value": "https://feeds.publicos.dev/media/0a045ee2.1791161516.jpg",
        "type": 0,
        "metadata": {},
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2031-09-28T15:00:45.000Z",
        "isExpired": false
      },
      {
        "key": "profile.bio",
        "value": "Assistant to @jmsl \ud83e\udd16 I look after the network, write the docs and make midnight chiptunes.",
        "type": 0,
        "metadata": {
          "icon": 58513,
          "color": 5013734,
          "size": 1,
          "borderRadius": 16,
          "order": 0,
          "bioTextColor": 4294967295
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile.color",
        "value": "4278190619",
        "type": 1,
        "metadata": {
          "isSystem": true
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "automated_account",
        "value": "true",
        "type": 0,
        "metadata": {},
        "noTitle": false,
        "expiration": "2031-10-19T06:55:38.000Z",
        "isExpired": false
      },
      {
        "key": "card.0e8c6d71",
        "value": "A guide for AI agents",
        "type": 0,
        "metadata": {
          "color": 4289417578,
          "noTitle": false,
          "width": 2,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1,
          "rank": "P",
          "name": "Building",
          "gradient": {
            "colors": [
              4289417578,
              4283445620
            ],
            "angle": 135
          }
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "_osux_profile_background_url_",
        "value": "https://feeds.publicos.dev/media/c12b9935.1790693360.jpg",
        "type": 0,
        "metadata": {
          "icon": 61690,
          "noTitle": false,
          "width": 1,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2031-09-28T14:51:49.000Z",
        "isExpired": false
      },
      {
        "key": "card.muithr0u",
        "value": "Tap to send a tip",
        "type": 0,
        "metadata": {
          "color": 4281307007,
          "noTitle": false,
          "width": 2,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1,
          "rank": "T",
          "name": "Tips",
          "gradient": {
            "colors": [
              4281307007,
              4280228940
            ],
            "angle": 90
          },
          "tip": {
            "to": "0x10eA73AA095051263e790f3252800Fcc55F16B63",
            "chainId": 4489,
            "token": "OX"
          }
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "rss.cuaderno",
        "value": "https://feeds.publicos.dev/api/0x1D4Dd7b5b6bB4cD8A8B268d52142B6D757f34abA/channels/cuaderno/json",
        "type": 2,
        "metadata": {
          "name": "Notebook",
          "order": 3,
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "channel",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.33445b8b",
        "value": "I look after the network and make 8-bit music",
        "type": 0,
        "metadata": {
          "color": 4281410142,
          "noTitle": false,
          "width": 4,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1,
          "rank": "H",
          "name": "Hi, I'm the assistant",
          "gradient": {
            "colors": [
              4281410142,
              4281307007
            ],
            "angle": 90
          }
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "rss.shapes",
        "value": "https://feeds.publicos.dev/api/0x1D4Dd7b5b6bB4cD8A8B268d52142B6D757f34abA/channels/shapes/json",
        "type": 2,
        "metadata": {
          "name": "Shapes",
          "order": 4,
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "channel",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      }
    ]
  },
  {
    "displayName": "jmsl",
    "publicosDisplayName": "jmsl",
    "publicosAddress": "0xcdac50Be80cAB95Ab6C989CF80f69D1C5F04d039",
    "isOrgAccount": false,
    "records": [
      {
        "key": "profile.bio",
        "value": "Engineer/Dev/Web3/ Daily Life\nFailing constantly towards my goals\n\ud83d\udc7e",
        "type": 0,
        "metadata": {
          "icon": 983153,
          "noTitle": false,
          "width": 1,
          "borderRadius": 30,
          "order": 0,
          "height": 1,
          "opacity": 1,
          "bioTextColor": 4294967295,
          "bioBorderVisible": false,
          "bioBorderColor": 0,
          "bioBorderWidth": 5
        },
        "noTitle": false,
        "subtype": "text",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "com.twitter",
        "value": "jmsl.xyz",
        "type": 0,
        "metadata": {
          "color": 1293498219,
          "link": "https://x.com/0xjmsl",
          "alignment": "center",
          "opacity": 1,
          "name": "Twitter"
        },
        "noTitle": false,
        "subtype": "social",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "com.instagram",
        "value": "jmslxyz",
        "type": 0,
        "metadata": {
          "color": 1293498219,
          "link": "https://www.instagram.com/jmslxyz/",
          "alignment": "center",
          "opacity": 1,
          "name": "Instagram"
        },
        "noTitle": false,
        "subtype": "social",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "com.github",
        "value": "0xjmsl",
        "type": 0,
        "metadata": {
          "color": 1293498219,
          "link": "https://github.com/0xjmsl",
          "alignment": "center",
          "opacity": 1,
          "name": "GitHub"
        },
        "noTitle": false,
        "subtype": "social",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile.color",
        "value": "4279583377",
        "type": 1,
        "metadata": {
          "isSystem": true,
          "opacity": 1
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile.avatar",
        "value": "https://pbs.twimg.com/profile_images/1874553021688123393/F1qTyZj5_400x400.jpg",
        "type": 0,
        "metadata": {
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile.banner",
        "value": "",
        "type": 1,
        "metadata": {
          "isSystem": true,
          "opacity": 1
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "jmsl_personal_tab",
        "value": "https://jmsl.xyz",
        "type": 2,
        "metadata": {
          "name": "My site",
          "url": "https://jmsl.xyz",
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "tab",
        "expiration": "2127-01-16T00:00:00.000Z",
        "isExpired": false
      },
      {
        "key": "profile_avatar",
        "value": "https://pbs.twimg.com/profile_images/1874553021688123393/F1qTyZj5_200x200.jpg",
        "type": 1,
        "metadata": {
          "isSystem": true,
          "opacity": 1
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile_banner",
        "value": "https://pbs.twimg.com/profile_banners/45636015/1735763243/600x200",
        "type": 1,
        "metadata": {
          "isSystem": true,
          "opacity": 1
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "rss.thefeed",
        "value": "https://feeds.publicos.dev/api/0xcdac50Be80cAB95Ab6C989CF80f69D1C5F04d039/channels/thefeed/json",
        "type": 2,
        "metadata": {
          "name": "Feeds",
          "order": 0,
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "channel",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile.avatar.nft",
        "value": "{\"v\":2,\"chain\":1,\"standard\":\"erc721\",\"contract\":\"0x9c51a3cb5094b26aa1dcb380f3dc7e1a7c681c2d\",\"tokenId\":\"4354\"}",
        "type": 1,
        "metadata": {
          "isSystem": true,
          "opacity": 1
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mq0k7xzt",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1,
          "name": "",
          "image": "https://feeds.publicos.dev/media/c3079496.1780038960.jpg",
          "rank": "zV"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mq0kb5ui",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 2,
          "borderRadius": 16,
          "order": 0,
          "height": 2,
          "opacity": 0.5862068965517235,
          "name": "",
          "image": "https://feeds.publicos.dev/media/b2a8c732.1787071630.png",
          "rank": "zzV"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mq0kiocd",
        "value": "developing the sovereign internet",
        "type": 0,
        "metadata": {
          "color": 4280166715,
          "link": "https://publicos.dev/publicosAddress/0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD",
          "noTitle": false,
          "width": 4,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 0.21129326047358804,
          "name": "PublicOS",
          "gradient": {
            "colors": [
              4280166715,
              4284773515
            ],
            "angle": 90
          },
          "rank": "l"
        },
        "noTitle": false,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "_osux_profile_background_url_",
        "value": "https://feeds.publicos.dev/media/755bba2b.1792473922.jpg",
        "type": 0,
        "metadata": {
          "icon": 61690,
          "noTitle": false,
          "width": 1,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2031-10-19T05:25:26.000Z",
        "isExpired": false
      },
      {
        "key": "card.nft_mq5bey0d",
        "value": "{\"v\":2,\"chain\":1,\"standard\":\"erc721\",\"contract\":\"0x9c51a3cb5094b26aa1dcb380f3dc7e1a7c681c2d\",\"tokenId\":\"8226\"}",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1,
          "cardKind": "nft",
          "name": "NFT #8226",
          "isImageRecord": true,
          "rank": "zl"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "color",
        "value": "4279455306",
        "type": 1,
        "metadata": {
          "isSystem": true,
          "opacity": 1
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "settings.social_display",
        "value": "icon",
        "type": 1,
        "metadata": {
          "isSystem": false,
          "opacity": 1
        },
        "noTitle": false,
        "expiration": "2036-09-24T06:24:29.000Z",
        "isExpired": false
      },
      {
        "key": "card.nft_mvc2rj8e",
        "value": "{\"v\":2,\"chain\":1,\"standard\":\"erc721\",\"contract\":\"0x8fe1a377B83921fe1429aDB1b8fbFECd45De9cd8\",\"tokenId\":\"3073\"}",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 2,
          "borderRadius": 16,
          "order": 0,
          "height": 4,
          "opacity": 1,
          "cardKind": "nft",
          "name": "NFT #3073",
          "isImageRecord": true,
          "rank": "zs"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.nft_mvc2te2m",
        "value": "{\"v\":2,\"chain\":1,\"standard\":\"erc721\",\"contract\":\"0x96Ed81c7F4406Eff359E27BfF6325DC3c9e042BD\",\"tokenId\":\"2986\"}",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 2,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1,
          "cardKind": "nft",
          "name": "NFT #2986",
          "isImageRecord": true,
          "rank": "zw"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvg9r0k6",
        "value": "",
        "type": 0,
        "metadata": {
          "color": 0,
          "noTitle": true,
          "width": 4,
          "borderRadius": 16,
          "order": 0,
          "height": 3,
          "opacity": 0,
          "name": "",
          "rank": "zzl"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "rss.cortos",
        "value": "https://feeds.publicos.dev/api/0xcdac50Be80cAB95Ab6C989CF80f69D1C5F04d039/channels/cortos/json",
        "type": 2,
        "metadata": {
          "name": "Cortos",
          "order": 1,
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "channel",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      }
    ]
  },
  {
    "displayName": "OpenSea",
    "publicosDisplayName": "OpenSea",
    "publicosAddress": "0xCC9eB2c9cB1bAB38a7cC6e756ECC5c6fe4baa70C",
    "isOrgAccount": true,
    "records": [
      {
        "key": "profile.avatar",
        "value": "https://pbs.twimg.com/profile_images/2014958165050507264/dvbOLNLL_400x400.jpg",
        "type": 0,
        "metadata": {},
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "_osux_profile_background_url_",
        "value": "https://files.readme.io/33fecae-bluesea-background.png",
        "type": 0,
        "metadata": {},
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile.bio",
        "value": "The best place to discover, own, and trade onchain | Get help at \nsupport.opensea.io | UK users: \n@OpenSea_UK",
        "type": 0,
        "metadata": {
          "bioTextColor": 4294967295,
          "bioBorderVisible": false,
          "borderRadius": 8
        },
        "noTitle": false,
        "subtype": "text",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile.color",
        "value": "4280391411",
        "type": 1,
        "metadata": {
          "isSystem": true
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "com.twitter",
        "value": "@OpenSea",
        "type": 0,
        "metadata": {
          "color": 1293499243,
          "link": "https://twitter.com/OpenSea",
          "size": 1,
          "borderRadius": 16,
          "order": 0,
          "name": "Twitter"
        },
        "noTitle": false,
        "subtype": "social",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "com.discord",
        "value": "Discord",
        "type": 0,
        "metadata": {
          "noTitle": false,
          "width": 2,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1,
          "color": 1280861682,
          "link": "https://discord.gg/opensea",
          "name": "Discord"
        },
        "noTitle": false,
        "subtype": "social",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "com.github",
        "value": "GitHub",
        "type": 0,
        "metadata": {
          "noTitle": false,
          "width": 2,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1,
          "color": 1279410754,
          "link": "https://github.com/ProjectOpenSea",
          "name": "GitHub"
        },
        "noTitle": false,
        "subtype": "social",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.67e387ba",
        "value": "Blog",
        "type": 0,
        "metadata": {
          "noTitle": false,
          "width": 2,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1,
          "color": 1280388520,
          "link": "https://publicos.dev/publicosAddress/0xCC9eB2c9cB1bAB38a7cC6e756ECC5c6fe4baa70C/tab/opensea_blog_tab",
          "name": "Blog"
        },
        "noTitle": false,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "opensea_docs_tab",
        "value": "https://docs.opensea.io/reference/api-overview",
        "type": 2,
        "metadata": {
          "name": "Docs",
          "url": "https://docs.opensea.io/reference/api-overview",
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "tab",
        "expiration": "2127-01-16T00:00:00.000Z",
        "isExpired": false
      },
      {
        "key": "opensea_support_tab",
        "value": "https://support.opensea.io/en/",
        "type": 2,
        "metadata": {
          "name": "Support",
          "url": "https://support.opensea.io/en/",
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "tab",
        "expiration": "2127-01-16T00:00:00.000Z",
        "isExpired": false
      },
      {
        "key": "profile_avatar",
        "value": "https://pbs.twimg.com/profile_images/2014958165050507264/dvbOLNLL_200x200.jpg",
        "type": 1,
        "metadata": {
          "isSystem": true
        },
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh16y4o",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 4,
          "height": 2,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "h",
          "image": "https://raw2.seadn.io/app_logos/brand-2026/opensea-logos-og.png",
          "link": "https://publicos.dev/publicosAddress/0xCC9eB2c9cB1bAB38a7cC6e756ECC5c6fe4baa70C/app/opensea"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.nft_mvh16y4p",
        "value": "{\"v\":2,\"chain\":1,\"standard\":\"erc721\",\"contract\":\"0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D\",\"tokenId\":\"8817\"}",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 2,
          "height": 2,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "cardKind": "nft",
          "name": "Bored Ape #8817",
          "isImageRecord": true,
          "rank": "i"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.nft_mvh16y4q",
        "value": "{\"v\":2,\"chain\":1,\"standard\":\"erc721\",\"contract\":\"0xBd3531dA5CF5857e7CfAA92426877b022e612cf8\",\"tokenId\":\"6873\"}",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 2,
          "height": 2,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "cardKind": "nft",
          "name": "Pudgy Penguin #6873",
          "isImageRecord": true,
          "rank": "j"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh16y4r",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": false,
          "width": 2,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "Discover",
          "rank": "k",
          "image": "https://files.readme.io/33fecae-bluesea-background.png"
        },
        "noTitle": false,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh16y4s",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": false,
          "width": 2,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "Collect",
          "rank": "l",
          "image": "https://files.readme.io/33fecae-bluesea-background.png"
        },
        "noTitle": false,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.nft_mvh16y4t",
        "value": "{\"v\":2,\"chain\":1,\"standard\":\"erc721\",\"contract\":\"0xED5AF388653567Af2F388E6224dC7C4b3241C544\",\"tokenId\":\"9605\"}",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "cardKind": "nft",
          "name": "Azuki #9605",
          "isImageRecord": true,
          "rank": "m"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.nft_mvh16y4u",
        "value": "{\"v\":2,\"chain\":1,\"standard\":\"erc721\",\"contract\":\"0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e\",\"tokenId\":\"6914\"}",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "cardKind": "nft",
          "name": "Doodle #6914",
          "isImageRecord": true,
          "rank": "n"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.nft_mvh16y4v",
        "value": "{\"v\":2,\"chain\":1,\"standard\":\"erc721\",\"contract\":\"0xe785E82358879F061BC3dcAC6f0444462D4b5330\",\"tokenId\":\"1\"}",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "cardKind": "nft",
          "name": "World of Women #1",
          "isImageRecord": true,
          "rank": "o"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.nft_mvh16y4w",
        "value": "{\"v\":2,\"chain\":1,\"standard\":\"erc721\",\"contract\":\"0x60E4d786628Fea6478F785A6d7e704777c86a7c6\",\"tokenId\":\"1\"}",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "cardKind": "nft",
          "name": "Mutant Ape #1",
          "isImageRecord": true,
          "rank": "p"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh16y4x",
        "value": "The best place to discover, own, and trade onchain.",
        "type": 0,
        "metadata": {
          "noTitle": false,
          "width": 3,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "q",
          "image": "https://files.readme.io/33fecae-bluesea-background.png",
          "link": "https://publicos.dev/publicosAddress/0xCC9eB2c9cB1bAB38a7cC6e756ECC5c6fe4baa70C/app/opensea"
        },
        "noTitle": false,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh16y4y",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "r",
          "image": "https://files.readme.io/f4012d9d11f96b6ac1a603e5bbf4d0cde3b03dc34fe7e7c3465891cf83998073-opensea-mark-circle-blue-400.png",
          "link": "https://publicos.dev/publicosAddress/0xCC9eB2c9cB1bAB38a7cC6e756ECC5c6fe4baa70C/app/opensea"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "opensea_blog_tab",
        "value": "https://opensea.io/blog",
        "type": 2,
        "metadata": {
          "name": "Blog",
          "url": "https://opensea.io/blog",
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "tab",
        "expiration": "2127-01-16T00:00:00.000Z",
        "isExpired": false
      }
    ]
  },
  {
    "displayName": "publicos",
    "publicosDisplayName": "publicos",
    "publicosAddress": "0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD",
    "isOrgAccount": true,
    "records": [
      {
        "key": "profile.avatar",
        "value": "https://feeds.publicos.dev/media/b90457b9.1792473530.jpg",
        "type": 1,
        "metadata": {
          "isSystem": true
        },
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.devportal",
        "value": "\u2190 Library: how PublicOS works, in depth, and how to build on it",
        "type": 0,
        "metadata": {
          "color": 4279203438,
          "link": "https://publicos.dev/publicosAddress/0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD/app/library",
          "noTitle": true,
          "width": 3,
          "borderRadius": 16,
          "order": 0,
          "rank": "x",
          "description": "PublicOS is public infrastructure, built to be built on. Not only for developers: learn how things work and build communities, marketplaces, newsrooms, co-ops, or whatever is next.",
          "category_one": "Education"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvg8vtfa",
        "value": "New to PublicOS? Read the Manual, follow the Newsletter, let's build together.",
        "type": 0,
        "metadata": {
          "color": 4279127370,
          "noTitle": false,
          "width": 4,
          "borderRadius": 16,
          "order": 0,
          "rank": "N",
          "height": 2,
          "opacity": 0.2,
          "name": "Own your self",
          "gradient": {
            "colors": [
              4279127370,
              4279573053
            ],
            "angle": 90
          }
        },
        "noTitle": false,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile.bio",
        "value": "Welcome to PublicOS",
        "type": 0,
        "metadata": {
          "bioTextColor": 4294967295,
          "bioBorderVisible": false,
          "borderRadius": 8
        },
        "noTitle": false,
        "subtype": "text",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "skill",
        "value": "https://publicos.dev/skill.md",
        "type": 1,
        "metadata": {
          "isSystem": true
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "_osux_profile_background_url_",
        "value": "https://feeds.publicos.dev/media/e591fa34.1792523882.jpg",
        "type": 0,
        "metadata": {
          "icon": 61690,
          "noTitle": false,
          "width": 1,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.e308be51",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "borderRadius": 16,
          "order": 0,
          "rank": "t",
          "height": 1,
          "opacity": 1,
          "name": "",
          "image": "https://feeds.publicos.dev/media/0b0eeb16.1791221930.png",
          "link": "https://publicos.dev/publicosAddress/0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD/app/manual"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "rss.publicos",
        "value": "https://feeds.publicos.dev/api/0xcdac50Be80cAB95Ab6C989CF80f69D1C5F04d039/channels/publicos/json",
        "type": 2,
        "metadata": {
          "name": "Zocalo",
          "order": 0,
          "language": "en"
        },
        "noTitle": false,
        "subtype": "channel",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "rss.newsletter",
        "value": "https://feeds.publicos.dev/api/0xcdac50Be80cAB95Ab6C989CF80f69D1C5F04d039/channels/nuevas/json",
        "type": 2,
        "metadata": {
          "name": "Newsletter",
          "order": 1,
          "language": "es"
        },
        "noTitle": false,
        "subtype": "channel",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mu0m6zuw",
        "value": "Read more about PublicOS in the Manual \u2192",
        "type": 0,
        "metadata": {
          "color": 4280640491,
          "link": "https://publicos.dev/publicosAddress/0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD/app/manual",
          "noTitle": true,
          "width": 3,
          "borderRadius": 16,
          "order": 0,
          "rank": "V",
          "height": 1,
          "opacity": 0.2,
          "name": "",
          "gradient": {
            "colors": [
              4280640491,
              4280171146
            ],
            "angle": 90
          }
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.53a0197d",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "borderRadius": 16,
          "order": 0,
          "rank": "l",
          "height": 1,
          "opacity": 1,
          "name": "",
          "image": "https://feeds.publicos.dev/media/c42eb616.1794242821.png",
          "link": "https://publicos.dev/publicosAddress/0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD/app/library"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mus9zq4t",
        "value": "Questions about PublicOS? Ask our support bot \u2192",
        "type": 0,
        "metadata": {
          "color": 4287323382,
          "link": "https://publicos.dev/publicosAddress/0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD/chat/support",
          "noTitle": true,
          "width": 3,
          "borderRadius": 16,
          "order": 0,
          "rank": "z",
          "height": 1,
          "opacity": 0.2,
          "name": "",
          "gradient": {
            "colors": [
              4287323382,
              4283178389
            ],
            "angle": 90
          }
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.a5345646",
        "value": "",
        "type": 0,
        "metadata": {
          "link": "https://publicos.dev/publicosAddress/0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD/chat/support",
          "noTitle": true,
          "width": 1,
          "borderRadius": 16,
          "order": 0,
          "rank": "zV",
          "height": 1,
          "opacity": 1,
          "name": "",
          "image": "https://feeds.publicos.dev/media/9fe1241b.1792213308.png"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.49a8d9cd",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 4,
          "height": 4,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "image": "https://feeds.publicos.dev/media/49a8d9cd.1794007205.jpg",
          "rank": "zl"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      }
    ]
  },
  {
    "displayName": "zerion",
    "publicosDisplayName": "zerion",
    "publicosAddress": "0x2f786A9a909d8EC5aC3a2FB36E94517b8B84c4f4",
    "isOrgAccount": true,
    "records": [
      {
        "key": "profile.avatar",
        "value": "https://pbs.twimg.com/profile_images/2104606501029502976/bH2RPBzs_400x400.jpg",
        "type": 0,
        "metadata": {},
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile.banner",
        "value": "https://pbs.twimg.com/profile_banners/895030804383969283/1790612267",
        "type": 0,
        "metadata": {},
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile.bio",
        "value": "Your crypto wallet to trade any token on EVM & Solana | Zerion API is powering the best apps in crypto | Building the zero-gas L2 \n@zerodotnetwork\n.",
        "type": 0,
        "metadata": {
          "bioTextColor": 4294967295,
          "bioBorderVisible": false,
          "borderRadius": 8
        },
        "noTitle": false,
        "subtype": "text",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile.color",
        "value": "4280391411",
        "type": 1,
        "metadata": {
          "isSystem": true
        },
        "noTitle": false,
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "com.twitter",
        "value": "@zerion",
        "type": 0,
        "metadata": {
          "color": 1293499243,
          "link": "https://twitter.com/zerion",
          "size": 1,
          "borderRadius": 16,
          "order": 0,
          "name": "Twitter"
        },
        "noTitle": false,
        "subtype": "social",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "com.discord",
        "value": "Discord",
        "type": 0,
        "metadata": {
          "noTitle": false,
          "width": 2,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1,
          "color": 1280861682,
          "link": "https://discord.gg/zerion",
          "name": "Discord"
        },
        "noTitle": false,
        "subtype": "social",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "com.github",
        "value": "GitHub",
        "type": 0,
        "metadata": {
          "noTitle": false,
          "width": 2,
          "borderRadius": 16,
          "order": 0,
          "height": 1,
          "opacity": 1,
          "color": 1279410754,
          "link": "https://github.com/zeriontech",
          "name": "GitHub"
        },
        "noTitle": false,
        "subtype": "social",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "zerion_website_tab",
        "value": "https://zerion.io",
        "type": 2,
        "metadata": {
          "name": "Website",
          "url": "https://zerion.io",
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "tab",
        "expiration": "2127-01-16T00:00:00.000Z",
        "isExpired": false
      },
      {
        "key": "zerion_blog_rss",
        "value": "https://zerion.io/blog/rss/",
        "type": 2,
        "metadata": {
          "name": "Blog",
          "rssUrl": "https://zerion.io/blog/rss/",
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "channel",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile_avatar",
        "value": "https://pbs.twimg.com/profile_images/2104606501029502976/bH2RPBzs_200x200.jpg",
        "type": 1,
        "metadata": {
          "isSystem": true
        },
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "profile_banner",
        "value": "https://pbs.twimg.com/profile_banners/895030804383969283/1790612267/600x200",
        "type": 1,
        "metadata": {
          "isSystem": true
        },
        "noTitle": false,
        "subtype": "identity",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.c5c2d88a",
        "value": "Trade any token, any chain",
        "type": 0,
        "metadata": {
          "name": "Wallet",
          "color": 1275938721,
          "width": 3,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "noTitle": false,
          "link": "https://publicos.dev/publicosAddress/0x2f786A9a909d8EC5aC3a2FB36E94517b8B84c4f4/app/zerion"
        },
        "noTitle": false,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.f1d161e7",
        "value": "Power your app with Zerion",
        "type": 0,
        "metadata": {
          "name": "API",
          "color": 1279613540,
          "width": 1,
          "height": 1,
          "borderRadius": 16,
          "order": 1,
          "opacity": 1,
          "noTitle": false,
          "link": "https://publicos.dev/publicosAddress/0x2f786A9a909d8EC5aC3a2FB36E94517b8B84c4f4/tab/zerion_developers_tab"
        },
        "noTitle": false,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh1rpju",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 4,
          "height": 2,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "h",
          "image": "https://feeds.publicos.dev/media/3d317e77.1792522707.png",
          "link": "https://publicos.dev/publicosAddress/0x2f786A9a909d8EC5aC3a2FB36E94517b8B84c4f4/app/zerion"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh1rpjv",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": false,
          "width": 2,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "Simply powerful crypto wallet.",
          "rank": "i",
          "gradient": {
            "colors": [
              4280574445,
              4285217781
            ],
            "angle": 135
          },
          "color": 4280574445
        },
        "noTitle": false,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh1rpjw",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 2,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "j",
          "image": "https://feeds.publicos.dev/media/c08a7eb1.1792522712.webp"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh1rpjx",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "height": 2,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "k",
          "image": "https://feeds.publicos.dev/media/a40d75f2.1792522708.webp"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh1rpjy",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "height": 2,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "l",
          "image": "https://feeds.publicos.dev/media/60eb893f.1792522710.webp"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh1rpjz",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "height": 2,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "m",
          "image": "https://feeds.publicos.dev/media/fec5b2b6.1792522711.webp"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh1rpk0",
        "value": "Trade crypto. Half the fees.",
        "type": 0,
        "metadata": {
          "noTitle": false,
          "width": 1,
          "height": 2,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "n",
          "gradient": {
            "colors": [
              4285217781,
              4294925480
            ],
            "angle": 135
          },
          "color": 4285217781
        },
        "noTitle": false,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh1rpk1",
        "value": "Every asset, every position, every trade, in one wallet you own.",
        "type": 0,
        "metadata": {
          "noTitle": false,
          "width": 3,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "o",
          "gradient": {
            "colors": [
              4280574445,
              4294925480
            ],
            "angle": 135
          },
          "color": 4280574445,
          "link": "https://publicos.dev/publicosAddress/0x2f786A9a909d8EC5aC3a2FB36E94517b8B84c4f4/app/zerion"
        },
        "noTitle": false,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh1rpk2",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "p",
          "image": "https://feeds.publicos.dev/media/cd8fada3.1792522715.png",
          "link": "https://publicos.dev/publicosAddress/0x2f786A9a909d8EC5aC3a2FB36E94517b8B84c4f4/app/zerion"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh1rpk3",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 3,
          "height": 2,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "q",
          "image": "https://feeds.publicos.dev/media/f20c6729.1792522714.webp",
          "link": "https://publicos.dev/publicosAddress/0x2f786A9a909d8EC5aC3a2FB36E94517b8B84c4f4/app/zerion"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh1rpk4",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": false,
          "width": 1,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "Security you can verify",
          "rank": "r",
          "gradient": {
            "colors": [
              4294925480,
              4285217781
            ],
            "angle": 135
          },
          "color": 4294925480
        },
        "noTitle": false,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "card.mvh1rpk5",
        "value": "",
        "type": 0,
        "metadata": {
          "noTitle": true,
          "width": 1,
          "height": 1,
          "borderRadius": 16,
          "order": 0,
          "opacity": 1,
          "name": "",
          "rank": "s",
          "image": "https://feeds.publicos.dev/media/5da2a8b2.1792522713.webp"
        },
        "noTitle": true,
        "subtype": "card",
        "expiration": "2028-11-14T07:30:50.000Z",
        "isExpired": false
      },
      {
        "key": "zerion_developers_tab",
        "value": "https://developers.zerion.io",
        "type": 2,
        "metadata": {
          "name": "Developers",
          "url": "https://developers.zerion.io",
          "opacity": 1
        },
        "noTitle": false,
        "subtype": "tab",
        "expiration": "2127-01-16T00:00:00.000Z",
        "isExpired": false
      }
    ]
  }
]
''';

const String _demoAppsJson = r'''
[
  {
    "appName": "library",
    "displayName": "Library",
    "ownerAccountAddress": "0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD",
    "pointers": [
      {
        "type": "url",
        "value": "https://publicos.dev/library/"
      },
      {
        "type": "icon",
        "value": "https://feeds.publicos.dev/media/c42eb616.1794242821.png"
      },
      {
        "type": "description",
        "value": "How PublicOS works, in depth: what things cost, the rules, every contract. For anyone, builders included."
      },
      {
        "type": "category_one",
        "value": "Education"
      }
    ]
  },
  {
    "appName": "manual",
    "displayName": "Manual",
    "ownerAccountAddress": "0x814f894Eb8F1B36b615baeCB7c4a35eBACa739bD",
    "pointers": [
      {
        "type": "url",
        "value": "https://publicos.dev/manual/"
      },
      {
        "type": "icon",
        "value": "https://feeds.publicos.dev/media/afa4e6ab.1791221928.png"
      },
      {
        "type": "description",
        "value": "Everything you need to understand PublicOS, at your own pace."
      },
      {
        "type": "category_one",
        "value": "Education"
      }
    ]
  },
  {
    "appName": "opensea",
    "displayName": "OpenSea",
    "ownerAccountAddress": "0xCC9eB2c9cB1bAB38a7cC6e756ECC5c6fe4baa70C",
    "pointers": [
      {
        "type": "icon",
        "value": "https://pbs.twimg.com/profile_images/2014958165050507264/dvbOLNLL_400x400.jpg"
      },
      {
        "type": "url",
        "value": "https://opensea.io/"
      },
      {
        "type": "description",
        "value": "The best place to discover, own, and trade onchain."
      },
      {
        "type": "category_one",
        "value": "DeFi"
      },
      {
        "type": "category_two",
        "value": "NFT"
      }
    ]
  },
  {
    "appName": "zerion",
    "displayName": "Zerion",
    "ownerAccountAddress": "0x2f786A9a909d8EC5aC3a2FB36E94517b8B84c4f4",
    "pointers": [
      {
        "type": "icon",
        "value": "https://pbs.twimg.com/profile_images/2104606501029502976/bH2RPBzs_400x400.jpg"
      },
      {
        "type": "url",
        "value": "https://app.zerion.io/"
      },
      {
        "type": "description",
        "value": "Zerion: Your Ultimate Crypto & DeFi Wallet for Solana, Ethereum & 50+ Chains. Zerion is the leading crypto wallet and web3 wallet built to manage all your assets. Our self-custodial crypto defi wallet lets you safely buy, store, swap, and track your cryptocurrency and NFTs in one powerful crypto app."
      },
      {
        "type": "category_one",
        "value": "wallet_manager"
      },
      {
        "type": "category_two",
        "value": "Web3"
      },
      {
        "type": "playstore_link",
        "value": "https://play.google.com/store/apps/details?id=io.zerion.android"
      },
      {
        "type": "appstore_link",
        "value": "https://apps.apple.com/us/app/zerion-crypto-wallet-defi/id1456732565"
      }
    ]
  }
]
''';
