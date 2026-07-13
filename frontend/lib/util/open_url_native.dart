import 'package:url_launcher/url_launcher.dart';

Future<void> openInBrowser(String url) async {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
