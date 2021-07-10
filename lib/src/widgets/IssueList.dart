import 'package:flutter/material.dart';
import '../clients/JiraClient.dart';
import '../models/JiraFilter.dart';
import '../widgets/WaitSpinner.dart';

class IssueList extends StatefulWidget {
  IssueList(this.jiraClient, this.hostUrl, this.filter);
  final JiraClient jiraClient;
  final String? hostUrl;
  final JiraFilter? filter;

  @override
  _IssueListState createState() => _IssueListState();
}

class _IssueListState extends State<IssueList> {
  List<dynamic>? issues;

  @override
  void initState() {
    super.initState();

    if (widget.hostUrl != null && widget.filter != null) {
      this._getIssues();
    }
  }

  @override
  void didUpdateWidget(covariant IssueList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hostUrl != null && widget.filter != null) {
      this._getIssues();
    }
  }

  void _getIssues() {
    widget.jiraClient.searchIssues(widget.hostUrl!, widget.filter!.jql).then((issues) {
      this.setState(() {
        this.issues = issues;
      });
    });
  }

  Widget build(BuildContext context) {
    if (widget.filter == null) {
      return Container();
    }

    if (this.issues == null) {
      return WaitSpinner();
    }

    return SingleChildScrollView(
        child: Column(
            // padding: const EdgeInsets.all(8),
            // scrollDirection: Axis.vertical,
            // shrinkWrap: true,
            children: this
                .issues!
                .map((issue) =>
                    Row(children: [Text(issue['key']), Text(issue['fields']['summary'])]))
                .toList()));
  }
}
