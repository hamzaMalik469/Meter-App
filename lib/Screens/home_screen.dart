import 'package:flutter/material.dart';
import 'package:meter_app/Screens/add_meter_screen.dart';
import 'package:meter_app/models/meter_model.dart';
import 'package:meter_app/providers/meter_provider.dart';
import 'package:meter_app/widgets/meter_tile.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      Provider.of<MeterProvider>(context, listen: false).fetchMeters();
      _isInitialized = true;
    }
  }

  void _showEditMeterDialog(BuildContext context, MeterModel meter) {
    final nameController = TextEditingController(text: meter.name);
    final numberController = TextEditingController(text: meter.number);
    final billingDateController =
        TextEditingController(text: meter.billingDate);
    final billingReadingController =
        TextEditingController(text: meter.billingReading.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Meter"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Name")),
              TextField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: "Number")),
              TextField(
                  controller: billingDateController,
                  decoration: const InputDecoration(labelText: "Billing Date")),
              TextField(
                controller: billingReadingController,
                decoration: const InputDecoration(labelText: "Billing Reading"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final updatedMeter = MeterModel(
                id: meter.id,
                name: nameController.text,
                number: numberController.text,
                billingDate: billingDateController.text,
                billingReading:
                    double.tryParse(billingReadingController.text) ??
                        meter.billingReading,
                latestReading: meter.latestReading,
                consumedUnits: 0.0,
                readingDate: meter.readingDate,
              );
              Provider.of<MeterProvider>(context, listen: false)
                  .updateMeter(updatedMeter);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMeter(BuildContext context, String meterId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text(
            "Are you sure you want to delete this meter? This will also delete its readings."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<MeterProvider>(context, listen: false)
                  .deleteMeter(meterId);
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meters"),
        centerTitle: false,
      ),
      body: Consumer<MeterProvider>(
        builder: (context, provider, child) {
          return provider.meters.isEmpty
              ? const Center(child: Text("No Meter Added"))
              : ListView.builder(
                  itemCount: provider.meters.length,
                  itemBuilder: (context, index) {
                    final meter = provider.meters[index];
                    return Stack(
                      children: [
                        MeterTile(meter: meter),
                        Positioned(
                          top: 0,
                          right: 8,
                          child: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditMeterDialog(context, meter);
                              } else if (value == 'delete') {
                                _confirmDeleteMeter(context, meter.id);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddMeterScreen()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
