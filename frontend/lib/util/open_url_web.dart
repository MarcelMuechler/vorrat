// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
// This file is only ever compiled in on web (see open_url.dart's conditional
// export), so dart:html is exactly the right tool here despite the lints
// meant to steer plugin code away from it.
import 'dart:html' as html;

/// A direct DOM anchor click, synchronous JS interop with no platform-channel
/// round trip -- unlike url_launcher (whose async channel call breaks the
/// browser's user-gesture chain for the popup/download it triggers), this
/// stays within the same click event and isn't popup-blocked.
Future<void> openInBrowser(String url) async {
  html.AnchorElement(href: url)
    ..target = '_blank'
    ..click();
}
