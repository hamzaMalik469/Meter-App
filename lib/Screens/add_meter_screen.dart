import 'package:flutter/material.dart';
import 'package:meter_app/Screens/home_screen.dart';
import 'package:provider/provider.dart';
import '../providers/meter_provider.dart';

class AddMeterScreen extends StatelessWidget {
  const AddMeterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Meter')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: AddMeterForm(),
      ),
    );
  }
}

class AddMeterForm extends StatefulWidget {
  const AddMeterForm({super.key});

  @override
  State<AddMeterForm> createState() => _AddMeterFormState();
}

class _AddMeterFormState extends State<AddMeterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _billingDateController = TextEditingController();
  final _billingReadingController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _billingDateController.dispose();
    _billingReadingController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _billingDateController.text =
          "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  void _saveMeter(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<MeterProvider>(context, listen: false);

      provider.addMeter(
        _nameController.text.trim(),
        _numberController.text.trim(),
        _billingDateController.text.trim(),
        double.parse(_billingReadingController.text.trim()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Meter added successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Meter Name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter meter name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _numberController,
              decoration: const InputDecoration(labelText: 'Meter Number'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter meter number' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _billingDateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              decoration: const InputDecoration(
                labelText: 'Billing Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Select billing date' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _billingReadingController,
              decoration: const InputDecoration(labelText: 'Billing Reading'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter billing reading';
                }
                final reading = double.tryParse(value);
                return reading == null ? 'Enter valid number' : null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Meter"),
                onPressed: () => _saveMeter(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
