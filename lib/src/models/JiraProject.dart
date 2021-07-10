class JiraProject {
  JiraProject(this.id, this.name, this.hostId);

  final String id;
  final String name;
  final String? hostId;

  JiraProject.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        hostId = json['hostId'];

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {'id': this.id, 'name': this.name};
    if (this.hostId != null) {
      json['hostId'] = this.hostId!;
    }
    return json;
  }
}
