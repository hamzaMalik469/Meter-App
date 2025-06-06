import 'package:flutter/material.dart';
import 'package:meter_app/Screens/home_screen.dart';
import 'package:provider/provider.dart';
import '../providers/meter_provider.dart';

class AddMeterScreen extends StatelessWidget {
  const AddMeterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final billingDateController = TextEditingController();
    final billingReadingController = TextEditingController();
    final meterProvider = Provider.of<MeterProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Meter')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AddMeterForm(
            formKey: _formKey,
            nameController: nameController,
            numberController: numberController,
            billingDateController: billingDateController,
            billingReadingController: billingReadingController,
            meterProvider: meterProvider),
      ),
    );
  }
}

class AddMeterForm extends StatelessWidget {
  const AddMeterForm({
    super.key,
    required GlobalKey<FormState> formKey,
    required this.nameController,
    required this.numberController,
    required this.billingDateController,
    required this.billingReadingController,
    required this.meterProvider,
  }) : _formKey = formKey;

  final GlobalKey<FormState> _formKey;
  final TextEditingController nameController;
  final TextEditingController numberController;
  final TextEditingController billingDateController;
  final TextEditingController billingReadingController;
  final MeterProvider meterProvider;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      billingDateController.text =
          "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Meter Name'),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter meter name' : null,
          ),
          TextFormField(
            controller: numberController,
            decoration: const InputDecoration(labelText: 'Meter Number'),
            validator: (value) =>
                value == null || value.isEmpty ? 'Enter meter number' : null,
          ),
          TextFormField(
            controller: billingDateController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Billing Date',
              suffixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () => _selectDate(context),
            validator: (value) =>
                value == null || value.isEmpty ? 'Select billing date' : null,
          ),
          TextFormField(
            controller: billingReadingController,
            decoration: const InputDecoration(labelText: 'Billing Reading'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Enter billing reading';
              }
              final reading = double.tryParse(value);
              if (reading == null) {
                return 'Enter a valid number';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                meterProvider.addMeter(
                  nameController.text,
                  numberController.text,
                  billingDateController.text,
                  double.parse(billingReadingController.text),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Save Meter'),
          )
        ],
      ),
    );
  }
}
