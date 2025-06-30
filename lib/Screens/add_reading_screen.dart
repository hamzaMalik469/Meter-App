import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meter_app/Screens/home_screen.dart';
import 'package:provider/provider.dart';
import '../models/meter_model.dart';
import '../providers/meter_provider.dart';

class MeterDetailScreen extends StatefulWidget {
  final MeterModel meter;

  const MeterDetailScreen({super.key, required this.meter});

  @override
  State<MeterDetailScreen> createState() => _MeterDetailScreenState();
}

class _MeterDetailScreenState extends State<MeterDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _latestReadingController = TextEditingController();
  final _dateTimeController = TextEditingController();
  DateTime? selectedDateTime;

  @override
  void dispose() {
    _latestReadingController.dispose();
    _dateTimeController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final fullDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      selectedDateTime = fullDateTime;
      _dateTimeController.text =
          DateFormat('d/M/yyyy h:mm a').format(fullDateTime);
    });
  }

  void _saveReading(BuildContext context) {
    if (!_formKey.currentState!.validate() || selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    final latestReading = double.parse(_latestReadingController.text.trim());
    final readingDateStr = _dateTimeController.text.trim();

    Provider.of<MeterProvider>(context, listen: false).updateLatestReading(
      widget.meter.id,
      latestReading,
      readingDateStr,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Reading saved successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meter = widget.meter;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Reading')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Billing Reading: ${meter.billingReading.toStringAsFixed(1)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _latestReadingController,
                decoration: const InputDecoration(labelText: 'Latest Reading'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter latest reading';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null) return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateTimeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Reading Date & Time',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDateTime(context),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Select date'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text("Save Reading"),
                  onPressed: () => _saveReading(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
