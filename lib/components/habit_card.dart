import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'wide_button.dart';
import 'package:habit_creator/pages/habit_tracker.dart';
import 'package:habit_creator/constants.dart';
import 'day_selector.dart';

class Habit {
  Map serverVariables;
  late String habitName;
  late DateTime startTime;
  late Map frequency;
  late List progressList;
  late int dayInt;
  late String weekday;
  late bool uploaded;
  late int length;
  late String won;
  late int dayCount;

  Habit(
    this.serverVariables,
  )   : progressList = serverVariables['progressList'],
        frequency = serverVariables['frequency'],
        habitName = serverVariables['habit'],
        length = serverVariables['length'],
        won = serverVariables['won'];

  init() {
    startTime = DateTime.parse(serverVariables['startTime']);
    DateTime now = DateTime.now().toLocal();
    dayInt = (now.difference(startTime).inDays + 1);

    weekday = now.weekday.toString();
    uploaded = false;
    if (dayInt == progressList.length) {
      uploaded = true;
    }
    if (progressList.length == 0) {
      dayCount = 0;
    } else if (progressList.length < dayInt) {
      dayCount = 0;
    } else {
      dayCount = 1;
      int weekdayCount = int.parse(weekday);
      for (int x = progressList.length - 1; x > 0; x--) {
        if (frequency[weekdayCount.toString()]) {
          if (progressList[x] == 1 || progressList[x] == 2) {
            dayCount++;
          } else {
            break;
          }
        }
        weekdayCount--;
        if (weekdayCount == 0) {
          weekdayCount = 7;
        }
      }
      print('dayCount');
      print(dayCount);
    }
  }
}

Card makeCard(Habit habit, context) => Card(
      elevation: 8.0,
      margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(color: Colors.blueGrey[200]),
        child: makeListTile(habit, context),
      ),
    );

ListTile makeListTile(Habit habit, context) => ListTile(
    onTap: () {
      globalHabitName = habit.habitName;
      Navigator.pushNamed(context, HabitTracker.id);
    },
    contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
    title: Row(
      children: [
        Expanded(
          flex: 1,
          child: Text(
            habit.habitName,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 1,
          child: makeSubtitle(habit),
        )
      ],
    ),
    // subtitle: Text("Intermediate", style: TextStyle(color: Colors.white)),

    subtitle: Row(
      children: <Widget>[
        Expanded(
            flex: 1,
            child: Container(
              // tag: 'hero',
              child: LinearProgressIndicator(
                  backgroundColor: Color.fromRGBO(209, 224, 224, 0.2),
                  value: habit.dayCount / habit.length,
                  valueColor: AlwaysStoppedAnimation(Colors.green)),
            )),
        Expanded(flex: 1, child: Container()),
      ],
    ),
    trailing:
        Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0));

Widget makeSubtitle(Habit habit) =>
    !habit.uploaded & habit.frequency[habit.weekday]
        ? habit.startTime != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Scheduled',
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ],
              )
            : Container()
        : habit.frequency[habit.weekday]
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //Icon(Icons.check_circle, color: Colors.green, size: 16.0),
                  Text('Complete',
                      style: TextStyle(
                          color: Colors.green[800],
                          fontSize: 16,
                          fontWeight: FontWeight.bold))
                ],
              )
            : Container();

Widget makeBody(List habits, context) => Container(
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: habits.length,
        itemBuilder: (BuildContext context, int index) {
          return makeCard(habits[index], context);
        },
      ),
    );
