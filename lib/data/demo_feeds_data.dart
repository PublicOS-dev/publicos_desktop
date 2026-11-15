/// Curated set of live external RSS/Atom feeds used to build the demo "News"
/// list (Settings → Create demo channel list).
///
/// DIRECT external sources only (no `feeds.publicos.dev` proxies), each URL
/// fetched and validated live. Titles are the outlet names. No source
/// account, so these carry no `feedFoundAtAccountAddress` provenance.
///
/// The app's feed pipeline (`RssParser.fetchFeed`) reads these directly: it
/// detects RSS/Atom XML vs JSON Feed by content-type, so no PublicOS feed
/// server is involved.
class DemoFeed {
  final String title;
  final String url;
  const DemoFeed(this.title, this.url);
}

/// The baked News feeds. To refresh: revalidate liveliness and swap this list.
const List<DemoFeed> kDemoNewsFeeds = [
  DemoFeed('Android Authority', 'https://www.androidauthority.com/feed'),
  DemoFeed('Ars Technica', 'https://feeds.arstechnica.com/arstechnica/index'),
  DemoFeed('CoinDesk', 'https://www.coindesk.com/arc/outboundfeeds/rss/'),
  DemoFeed('Cointelegraph', 'https://cointelegraph.com/rss'),
  DemoFeed('Compound', 'https://medium.com/feed/compound-finance'),
  DemoFeed('Decrypt', 'https://decrypt.co/feed'),
  DemoFeed('Expansión', 'https://expansion.mx/rss'),
  DemoFeed('Futurism', 'https://futurism.com/feed'),
  DemoFeed('George R. R. Martin', 'https://georgerrmartin.com/notablog/feed/'),
  DemoFeed('MetaMask', 'https://metamask.io/news-rss.xml'),
  DemoFeed('TechCrunch', 'https://techcrunch.com/feed/'),
  DemoFeed('The Block', 'https://www.theblock.co/rss.xml'),
  DemoFeed('The Verge', 'https://www.theverge.com/rss/index.xml'),
  DemoFeed('Vitalik Buterin', 'https://vitalik.eth.limo/feed.xml'),
  DemoFeed('Wired', 'https://www.wired.com/feed/rss'),
  DemoFeed('Zerion', 'https://zerion.io/blog/rss/'),
  DemoFeed('Apple Newsroom', 'https://www.apple.com/newsroom/rss-feed.rss'),
  DemoFeed('Disney', 'https://thewaltdisneycompany.com/feed/'),
  DemoFeed('Ethereum Foundation', 'https://blog.ethereum.org/feed.xml'),
  DemoFeed('Microsoft', 'https://blogs.microsoft.com/feed/'),
];
