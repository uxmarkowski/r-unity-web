import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_web/blocs/payment/payment_bloc.dart';
import 'package:event_web/global_variables.dart';
import 'package:event_web/sign_in.dart';
import 'package:event_web/sign_up.dart';
import 'package:event_web/test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'dev_test.dart';

void main() async{
  await WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: FirebaseOptions(apiKey: "AIzaSyDy3IO1jCRsQit0HUDxRRnVlEleAMwOjQk", appId: "1:192940888759:web:bea61940a770dcea097332", messagingSenderId: "192940888759", projectId: "r-unity"));
  FirebaseFirestore.instance.settings = Settings(persistenceEnabled: false);

  runApp( MyApp() );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData( primarySwatch: Colors.blue, ),
      // home: MyEventList(),
      initialRoute: "/",
      routes: {
        '/': (context) => MyEventList(doc_id: "",),
        '/second': (context) => ClassicPage(test_param: "test_param"),
      },
      onGenerateRoute: (settings) {
        List<String> pathComponents = settings.name!.split('/');
        return MaterialPageRoute(
          builder: (context) {
            return MyEventList(doc_id: pathComponents[1].toString());
          },
        );
        ;
      },
    );
  }
}

Color PrimaryCol=Color.fromRGBO(93, 42, 233, 1);