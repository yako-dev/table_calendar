import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class EventLinesExampleScreen extends StatefulWidget {
  const EventLinesExampleScreen({Key? key}) : super(key: key);

  @override
  _EventLinesExampleScreenState createState() =>
      _EventLinesExampleScreenState();
}

class _EventLinesExampleScreenState extends State<EventLinesExampleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late PageController calendarController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text('Calendar'),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          buildHeader(),
          SafeArea(
            child: TableCalendar(
              onCalendarCreated: (controller) {
                calendarController = controller;
              },
              headerVisible: false,
              rowHeight: MediaQuery.of(context).size.width / 7 * 1.5,
              firstDay: DateTime(2021),
              lastDay: DateTime(2023),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.month,
              startingDayOfWeek: StartingDayOfWeek.monday,
              daysOfWeekHeight: 20,
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                }
              },
              availableGestures: AvailableGestures.horizontalSwipe,
              events: _defaultEvents,
              maxEventsCount: 3,
              eventVerticalPadding: 3,
              eventIndent: 30,
              eventMaxHeight: 20,
              daysOfWeekStyle: DaysOfWeekStyle(
                decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(width: 0.5, color: Colors.grey)),
                weekdayStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
                weekendStyle: TextStyle(color: Colors.red, fontSize: 14),
              ),
              calendarStyle: CalendarStyle(
                cellAlignment: Alignment(-1, -1),
                weekendTextStyle: TextStyle(color: Colors.red, fontSize: 16),
                defaultDecoration: BoxDecoration(
                    border: Border(
                  top: BorderSide(width: 0.5, color: Colors.grey),
                  left: BorderSide(width: 0.5, color: Colors.grey),
                )),
                weekendDecoration: BoxDecoration(
                    border: Border(
                  top: BorderSide(width: 0.5, color: Colors.grey),
                  left: BorderSide(width: 0.5, color: Colors.grey),
                )),
                outsideDecoration: BoxDecoration(
                    border: Border(
                  top: BorderSide(width: 0.5, color: Colors.grey),
                  left: BorderSide(width: 0.5, color: Colors.grey),
                )),
                todayDecoration: BoxDecoration(
                    border: Border(
                  top: BorderSide(width: 0.5, color: Colors.grey),
                  left: BorderSide(width: 0.5, color: Colors.grey),
                )),
                rowDecoration: BoxDecoration(shape: BoxShape.rectangle),
                selectedDecoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.7),
                    border: Border(
                      top: BorderSide(width: 0.5, color: Colors.grey),
                      left: BorderSide(width: 0.5, color: Colors.grey),
                    )),
                todayTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepPurple[700]),
                cellPadding: EdgeInsets.all(5),
                cellMargin: EdgeInsets.all(0),
                selectedTextStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                holidayTextStyle: TextStyle(fontSize: 18, color: Colors.red),
                outsideDaysVisible: true,
              ),
            ),
          ),
          Divider(
            thickness: 0.5,
            color: Colors.grey,
            height: 0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: Wrap(
              children: _defaultEvents
                  .map((e) => explanationItem(e, context))
                  .toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            calendarController.previousPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.linear,
            );
          },
          icon: Icon(Icons.arrow_back_ios, size: 18),
        ),
        Text(
          DateFormat('d MMM, yyyy').format(DateTime.now()),
          style: TextStyle(fontSize: 18),
        ),
        IconButton(
          onPressed: () {
            calendarController.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.linear,
            );
          },
          icon: Icon(Icons.arrow_forward_ios, size: 18),
        )
      ],
    );
  }

  Widget explanationItem(EventModel e, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12, bottom: 6),
      child: SizedBox(
        width: 150,
        child: Row(children: <Widget>[
          CircleAvatar(
            radius: 6,
            backgroundColor: e.color,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                e.title,
                style: Theme.of(context).textTheme.caption,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

final _defaultEvents = [
  EventModel(
    id: '1',
    title: 'FESTIVAL OF MODERN CHOREOGRAPHY',
    color: Colors.deepPurple.shade300,
    titleStyle: TextStyle(
        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
    startDate: DateTime.now().add(Duration(days: 1)),
    endDate: DateTime.now().add(Duration(days: 11)),
  ),
  EventModel(
    id: '3',
    title: 'ROCK BULAVA 2022',
    color: Colors.green.shade400,
    titleStyle: TextStyle(
        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
    startDate: DateTime.now().add(Duration(days: 10)),
    endDate: DateTime.now().add(Duration(days: 13)),
  ),
  EventModel(
    id: '4',
    title: 'UPARK 2022',
    color: Colors.red.shade300,
    titleStyle: TextStyle(
        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
    startDate: DateTime.now().subtract(Duration(days: 2)),
    endDate: DateTime.now().subtract(Duration(days: 1)),
  ),
  EventModel(
    id: '5',
    title: 'November Music',
    color: Colors.blue.shade300,
    titleStyle: TextStyle(
        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
    startDate: DateTime.now().add(Duration(days: 21)),
    endDate: DateTime.now().add(Duration(days: 28)),
  ),
  EventModel(
    id: '6',
    title: 'New Music',
    color: Colors.deepOrange.shade300,
    titleStyle: TextStyle(
        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
    startDate: DateTime.now().add(Duration(days: 5)),
    endDate: DateTime.now().add(Duration(days: 12)),
  ),
];
