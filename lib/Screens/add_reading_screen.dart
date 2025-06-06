import 'package:flutter/material.dart';
import 'package:meter_app/Screens/home_screen.dart';
import 'package:provider/provider.dart';
import '../models/meter_model.dart';
import '../providers/meter_provider.dart';

class MeterDetailScreen extends StatefulWidget {
  const MeterDetailScreen({super.key, required this.meter});

  final MeterModel meter;
  @override
  _MeterDetailScreenState createState() => _MeterDetailScreenState();
}

class _MeterDetailScreenState extends State<MeterDetailScreen> {
  late TextEditingController latestReadingController;
  late TextEditingController dateTimeController;
  DateTime? selectedDateTime;

  @override
  void initState() {
    super.initState();
    latestReadingController = TextEditingController();
    dateTimeController = TextEditingController();
  }

  @override
  void dispose() {
    latestReadingController.dispose();
    dateTimeController.dispose();
    super.dispose();
  }

  // Select date and time
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          selectedDateTime = fullDateTime;
          dateTimeController.text =
              '${pickedDate.day}/${pickedDate.month}/${pickedDate.year} '
              '${pickedTime.format(context)}';
        });
      }
    }
  }

  // Save the reading
  void _saveMeter(BuildContext context) {
    if (latestReadingController.text.isEmpty ||
        dateTimeController.text.isEmpty ||
        selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields!')),
      );
      return;
    }

    final latestReading = double.parse(latestReadingController.text);

    Provider.of<MeterProvider>(context, listen: false).updateLatestReading(
      widget.meter.id,
      latestReading,
      dateTimeController.text, // Store formatted date-time string
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reading saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meter = widget.meter;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Reading')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Billing Reading: ${meter.billingReading}'),
            const SizedBox(height: 10),
            TextField(
              controller: latestReadingController,
              decoration: const InputDecoration(labelText: 'Latest Reading'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: dateTimeController,
              decoration: const InputDecoration(
                labelText: 'Reading Date & Time',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () => _selectDateTime(context),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _saveMeter(context),
              child: const Text('Calculate & Save'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
