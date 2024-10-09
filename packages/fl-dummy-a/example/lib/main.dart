import 'package:fl_dummy_a/fl_dummy_a.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

const title = 'FL Dummy A Example';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text(title),
        ),
        body: const Center(
          child: DummyAWidget(),
        ),
      ),
    );
  }
}
