import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';


class GlobalProvider extends ChangeNotifier {
  int notifications_lenght = 0;
  int uncheck_messages_lenght = 0;
  bool app_init = false;

  int get notifications_lenght_get => notifications_lenght;
  int get uncheck_messages_lenght_get => uncheck_messages_lenght;
  bool get app_init_get => app_init;

  void updateNotifcations(int newData) {
    notifications_lenght = newData;
    notifyListeners();
  }

  void updateUncheckMessages(int newData) {
    uncheck_messages_lenght = newData;
    notifyListeners();
  }

  void AppEnsureInit(bool InitBool) {
    app_init = InitBool;
    notifyListeners();
  }


}



