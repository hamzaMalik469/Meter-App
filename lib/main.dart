import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:meter_app/Screens/home_screen.dart';
import 'package:meter_app/providers/meter_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MeterProvider(),
          child: const MyApp(), // Wrap the whole app here
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meter App',
      home: HomeScreen(),
    );
  }
}
