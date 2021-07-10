import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'jira_oauth_credentials.dart';
import 'src/JiraLoginWidget.dart';
import 'src/ExplorerWidget.dart';
import 'src/widgets/WaitSpinner.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.grey,
      ),
      home: MyHomePage(title: 'Gigan Jira Client'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<SharedPreferences> _preferences = SharedPreferences.getInstance();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
        future: this._preferences,
        builder: (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
          if (snapshot.hasData) {
            return JiraLoginWidget(
                builder: (context, httpClient) {
                  return ExplorerWidget(context, httpClient, snapshot.data!);
                },
                jiraClientId: jiraClientId,
                jiraClientSecret: jiraClientSecret,
                jiraScopes: jiraScopes,
                preferences: snapshot.data!);
          } else if (snapshot.hasError) {
            return Center(
                child: Column(children: <Widget>[
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              )
            ]));
          } else {
            return WaitSpinner();
          }
        });
  }
}
