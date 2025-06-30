import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:meter_app/models/meter_model.dart';
import 'package:meter_app/providers/meter_provider.dart';
import 'package:meter_app/Screens/add_reading_screen.dart';
import 'package:provider/provider.dart';

class ReadingsScreen extends StatefulWidget {
  final MeterModel meter;

  const ReadingsScreen({super.key, required this.meter});

  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> {
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      Provider.of<MeterProvider>(context, listen: false)
          .fetchReadings(widget.meter.id);
      _isInitialized = true;
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    String docId,
    double currentReading,
    String currentDate,
  ) async {
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
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Latest Reading"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: dateController,
              readOnly: true,
              onTap: () async {
                final now = DateTime.now();
                final initialDate = now;
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initialDate,
                  firstDate: DateTime(now.year - 1),
                  lastDate: DateTime(now.year + 1),
                );
                if (picked != null) {
                  final formatted = DateFormat('d/M/yyyy').format(picked);
                  dateController.text = formatted;
                }
              },
              decoration: const InputDecoration(
                labelText: "Reading Date",
                suffixIcon: Icon(Icons.calendar_today),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              final updatedReading = double.tryParse(readingController.text);
              final updatedDate = dateController.text;

              if (updatedReading != null && updatedDate.isNotEmpty) {
                Provider.of<MeterProvider>(context, listen: false).editReading(
                  meterId: widget.meter.id,
                  docId: docId,
                  latestReading: updatedReading,
                  readingDate: updatedDate,
                );
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Reading updated successfully")));
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (result == true) {
      // UI already updates via Provider notifyListeners()
    }
  }

  String formatDateTime(String input) {
    try {
      final dateTime = DateFormat('d/M/yyyy h:mm a').parse(input);
      return DateFormat("d MMMM, h:mm a").format(dateTime);
    } catch (_) {
      try {
        final dateTime = DateFormat('d/M/yyyy').parse(input);
        return DateFormat("d MMMM yyyy").format(dateTime);
      } catch (_) {
        return input;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meter Readings')),
      body: Consumer<MeterProvider>(
        builder: (context, provider, _) {
          if (provider.isError) {
            return const Center(child: Text('Error fetching readings.'));
          }

          if (provider.readings.isEmpty) {
            return const Center(child: Text('No readings found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: provider.readings.length,
            itemBuilder: (context, index) {
              final reading = provider.readings[index];
              final dateTime = formatDateTime(reading.readingDate);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.flash_on,
                      color: Colors.orange, size: 32),
                  title: Text(
                    'Reading: ${reading.latestReading.toStringAsFixed(1)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        dateTime,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Units: ${reading.consumedUnits.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditDialog(context, reading.id,
                              reading.latestReading, reading.readingDate);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await provider.deleteReading(
                              widget.meter.id, reading.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Reading deleted")),
                          );
                        },
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
              builder: (_) => MeterDetailScreen(meter: widget.meter),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
