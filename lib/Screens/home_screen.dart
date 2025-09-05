import 'package:flutter/material.dart';
import 'package:meter_app/Screens/drawer.dart';
import 'package:meter_app/screens/add_meter_screen.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeterProvider>().init();
    });
  }

  void _showEditMeterDialog(BuildContext context, MeterModel meter) {
    final nameController = TextEditingController(text: meter.name);
    final ownerController = TextEditingController(text: meter.owner);
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
              _buildTextField(ownerController, "owner", Icons.person),
              const SizedBox(height: 10),
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
                owner: ownerController.text.trim(),
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
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text("Meters"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Consumer<MeterProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.owners.isEmpty) {
            return const Center(child: Text("No owners added yet."));
          }

          // If no owner selected yet, pick first by default
          String? selectedOwnerId = provider.selectedOwner;

          // Get meters only for the selected owner
          final ownerMeters = provider.getMetersByOwner(selectedOwnerId!);

          return Column(
            children: [
              // 🔹 Owner Dropdown
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, Colors.lightBlueAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: provider.selectedOwner,
                        hint: const Text(
                          "Select Owner",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white, size: 28),
                        dropdownColor: Colors.white,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        items: provider.owners.map((owner) {
                          return DropdownMenuItem<String>(
                            value: owner,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: const Icon(Icons.person,
                                      color: Colors.blue),
                                ),
                                const SizedBox(width: 12),
                                Text(owner,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            provider.setSelectedOwner(value);
                          }
                        },
                      ),
                    ),
                  )),
              // 🔹 Meters List (filtered by owner)
              if (ownerMeters.isEmpty)
                const Center(child: Text("No meters for this owner."))
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: ownerMeters.length,
                    itemBuilder: (context, index) {
                      final meter = ownerMeters[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Stack(
                          children: [
                            MeterTile(meter: meter),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: PopupMenuButton<String>(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.grey,
                                ),
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
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue),
                                        SizedBox(width: 10),
                                        Text(
                                          'Edit',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 10),
                                        Text(
                                          'Delete',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
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
        backgroundColor: Colors.blue.withOpacity(0.7),
      ),
    );
  }
}
