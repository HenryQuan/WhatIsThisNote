import 'package:flutter/material.dart';

/// A small uppercase heading used to separate related settings and menu items.
class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
