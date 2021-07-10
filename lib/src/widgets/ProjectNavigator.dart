import 'package:flutter/material.dart';
import '../clients/JiraClient.dart';
import '../models/JiraFilter.dart';
import '../models/JiraHost.dart';
import '../models/JiraProject.dart';
import './WaitSpinner.dart';

typedef void FilterSelectedHandler(String hostUrl, JiraFilter filter);

class ProjectNavigator extends StatefulWidget {
  ProjectNavigator(this.jiraClient, this.hosts, this.projects, this.onFilterSelected);
  final JiraClient jiraClient;
  final List<JiraHost> hosts;
  final List<JiraProject> projects;
  final FilterSelectedHandler onFilterSelected;

  @override
  _ProjectNavigatorState createState() => _ProjectNavigatorState();
}

class _ProjectNavigatorState extends State<ProjectNavigator> {
  List<JiraFilter>? filters;

  @override
  void initState() {
    super.initState();
    widget.jiraClient.getFilters(widget.hosts[0].url, widget.projects[0].id).then((filters) {
      this.setState(() {
        this.filters = filters;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (this.filters == null) {
      return WaitSpinner();
    }
    return Container(
        width: 250,
        decoration: BoxDecoration(color: Colors.black45),
        child: ListView(
            scrollDirection: Axis.vertical,
            children: widget.projects
                .map((project) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(project.name, style: TextStyle(fontWeight: FontWeight.bold)),
                      ListView(
                          padding: const EdgeInsets.all(8),
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          children: this
                              .filters!
                              .map((filter) => InkWell(
                                  onTap: () {
                                    print("Container was tapped");
                                    widget.onFilterSelected(widget.hosts[0].url, filter);
                                  },
                                  hoverColor: Colors.blueGrey,
                                  onHover: (event) {
                                    print("Hover");
                                  },
                                  child: Container(
                                      height: 25,
                                      child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(filter.name)))))
                              .toList())
                    ]))
                .toList()));
  }
}
