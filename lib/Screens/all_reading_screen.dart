import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meter_app/models/meter_model.dart';
import 'package:meter_app/Providers/meter_provider.dart';
import 'package:meter_app/Screens/add_reading_screen.dart';
import 'package:provider/provider.dart';

class ReadingsScreen extends StatefulWidget {
  final MeterModel meter;

  const ReadingsScreen({super.key, required this.meter});

  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> {
  late MeterProvider _meterProvider;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _meterProvider = MeterProvider();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _meterProvider.fetchReadings(widget.meter.id);
      _isInitialized = true;
    }
  }

  Future<void> _showEditDialog(BuildContext context, String docId,
      double currentReading, String currentDate) async {
    final readingController =
        TextEditingController(text: currentReading.toString());
    final dateController = TextEditingController(text: currentDate);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Reading"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: readingController,
              decoration: const InputDecoration(labelText: "Latest Reading"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Reading Date"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedReading = double.tryParse(readingController.text);
              final updatedDate = dateController.text;
              if (updatedReading != null) {
                _meterProvider.editReading(
                  meterId: widget.meter.id,
                  docId: docId,
                  latestReading: updatedReading,
                  readingDate: updatedDate,
                );
              }
              Navigator.pop(context, true);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MeterProvider>.value(
      value: _meterProvider,
      child: Scaffold(
        appBar: AppBar(title: const Text('Meter Readings')),
        body: Consumer<MeterProvider>(
          builder: (context, meterProvider, child) {
            if (meterProvider.isError) {
              return const Center(child: Text('Error fetching readings.'));
            }

            if (meterProvider.readings.isEmpty) {
              return const Center(child: Text('No readings found.'));
            }

            return ListView.builder(
              itemCount: meterProvider.readings.length,
              itemBuilder: (context, index) {
                final reading = meterProvider.readings[index];
                final docId = reading.id; // ReadingModel should contain `id`

                final dateTime = formatDateTime(reading.readingDate);

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on,
                            color: Colors.orange, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reading: ${reading.latestReading.toStringAsFixed(1)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                dateTime,
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Consumed Units: ${reading.consumedUnits.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                _showEditDialog(context, docId,
                                    reading.latestReading, reading.readingDate);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _meterProvider.deleteReading(
                                    widget.meter.id, docId);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MeterDetailScreen(meter: widget.meter),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
