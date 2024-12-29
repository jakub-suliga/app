import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Eigene Imports
import 'data/data_providers/esense_scanner.dart';
import 'data/data_providers/esense_data_provider.dart';
import 'data/repositories/esense_repository.dart';
import 'logic/esense/esense_cubit.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Scanner + DataProvider + Repository
  final scanner = ESenseScanner();
  final dataProvider = ESenseDataProvider();
  final repository = ESenseRepository(
    scanner: scanner,
    dataProvider: dataProvider,
  );

  runApp(
    BlocProvider<ESenseCubit>(
      create: (_) => ESenseCubit(esenseRepo: repository),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eSense + flutter_reactive_ble Demo',
      home: BlocBuilder<ESenseCubit, ESenseState>(
        builder: (ctx, state) {
          return Scaffold(
            appBar: AppBar(title: const Text('Scan & Connect eSense')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (state is ESenseConnecting) const CircularProgressIndicator(),
                  if (state is ESenseConnected)
                    const Text('eSense: CONNECTED', style: TextStyle(color: Colors.green)),
                  if (state is ESenseError)
                    Text('Fehler: ${state.message}', style: const TextStyle(color: Colors.red)),
                  if (state is ESenseDisconnected)
                    const Text('Disconnected', style: TextStyle(color: Colors.grey)),
                  if (state is ESenseInitial)
                    const Text('Initial State'),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Nur aufrufen, wenn nicht gerade connected/connecting
                      if (state is ESenseConnected || state is ESenseConnecting) return;
                      context.read<ESenseCubit>().connectToESense();
                    },
                    child: const Text('Scan & Connect'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => context.read<ESenseCubit>().disconnectESense(),
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
