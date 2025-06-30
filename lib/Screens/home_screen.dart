import 'package:flutter/material.dart';
import 'package:meter_app/screens/add_meter_screen.dart';
import 'package:meter_app/models/meter_model.dart';
import 'package:meter_app/providers/meter_provider.dart';
import '../Providers/auth_provider.dart';
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
      final provider = Provider.of<MeterProvider>(context, listen: false);
      provider.fetchMeters();
      provider.syncAllData();
      _isInitialized = true;
    }
  }

  void _showEditMeterDialog(BuildContext context, MeterModel meter) {
    final nameController = TextEditingController(text: meter.name);
    final numberController = TextEditingController(text: meter.number);
    final billingDateController =
        TextEditingController(text: meter.billingDate);
    final billingReadingController =
        TextEditingController(text: meter.billingReading.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Meter"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField(nameController, "Name", Icons.edit),
              const SizedBox(height: 10),
              _buildTextField(
                  numberController, "Number", Icons.confirmation_number),
              const SizedBox(height: 10),
              _buildTextField(
                  billingDateController, "Billing Date", Icons.date_range),
              const SizedBox(height: 10),
              _buildTextField(
                  billingReadingController, "Billing Reading", Icons.speed,
                  isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedBillingReading =
                  double.tryParse(billingReadingController.text.trim()) ??
                      meter.billingReading;

              final updatedMeter = MeterModel(
                id: meter.id,
                name: nameController.text.trim(),
                number: numberController.text.trim(),
                billingDate: billingDateController.text.trim(),
                billingReading: updatedBillingReading,
                latestReading: meter.latestReading,
                consumedUnits: meter.latestReading - updatedBillingReading,
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
        title: const Text("Delete Meter"),
        content: const Text(
            "Are you sure you want to delete this meter and all its readings?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<MeterProvider>(context, listen: false)
                  .deleteMeter(meterId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Do you really want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<AuthProvider>(context, listen: false)
                    .logout();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Logout failed: $e")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Meters"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: Consumer<MeterProvider>(
        builder: (context, provider, child) {
          if (provider.meters.isEmpty) {
            return const Center(child: Text("No meters added yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: provider.meters.length,
            itemBuilder: (context, index) {
              final meter = provider.meters[index];
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Stack(
                  children: [
                    MeterTile(meter: meter),
                    Positioned(
                      top: 8,
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
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMeterScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Meter"),
      ),
    );
  }
}
