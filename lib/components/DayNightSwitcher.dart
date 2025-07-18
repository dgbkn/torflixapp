// file: lib/components/day_night_switcher.dart

import 'package:flutter/material.dart';

/// A customizable, animated widget that toggles between light and dark mode icons.
///
/// This component is designed to be placed in an AppBar or any other part of the UI.
/// It receives the current dark mode state and a callback function to notify the parent
/// widget of a change, allowing the parent to rebuild with the new theme.
class DayNightSwitcher extends StatelessWidget {
  /// A boolean that determines which icon to show.
  /// `true` for dark mode (shows a sun icon), `false` for light mode (shows a moon icon).
  final bool isDarkModeEnabled;

  /// The callback function that is invoked when the switcher is tapped.
  /// It passes the new state of the dark mode.
  final Function(bool) onStateChanged;

  const DayNightSwitcher({
    Key? key,
    required this.isDarkModeEnabled,
    required this.onStateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip:
          isDarkModeEnabled ? 'Switch to Light Mode' : 'Switch to Dark Mode',
      onPressed: () => onStateChanged(!isDarkModeEnabled),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return RotationTransition(
            turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: isDarkModeEnabled
            ? const Icon(
                Icons.wb_sunny_rounded,
                // The key is essential for the AnimatedSwitcher to know which widget is new.
                key: ValueKey('sun'),
                color: Colors.amber,
              )
            : const Icon(
                Icons.nightlight_round,
                // The key is essential for the AnimatedSwitcher to know which widget is new.
                key: ValueKey('moon'),
                color: Colors.blueGrey,
              ),
      ),
    );
  }
}
