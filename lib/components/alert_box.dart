import 'package:flutter/material.dart';

Future showAlert(BuildContext context) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Rules', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            //'Most of us would like to improve ourselves but the hard part is getting our future self to repeatedly do what we would like it to.  We can bribe our future self with this app.  Studies have shown this method to be highly effective.',
            "It'll be up to you to prove you've completed the activity each day with a video.  If your proof is deemed insufficient, you'll be able to try again or change your activity without penalty until it is.  Once your first video passes your challenge will officially begin and you must start over if you aren't able to submit sufficient proof by each set time. \n\nYou may try your challenge from the beginning an unlimited number of times without depositing more money",
            style: TextStyle(
                fontSize: 20,
                //fontWeight: FontWeight.bold,
                color: Colors.black),
            //textAlign: TextAlign.center,
          ),
        ),
      );
    },
  );
}
