import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  static final ThemeData lightTheme = ThemeData.light().copyWith(
    primaryColor: Colors.blue,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.blue),
  );

  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: Colors.grey[900],
    appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900]!),
  );

  bool _isDark = false;

  ThemeCubit() : super(ThemeLight());

  void toggleTheme() {
    _isDark = !_isDark;
    if (_isDark) {
      emit(ThemeDark());
    } else {
      emit(ThemeLight());
    }
  }

  void setTheme(bool isDark) {
    _isDark = isDark;
    emit(_isDark ? ThemeDark() : ThemeLight());
  }
}
