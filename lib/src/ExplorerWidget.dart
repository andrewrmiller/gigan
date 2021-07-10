import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:gigan/src/widgets/WaitSpinner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oauth2/oauth2.dart' as oauth2;
import 'clients/JiraClient.dart';
import 'models/JiraFilter.dart';
import 'models/JiraHost.dart';
import 'models/JiraProject.dart';
import 'widgets/ProjectNavigator.dart';
import 'widgets/IssueList.dart';

// https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-filters/

class ExplorerWidget extends StatefulWidget {
  ExplorerWidget(this.context, this.client, this.preferences) : jiraClient = JiraClient(client);

  final BuildContext context;
  final oauth2.Client client;
  final SharedPreferences preferences;
  final JiraClient jiraClient;

  @override
  _ExplorerState createState() => _ExplorerState();
}

class _ExplorerState extends State<ExplorerWidget> {
  List<JiraHost>? jiraHosts;
  List<JiraProject>? jiraProjects;
  String? hostUrl;
  JiraFilter? filter;

  @override
  void initState() {
    super.initState();

    // Load the list of configured hosts if they exist otherwise fetch
    // the list of configured hosts from Jira.
    if (widget.preferences.containsKey('hosts')) {
      final json = widget.preferences.getString('hosts')!;
      Iterable list = jsonDecode(json);
      jiraHosts = List<JiraHost>.from(list.map((model) => JiraHost.fromJson(model)));
    } else {
      developer.log('No hosts preference found.  Loading hosts from Jira.');
      widget.jiraClient.getHosts().then((hosts) {
        widget.preferences.setString('hosts', jsonEncode(hosts));
        this.setState(() {
          jiraHosts = hosts;
        });
      });
    }

    if (widget.preferences.containsKey('projects')) {
      final json = widget.preferences.getString('projects')!;
      Iterable list = jsonDecode(json);
      jiraProjects = List<JiraProject>.from(list.map((model) => JiraProject.fromJson(model)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (this.jiraHosts == null) {
      return WaitSpinner();
    }

    if (!widget.preferences.containsKey('projects')) {
      developer.log('No projects preference found.  Loading projects from Jira.');
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        this._showSelectProjectDialog();
      });
    }

    if (this.jiraProjects == null) {
      return WaitSpinner();
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('Gigan - Jira Explorer'),
        ),
        body: Container(
            child: Row(
          children: [
            Center(
              child: ProjectNavigator(
                  widget.jiraClient, this.jiraHosts!, this.jiraProjects!, this._onFilterSelected),
            ),
            IssueList(widget.jiraClient, this.hostUrl, this.filter)
          ],
        )));
  }

  void _onFilterSelected(String hostUrl, JiraFilter filter) {
    this.setState(() {
      this.hostUrl = hostUrl;
      this.filter = filter;
    });
  }

  void _showSelectProjectDialog() {
    final hostsJson = jsonDecode(widget.preferences.getString('hosts')!);
    final hosts = List<JiraHost>.from(hostsJson.map((host) => JiraHost.fromJson(host)));
    widget.jiraClient.getProjects(hosts[0].url).then((projects) async {
      // Show a dialog that lets the user choose a project.
      final project = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
                title: const Text('Select Jira Project'),
                children: projects
                    .map((project) => SimpleDialogOption(
                        child: Text(project.name),
                        onPressed: () {
                          Navigator.pop(
                              context, JiraProject(project.id, project.name, hosts[0].id));
                        }))
                    .toList());
          });

      widget.preferences.setString("projects", jsonEncode([project]));
    });
  }
}
