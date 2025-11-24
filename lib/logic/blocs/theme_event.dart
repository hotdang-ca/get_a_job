import 'package:equatable/equatable.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class ToggleTheme extends ThemeEvent {
  const ToggleTheme();
}

class SetTheme extends ThemeEvent {
  final bool isDarkMode;

  const SetTheme(this.isDarkMode);

  @override
  List<Object?> get props => [isDarkMode];
}
