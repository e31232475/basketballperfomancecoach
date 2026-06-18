import 'package:flutter/material.dart';

import 'workout_day_detail_screen.dart';

class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({
    super.key,
    required this.dayNumber,
  });

  final int dayNumber;

  @override
  Widget build(BuildContext context) {
    return WorkoutDayDetailScreen(dayNumber: dayNumber);
  }
}
