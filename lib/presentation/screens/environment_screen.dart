// lib/screens/environment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../service/eSenseService.dart'; // Aktualisierter Importpfad
import '../../logic/settings/settings_cubit.dart'; // Stelle sicher, dass SettingsCubit importiert ist
import 'dart:async';

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({Key? key}) : super(key: key);

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  final ESenseService _eSenseService = ESenseService();

  // Daten, die von ESenseService kommen
  String _deviceStatus = 'Disconnected';
  String _deviceName = 'Unknown';
  double _voltage = -1;
  String _buttonStatus = 'Not pressed';
  String _rawImuDataString = 'No data';
  double _currentMagnitude = 0.0;
  String _movementStatus = 'Ruhig';

  late StreamSubscription<String> _deviceStatusSub;
  late StreamSubscription<String> _movementStatusSub;
  late StreamSubscription<String> _buttonStatusSub;
  late StreamSubscription<Map<String, dynamic>> _dataSub;

  @override
  void initState() {
    super.initState();

    // Initialisiere den Service mit dem Gerätenamen aus den Einstellungen
    final userSpecifiedName = context.read<SettingsCubit>().state.eSenseDeviceName;
    _eSenseService.initialize(userSpecifiedName);

    // Abonniere die Streams
    _deviceStatusSub = _eSenseService.deviceStatusStream.listen((status) {
      setState(() {
        _deviceStatus = status;
      });
    });

    _movementStatusSub = _eSenseService.movementStatusStream.listen((status) {
      setState(() {
        _movementStatus = status;
      });
    });

    _buttonStatusSub = _eSenseService.buttonStatusStream.listen((status) {
      setState(() {
        _buttonStatus = status;
      });
    });

    _dataSub = _eSenseService.dataStream.listen((data) {
      setState(() {
        if (data.containsKey('deviceName')) {
          _deviceName = data['deviceName'];
        }
        if (data.containsKey('voltage')) {
          _voltage = data['voltage'];
        }
        if (data.containsKey('rawImuData')) {
          _rawImuDataString = data['rawImuData'];
        }
        if (data.containsKey('currentMagnitude')) {
          _currentMagnitude = data['currentMagnitude'];
        }
      });
    });
  }

  @override
  void dispose() {
    _deviceStatusSub.cancel();
    _movementStatusSub.cancel();
    _buttonStatusSub.cancel();
    _dataSub.cancel();
    _eSenseService.dispose(); // Rufe die dispose-Methode des ESenseService auf
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.eSenseDeviceName != current.eSenseDeviceName,
      listener: (context, state) async {
        debugPrint('SettingsCubit device name geändert zu: ${state.eSenseDeviceName}');
        await _eSenseService.disconnect();

        // Initialisiere den Service mit dem neuen Gerätenamen
        _eSenseService.initialize(state.eSenseDeviceName);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Environment - eSense IMU'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Verbindungsstatus: $_deviceStatus'),
            Text('Gerätename laut eSense: $_deviceName'),
            Text('Batterie: ${_voltage > 0 ? '${_voltage.toStringAsFixed(2)} V' : 'Unknown'}'),
            Text('Button: $_buttonStatus'),
            const SizedBox(height: 10),
            Text('Roh-IMU-Daten: $_rawImuDataString'),
            const SizedBox(height: 10),
            Text(
              'Aktuelle Magnitude: ${_currentMagnitude.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Bewegungsstatus: $_movementStatus',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _deviceStatus != 'Connected'
                  ? () {
                      final deviceName = context.read<SettingsCubit>().state.eSenseDeviceName;
                      _eSenseService.initialize(deviceName);
                    }
                  : null,
              icon: const Icon(Icons.login),
              label: const Text('Verbinden'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: (_deviceStatus != 'Connected')
                      ? null
                      : (!_eSenseService.sampling
                          ? () {
                              _eSenseService.startSensors();
                            }
                          : () {
                              _eSenseService.stopSensors();
                            }),
                  child: Text(!_eSenseService.sampling ? 'Sensor Start' : 'Sensor Stop'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _deviceStatus == 'Connected'
                      ? () async {
                          await _eSenseService.disconnect();
                          setState(() {
                            _deviceStatus = 'Disconnected';
                            _movementStatus = 'Ruhig';
                            _currentMagnitude = 0.0;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Erfolgreich getrennt.')),
                          );
                        }
                      : null,
                  child: const Text('Disconnect'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Optional: Zeige die aktuelle Standardabweichung in der UI
            // Dies könnte ebenfalls über den Service erfolgen, falls gewünscht
          ],
        ),
      ),
    );
  }
}