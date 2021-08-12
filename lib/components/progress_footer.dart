import 'package:flutter/material.dart';

List<Widget> progressCircles(List progressList, frequency, weekday) {
  List<Widget> circleList = [];
  Color color;
  int cnt = 0;
  int weekdayInt = int.parse(weekday);

  print('weekdayint:$weekdayInt');
  print(progressList.length);
  print(progressList.length % 7);
  print(weekdayInt - progressList.length % 7);
  weekdayInt = weekdayInt - progressList.length % 7 + 1;
  print('weekdayintafter:$weekdayInt');
  if (weekdayInt == 8) {
     weekdayInt = 1;
  }
  if (weekdayInt <= 0) {
    weekdayInt = 7 + weekdayInt;
  }

  for (var element in progressList) {
    cnt++;
    print('cnt' + cnt.toString());
    print(weekdayInt);
    print(!frequency[weekdayInt.toString()]);
    if (!frequency[weekdayInt.toString()]) {
      weekdayInt++;
      if (weekdayInt == 8) {
        weekdayInt = 1;
      }
      print('continue');
      continue;
    }
    weekdayInt++;
    if (weekdayInt == 8) {
      weekdayInt = 1;
    }

    if (element == 0) {
      color = Colors.black12;
    } else if (element == 1) {
      color = Colors.lightBlue;
    } else {
      color = Colors.green;
    }
    if (circleList.length > 8) {
      circleList.removeAt(0);
    }
    print('add circle');
    circleList.add(Flexible(
      child: Padding(
        padding: const EdgeInsets.only(right: 2.0),
        child: Container(
          width: 30.0,
          height: 30.0,
          decoration: new BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(cnt.toString(),
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    ));
  }
  return circleList;
}
