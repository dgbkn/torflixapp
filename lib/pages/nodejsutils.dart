import 'dart:convert';
import 'dart:io';

import 'package:process_run/process_run.dart';

bool checkExecutable(exec) {
  try {
    var shell = Shell();
    var preerflixExectutable = whichSync(exec);
    print([preerflixExectutable]);
    if (preerflixExectutable == null) {
      return false;
    }
    return true;
  } catch (ex) {
    print(ex);
    return false;
  }
}
