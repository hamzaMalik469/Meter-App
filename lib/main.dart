import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:meter_app/models/meter_model.dart';
import 'package:meter_app/models/reading_model.dart';
import 'package:meter_app/Providers/auth_gate.dart';
import 'package:meter_app/providers/meter_provider.dart';
import 'package:provider/provider.dart';
import 'Providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();

  Hive.registerAdapter(MeterModelAdapter());
  Hive.registerAdapter(ReadingModelAdapter());

  final meterBox = await Hive.openBox<MeterModel>('meters');
  final readingBox = await Hive.openBox<ReadingModel>('readings');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => MeterProvider(
            meterBox: meterBox,
            readingBox: readingBox,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meter App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
    );
  }
}
