class JiraHost {
  JiraHost(this.id, this.name, this.url, this.avatarUrl);

  final String id;
  final String name;
  final String url;
  final String avatarUrl;

  JiraHost.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        url = json['url'],
        avatarUrl = json['avatarUrl'];

  Map<String, dynamic> toJson() =>
      {'id': this.id, 'name': this.name, 'url': this.url, 'avatarUrl': this.avatarUrl};
}
