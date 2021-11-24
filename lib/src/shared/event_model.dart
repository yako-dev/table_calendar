import 'package:flutter/material.dart';

class EventModel {
  final String id;
  final String title;
  final DateTime startDate;
  final Color? color;
  final TextStyle? titleStyle;
  final DateTime? endDate;

  EventModel({
    required this.id,
    required this.title,
    required this.startDate,
    this.color,
    this.titleStyle,
    this.endDate,
  });

  DateTime get endDateCalc => endDate ?? startDate;
}

enum EventType { start, end, full, only }
