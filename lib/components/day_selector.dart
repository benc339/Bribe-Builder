import 'package:flutter/material.dart';

Row daySelector(String weekday, Map frequency) {
  Map dayMap = {
    '1': 'M',
    '2': 'T',
    '3': 'W',
    '4': 'T',
    '5': 'F',
    '6': 'S',
    '7': 'S'
  };
  return Row(
    children: [
      frequency[weekday]
          ? Flexible(
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(width: 2, color: Colors.white),
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(209, 224, 224, 0.2)),
                child: Padding(
                    padding: const EdgeInsets.all(6.5),
                    child: Text(dayMap[weekday],
                        style: TextStyle(fontSize: 10.0, color: Colors.white))),
              ),
            )
          : Flexible(
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        width: 2, color: Color.fromRGBO(209, 224, 224, 0.2)),
                    shape: BoxShape.circle,
                    color: Color.fromRGBO(209, 224, 224, 0.2)),
                child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(dayMap[weekday],
                        style: TextStyle(fontSize: 5.5, color: Colors.white))),
              ),
            )
    ],
  );
}
