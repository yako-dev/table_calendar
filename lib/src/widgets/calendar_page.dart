// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rect_getter/rect_getter.dart';
import 'package:table_calendar/src/shared/event_model.dart';
import 'package:table_calendar/src/shared/utils.dart';

class CalendarPage extends StatefulWidget {
  final Widget Function(BuildContext context, DateTime day)? dowBuilder;
  final Widget Function(BuildContext context, DateTime day) dayBuilder;
  final List<DateTime> visibleDays;
  final Decoration? dowDecoration;
  final Decoration? rowDecoration;
  final TableBorder? tableBorder;
  final bool dowVisible;
  final double? height;
  final int maxEventsCount;
  final List<EventModel>? events;
  final Function(List<EventModel>)? onMoreTap;
  final Function(EventModel)? onEventTap;
  final double eventVerticalPadding;
  final double eventMaxHeight;
  final double eventIndent;
  final WeekEventBuilder? weekEventBuilder;
  final MoreBuilder? moreBuilder;

  const CalendarPage({
    Key? key,
    required this.visibleDays,
    this.dowBuilder,
    required this.dayBuilder,
    this.dowDecoration,
    this.rowDecoration,
    this.tableBorder,
    this.dowVisible = true,
    this.height,
    this.events,
    this.maxEventsCount = 4,
    this.eventVerticalPadding = 4,
    this.eventMaxHeight = 15,
    this.eventIndent = 20,
    this.onEventTap,
    this.onMoreTap,
    this.weekEventBuilder,
    this.moreBuilder,
  })  : assert(!dowVisible || dowBuilder != null),
        super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final _weekLength = 7;
  int _maxCellPositions = 4;
  late final List<EventModel> _allEvents;

  @override
  void initState() {
    _allEvents = widget.events ?? [];
    _allEvents.sort((a, b) => a.startDate.compareTo(b.startDate));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (widget.dowVisible) _buildDaysOfWeek(),
      ..._buildCalendarDays(),
    ]);
  }

  Widget _buildDaysOfWeek() {
    return Row(
      children: List.generate(
        _weekLength,
        (i) =>
            Flexible(child: widget.dowBuilder!(context, widget.visibleDays[i])),
      ).toList(),
    );
  }

  List<Widget> _buildCalendarDays() {
    final rowAmount = widget.visibleDays.length ~/ _weekLength;
    return List.generate(rowAmount, (i) => i * _weekLength)
        .map(_buildWeek)
        .toList();
  }

  Widget _buildWeek(int week) {
    final children = <Widget>[];

    final cellKeys =
        List.generate(_weekLength, (index) => RectGetter.createGlobalKey());

    children.add(Row(
      children: List.generate(
        _weekLength,
        (i) => RectGetter(
          key: cellKeys[i],
          child: Flexible(child: _buildDay(widget.visibleDays[week + i])),
        ),
      ),
    ));

    return FutureBuilder<List<Widget>>(
      future: _buildEventLine(week, cellKeys),
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          //TODO add appear animation
          return Flexible(
            child: Stack(children: [...children, ...snapshot.data!]),
          );
        } else {
          return Flexible(child: Stack(children: children));
        }
      },
    );
  }

  Future<List<Widget>> _buildEventLine(int week, cellKeys) async {
    // Animation duration
    await Future.delayed(Duration(microseconds: 100));

    final resultList = <Widget>[];
    _maxCellPositions = widget.maxEventsCount;

    final weekEvents = <EventModel>[];
    final firstWeekDay = widget.visibleDays[week];
    final lastWeekDay = widget.visibleDays[week + _weekLength - 1];

    for (final e in _allEvents) {
      final startDate = e.startDate;
      final endDate = e.endDateCalc;
      final isEndDateInWeekRange =
          endDate.isAfter(firstWeekDay) || isSameDay(endDate, firstWeekDay);
      final isFirstDateInWeekRange =
          startDate.isBefore(lastWeekDay) || isSameDay(startDate, lastWeekDay);
      if (isEndDateInWeekRange && isFirstDateInWeekRange) {
        weekEvents.add(e);
      }
    }

    weekEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

    // Build week events

    final double eventAvailableHeight =
        (widget.height! - widget.eventIndent - 10) / _maxCellPositions -
            widget.eventVerticalPadding;
    final double itemHeight = eventAvailableHeight > widget.eventMaxHeight
        ? widget.eventMaxHeight
        : eventAvailableHeight;

    final eventAsMap = <String, List<int>>{};

    // Map of used indexes on cell position
    final registeredWeekIndexes = <int, List<int>>{};
    final eventPositionInCell = <String, int>{};

    for (final e in weekEvents) {
      for (var index = 0; index < _weekLength; index++) {
        if (_dayHasEvent(widget.visibleDays[week + index], e)) {
          final list = eventAsMap[e.id] ?? [];
          eventAsMap[e.id] = list..add(index);
        }
      }
    }

    // Define does week contains more items
    var moreItemsExist = false;
    var moreEventsIds = <String>[];

    for (final id in eventAsMap.keys) {
      for (var i = 0; i < _maxCellPositions + 1; i++) {
        var firstList = registeredWeekIndexes[i] ?? [];
        var secondList = eventAsMap[id]!;

        if (i == _maxCellPositions) {
          if (!moreEventsIds.contains(id)) moreEventsIds.add(id);
        }

        // If all cells already filled put last ids to extra one;
        if (i == _maxCellPositions) {
          registeredWeekIndexes[i] = firstList..addAll(secondList);
          eventPositionInCell[id] = i;
          moreItemsExist = true;
          if (!moreEventsIds.contains(id)) moreEventsIds.add(id);
          break;
        }

        var firstListSet = firstList.toSet();
        var secondListSet = secondList.toSet();

        if (firstListSet.intersection(secondListSet).isEmpty) {
          registeredWeekIndexes[i] = firstList..addAll(secondList);
          eventPositionInCell[id] = i;
          break;
        }
      }
    }

    final moreChildrenOfWeek = <Widget>[];

    for (final e in weekEvents) {
      var eventMap = eventAsMap[e.id]!;
      var cellCount = (eventMap.last + 1) - eventMap.first;
      var position = eventPositionInCell[e.id]!;
      var isMore = position == _maxCellPositions;

      List<Widget> rowChildren = [];

      for (var index = 0; index < _weekLength; index++) {
        var width = RectGetter.getRectFromKey(cellKeys[index])!.width;
        final padding = EdgeInsets.only(
            top: (itemHeight * position +
                (widget.eventVerticalPadding * position) +
                widget.eventIndent));

        if (!eventMap.contains(index) || (moreItemsExist && isMore)) {
          rowChildren.add(Container(
            margin: padding,
            width: width,
            height: itemHeight,
          ));
        } else {
          final day = widget.visibleDays[week + index];
          final type = _getType(e, day, firstWeekDay, lastWeekDay);

          late final BorderRadius borderRadius;
          if (type == EventType.start) {
            borderRadius =
                BorderRadius.horizontal(left: Radius.circular(itemHeight));
          } else if (type == EventType.end) {
            borderRadius =
                BorderRadius.horizontal(right: Radius.circular(itemHeight));
          } else if (type == EventType.only) {
            borderRadius = BorderRadius.all(Radius.circular(itemHeight));
          } else {
            borderRadius = BorderRadius.zero;
          }

          if (widget.weekEventBuilder != null) {
            rowChildren.add(
                widget.weekEventBuilder!(e, type, width * cellCount, position));
          } else {
            rowChildren.add(Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  color: e.color,
                ),
                margin: padding,
                width: (width * cellCount) - 10,
                height: itemHeight,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: borderRadius,
                    onTap: () {
                      if (widget.onEventTap != null) widget.onEventTap!(e);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          e.title,
                          maxLines: 1,
                          style: e.titleStyle
                                  ?.copyWith(fontSize: itemHeight / 1.2) ??
                              TextStyle(fontSize: itemHeight / 1.2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ));
          }

          break;
        }
      }
      resultList.add(Row(children: rowChildren));
    }

    if (moreItemsExist) {
      for (var index = 0; index < _weekLength; index++) {
        var width = RectGetter.getRectFromKey(cellKeys[index])!.width;
        var moreIdsPerDay = [];
        final position = _maxCellPositions;
        final padding = EdgeInsets.only(
            top: (itemHeight * position +
                (widget.eventVerticalPadding * position) +
                widget.eventIndent));

        for (final e in moreEventsIds) {
          final allIndexes = eventAsMap[e]!;
          if (allIndexes.contains(index)) {
            moreIdsPerDay.add(e);
          }
        }

        if (moreIdsPerDay.isEmpty) {
          moreChildrenOfWeek.add(Container(
            margin: padding,
            width: width,
            height: itemHeight,
          ));
        } else {
          moreChildrenOfWeek.add(
            Container(
              margin: padding,
              width: width,
              height: itemHeight,
              child: InkWell(
                onTap: () {
                  if (widget.onMoreTap != null)
                    widget.onMoreTap!(weekEvents
                        .where((e) => moreIdsPerDay.contains(e.id))
                        .toList());
                },
                child: Center(
                  child: Container(
                    decoration: ShapeDecoration(
                        shape: CircleBorder(), color: Colors.black),
                    width: 7,
                    height: 7,
                  ),
                ),
              ),
            ),
          );
        }
      }
      resultList.add(Row(children: moreChildrenOfWeek));
    }
    return resultList;
  }

  Widget _buildDay(DateTime day) => widget.dayBuilder(context, day);

  bool _dayHasEvent(DateTime day, EventModel event) {
    final isStartDay = isSameDay(event.startDate, day);
    final isEndDay = isSameDay(event.endDateCalc, day);
    final isInDateRange =
        day.isAfter(event.startDate) && day.isBefore(event.endDateCalc);
    return isStartDay || isEndDay || isInDateRange;
  }

  EventType _getType(
    EventModel e,
    DateTime day,
    DateTime startDate,
    DateTime endDate,
  ) {
    final isOnlyDay = isSameDay(e.startDate, e.endDateCalc);
    final isStartDay = isSameDay(e.startDate, day);
    final isEndDay = isSameDay(e.endDateCalc, day) ||
        (e.endDateCalc.isBefore(endDate) || isSameDay(e.endDateCalc, endDate));

    final isWeekContainsBothDay =
        _isWeekContainsBothDay(e, day, startDate, endDate);

    late final EventType type;
    if (isOnlyDay) {
      type = EventType.only;
    } else if (isWeekContainsBothDay) {
      type = EventType.only;
    } else if (isStartDay) {
      type = EventType.start;
    } else if (isEndDay) {
      type = EventType.end;
    } else {
      type = EventType.full;
    }
    return type;
  }

  bool _isWeekContainsBothDay(
    EventModel e,
    DateTime day,
    DateTime startDate,
    DateTime endDate,
  ) {
    final isStartDay = isSameDay(e.startDate, day);
    return isStartDay &&
        (e.endDateCalc.isBefore(endDate) || isSameDay(e.endDateCalc, endDate));
  }
}
