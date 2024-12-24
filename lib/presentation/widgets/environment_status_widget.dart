import 'package:flutter/material.dart';

class EnvironmentStatusWidget extends StatelessWidget {
  final String status;
  const EnvironmentStatusWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Text(
      status,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.red,
      ),
      textAlign: TextAlign.center,
    );
  }
}
