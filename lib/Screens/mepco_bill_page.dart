import 'package:flutter/material.dart';
import 'package:meter_app/Screens/mepco_bill_selector.dart';
import 'package:url_launcher/url_launcher.dart';

class MepcoBillLauncher extends StatelessWidget {
  final String referenceNumber;
  const MepcoBillLauncher({super.key, required this.referenceNumber});

  Future<void> _launchBill() async {
    final url = Uri.parse("https://mepcobill.pk/");
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication, // Opens in browser
    )) {
      throw Exception("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MEPCO Bill Viewer")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MepcoBillWebView(referenceNumber: referenceNumber),
                    ));
              },
              child: const Text("Open MEPCO Bill Here"),
            ),
            ElevatedButton(
              onPressed: _launchBill,
              child: const Text("Open MEPCO Bill Website"),
            ),
          ],
        ),
      ),
    );
  }
}
