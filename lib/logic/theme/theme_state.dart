part of 'theme_cubit.dart';

abstract class ThemeState {
  ThemeData get themeData;
}

class ThemeLight extends ThemeState {
  @override
  ThemeData get themeData => ThemeCubit.lightTheme;
}

class ThemeDark extends ThemeState {
  @override
  ThemeData get themeData => ThemeCubit.darkTheme;
}
