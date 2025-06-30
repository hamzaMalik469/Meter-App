import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReadingsScreen(meter: meter),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left Meter Icon Column
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.speed, color: Colors.blue, size: 28),
              ),

              const SizedBox(width: 16),

              // Expanded Meter Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meter.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meter.number,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.bolt, size: 16, color: Colors.orange),
                        const SizedBox(width: 6),
                        Consumer<MeterProvider>(
                          builder: (BuildContext context, MeterProvider value,
                              Widget? child) {
                            return Text(
                              "Used: ${meter.consumedUnits.toStringAsFixed(1)} units",
                              style: const TextStyle(fontSize: 14),
                            );
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "Billing: $dateTime",
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          "Due in: $remainingDays days",
                          style: TextStyle(
                            fontSize: 13,
                            color: remainingDays <= 3
                                ? Colors.red
                                : Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Trailing Navigation Arrow
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
