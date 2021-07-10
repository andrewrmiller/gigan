class JiraFilter {
  JiraFilter(this.id, this.name, this.viewUrl, this.jql);

  final String id;
  final String name;
  final String viewUrl;
  final String jql;

  JiraFilter.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        viewUrl = json['viewUrl'],
        jql = json['jql'];

  Map<String, dynamic> toJson() =>
      {'id': this.id, 'name': this.name, 'viewUrl': this.viewUrl, 'jql': this.jql};
}
