import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meter_app/models/meter_model.dart';
import 'package:meter_app/Screens/all_reading_screen.dart';

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
      // Parse original format
      try {
        final DateTime dateTime = DateFormat('d/M/yyyy h:mm a').parse(input);
        return DateFormat("d MMMM h:mm a").format(dateTime);
      } catch (e) {
        final DateTime dateTime = DateFormat('d/M/yyyy').parse(input);
        return DateFormat("d MMMM").format(dateTime);
      }

      // Format to desired output
    }

    DateTime parsedDate = DateFormat('dd/MM/yyyy').parse(meter.billingDate);
    int remainingDays = calculateRemainingDays(parsedDate);
    final dateTime = formatDateTime(meter.billingDate);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        tileColor: Colors.grey[200],
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("This Month Units"),
            Text(
              meter.consumedUnits.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                dateTime,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            )
          ],
        ),
        title: Text(
          meter.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meter.number,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            Text(
              "Bill Reading: ${meter.billingReading.toStringAsFixed(1)}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Days Left: $remainingDays days",
              style: TextStyle(
                fontSize: 13,
                color: remainingDays <= 3 ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.blueAccent,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReadingsScreen(meter: meter),
            ),
          );
        },
      ),
    );
  }
}
