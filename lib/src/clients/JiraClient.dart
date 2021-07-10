import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import '../models/JiraFilter.dart';
import '../models/JiraHost.dart';
import '../models/JiraProject.dart';

class JiraClient {
  JiraClient(this.oauthClient);

  final oauth2.Client oauthClient;

  Future<List<JiraHost>> getHosts() async {
    http.Request request = http.Request(
        'GET', Uri.parse('https://api.atlassian.com/oauth/token/accessible-resources'));

    final streamedResponse = await this.oauthClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw ("Failed to retrieve accessible resources.");
    }

    developer.log('Successfully retrieved accessible resources');
    final json = response.body;
    return List<JiraHost>.from(jsonDecode(json).map((model) => JiraHost.fromJson(model)));
  }

  Future<List<JiraProject>> getProjects(String hostUrl) async {
    http.Request request = http.Request('GET', Uri.parse('$hostUrl/rest/api/3/project'));

    final streamedResponse = await this.oauthClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw ("Failed to retrieve list of projects.");
    }

    developer.log('Successfully retrieved list of projects');
    final json = response.body;
    return List<JiraProject>.from(jsonDecode(json).map((model) => JiraProject.fromJson(model)));
  }

  Future<List<JiraFilter>> getFilters(String hostUrl, String projectId) async {
    Uri uri =
        Uri.parse('$hostUrl/rest/api/3/filter/search?projectId=$projectId&expand=viewUrl,jql');
    http.Request request = http.Request('GET', uri);

    final streamedResponse = await this.oauthClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw ("Failed to retrieve list of filters.");
    }

    developer.log('Successfully retrieved list of filters');
    final json = response.body;
    return List<JiraFilter>.from(
        jsonDecode(json)["values"].map((model) => JiraFilter.fromJson(model)));
  }

  // https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-filters/#api-rest-api-3-filter-id-columns-get
  Future<List<String>> getFilterColumns(String hostUrl, String filterId) async {
    Uri uri = Uri.parse('$hostUrl/rest/api/3/filter/$filterId/columns');
    http.Request request = http.Request('GET', uri);

    final streamedResponse = await this.oauthClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw ("Failed to retrieve filter columns.");
    }

    developer.log('Successfully retrieved filter columns');
    final json = response.body;
    return List<String>.from(jsonDecode(json)["values"].map((model) => JiraFilter.fromJson(model)));
  }

  // https://developer.atlassian.com/cloud/jira/platform/rest/v3/api-group-issue-search/#api-rest-api-3-search-post
  Future<List<dynamic>> searchIssues(String hostUrl, String jql) async {
    Uri uri = Uri.parse('$hostUrl/rest/api/3/search');
    http.Request request = http.Request('POST', uri);
    request.body = jsonEncode(<String, dynamic>{
      'jql': jql,
      'startAt': 0,
      'maxResults': 50,
      'fields': ['key', 'summary']
    });
    request.headers['Content-Type'] = 'application/json; charset=UTF-8';

    final streamedResponse = await this.oauthClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      print(response.body);
      throw ("Failed to retrieve issue search results.");
    }

    developer.log('Successfully retrieved issue search results');
    final json = response.body;
    return List<dynamic>.from(jsonDecode(json)["issues"]);
  }
}
