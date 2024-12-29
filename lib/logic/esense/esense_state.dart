part of 'esense_cubit.dart';

/// Basis-Klasse für alle eSense-States
abstract class ESenseConnectionState {}

/// Anfangszustand: Noch nichts gemacht
class ESenseConnectionInitial extends ESenseConnectionState {}

/// Zeigt an, dass wir versuchen, uns zu verbinden
class ESenseConnectionConnecting extends ESenseConnectionState {}

/// Wenn wir verbunden sind
class ESenseConnectionConnected extends ESenseConnectionState {}

/// Wenn die Verbindung getrennt (oder nie hergestellt) ist
class ESenseConnectionDisconnected extends ESenseConnectionState {}

/// Ein Fehlerzustand (z.B. wenn Connect fehlschlägt)
class ESenseConnectionError extends ESenseConnectionState {
  final String message;
  ESenseConnectionError(this.message);
}
