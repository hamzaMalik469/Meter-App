import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:meter_app/Screens/mepco_bill_page.dart';
import 'package:meter_app/models/meter_model.dart';
import 'package:meter_app/Screens/all_reading_screen.dart';
import 'package:meter_app/providers/meter_provider.dart';
import 'package:provider/provider.dart';

class MeterTile extends StatelessWidget {
  final MeterModel meter;

  const MeterTile({super.key, required this.meter});

  int calculateRemainingDays(DateTime billingDate) {
    final now = DateTime.now();
    final nextBillingDate = DateTime(now.year, now.month, billingDate.day);
    final targetDate = nextBillingDate.isBefore(now)
        ? DateTime(now.year, now.month + 1, billingDate.day)
        : nextBillingDate;
    return targetDate.difference(now).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Dynamic font sizes
    final double titleFont = screenWidth * 0.045; // ~16–18
    final double subtitleFont = screenWidth * 0.038; // ~13–15
    final double smallFont = screenWidth * 0.032; // ~11–13

    String formatDateTime(String input) {
      try {
        final DateTime dateTime = DateFormat('d/M/yyyy h:mm a').parse(input);
        return DateFormat("d MMM h:mm a").format(dateTime);
      } catch (e) {
        final DateTime dateTime = DateFormat('d/M/yyyy').parse(input);
        return DateFormat("d MMM").format(dateTime);
      }
    }

    DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(meter.billingDate);
    int remainingDays = calculateRemainingDays(parsedDate);
    final dateTime = formatDateTime(meter.billingDate);

    return Card(
      elevation: 6,
      shadowColor: Colors.blue.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReadingsScreen(meter: meter)),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column
                  Column(
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: meter.isOn,
                          onChanged: (value) {
                            Provider.of<MeterProvider>(context, listen: false)
                                .toggleMeterStatus(meter.id, value);
                            Provider.of<MeterProvider>(context, listen: false)
                                .fetchMeters();
                          },
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade300,
                              Colors.blue.shade600
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.bolt,
                            color: Colors.white, size: screenWidth * 0.07),
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      Text(
                        meter.consumedUnits < 0
                            ? "0"
                            : meter.consumedUnits.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: subtitleFont,
                          color: meter.consumedUnits > 180
                              ? Colors.red
                              : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(width: screenWidth * 0.04),

                  // Expanded Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                meter.name,
                                style: TextStyle(
                                  fontSize: titleFont,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                Provider.of<MeterProvider>(context,
                                        listen: false)
                                    .toggleMeterPinStatus(
                                        meter.id, !meter.isPin);
                                Provider.of<MeterProvider>(context,
                                        listen: false)
                                    .fetchMeters();
                              },
                              icon: Icon(
                                meter.isPin
                                    ? Icons.push_pin
                                    : Icons.push_pin_outlined,
                                color: meter.isPin
                                    ? Colors.blueAccent
                                    : Colors.grey,
                                size: screenWidth * 0.055,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text("# ${meter.number}",
                                style: TextStyle(fontSize: subtitleFont)),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.copy,
                                  color: Colors.blue,
                                  size: screenWidth * 0.045),
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: meter.number));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied to clipboard!'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              tooltip: 'Copy Number',
                            )
                          ],
                        ),
                        _buildInfoRow(
                            Icons.speed,
                            "Reading: ${meter.billingReading.toStringAsFixed(0)}",
                            subtitleFont),
                        _buildInfoRow(Icons.calendar_today,
                            "Billing: $dateTime", subtitleFont),
                        _buildInfoRow(
                          Icons.access_time,
                          "Due in: $remainingDays days",
                          subtitleFont,
                          color: remainingDays <= 3
                              ? Colors.red
                              : Colors.green[700],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenWidth * 0.04),

              // Bill Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long),
                  label: const Text("View MEPCO Bill"),
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: screenWidth * 0.035),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    textStyle: TextStyle(fontSize: subtitleFont),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MepcoBillLauncher(referenceNumber: meter.number),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, double fontSize,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: fontSize + 1, color: Colors.grey),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
