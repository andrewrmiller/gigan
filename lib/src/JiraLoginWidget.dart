import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:oauth2/oauth2.dart' as oauth2;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

final _authorizationEndpoint =
    Uri.parse('https://auth.atlassian.com/authorize?audience=api.atlassian.com');
final _tokenEndpoint = Uri.parse('https://auth.atlassian.com/oauth/token');

class JiraLoginWidget extends StatefulWidget {
  const JiraLoginWidget(
      {required this.builder,
      required this.jiraClientId,
      required this.jiraClientSecret,
      required this.jiraScopes,
      required this.preferences});
  final AuthenticatedBuilder builder;
  final String jiraClientId;
  final String jiraClientSecret;
  final List<String> jiraScopes;
  final SharedPreferences preferences;

  @override
  _JiraLoginState createState() => _JiraLoginState();
}

typedef AuthenticatedBuilder = Widget Function(BuildContext context, oauth2.Client client);

class _JiraLoginState extends State<JiraLoginWidget> {
  HttpServer? _redirectServer;
  oauth2.Client? _client;

  @override
  void initState() {
    super.initState();

    // If there are persisted OAuth credentials, load them and initialize
    // the OAuth2 client instance.
    if (widget.preferences.containsKey('credentials')) {
      final json = widget.preferences.getString('credentials');
      final credentials = oauth2.Credentials.fromJson(json!);
      final client = oauth2.Client(credentials,
          identifier: widget.jiraClientId,
          secret: widget.jiraClientSecret,
          onCredentialsRefreshed: this._handleCredentialsRefreshed);
      _client = client;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (this._client != null) {
      return widget.builder(context, this._client!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jira Login'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await _redirectServer?.close();
            // Bind to an ephemeral port on localhost
            _redirectServer = await HttpServer.bind('localhost', 3333);
            var authenticatedHttpClient =
                await _getOAuth2Client(Uri.parse('http://localhost:${_redirectServer!.port}/auth'));
            setState(() {
              _client = authenticatedHttpClient;
            });
          },
          child: const Text('Login to Jira'),
        ),
      ),
    );
  }

  Future<oauth2.Client> _getOAuth2Client(Uri redirectUrl) async {
    if (widget.jiraClientId.isEmpty || widget.jiraClientSecret.isEmpty) {
      throw const JiraLoginException('JiraClientId and JiraClientSecret must be not empty. '
          'See `lib/Jira_oauth_credentials.dart` for more detail.');
    }

    final grant = oauth2.AuthorizationCodeGrant(
        widget.jiraClientId, _authorizationEndpoint, _tokenEndpoint,
        secret: widget.jiraClientSecret,
        httpClient: _JsonAcceptingHttpClient(),
        onCredentialsRefreshed: this._handleCredentialsRefreshed);
    Uri authorizationUrl = grant.getAuthorizationUrl(redirectUrl, scopes: widget.jiraScopes);
    developer.log(
        'Initiating OAuth 2.0 authorization flow with url \'${authorizationUrl.toString()}\'.');

    await _redirect(authorizationUrl);
    final responseQueryParameters = await _listen();
    final client = await grant.handleAuthorizationResponse(responseQueryParameters);

    developer.log('Login successful.  Saving credentials.');
    widget.preferences.setString('credentials', client.credentials.toJson());

    return client;
  }

  Future<void> _redirect(Uri authorizationUrl) async {
    var url = authorizationUrl.toString();
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw JiraLoginException('Could not launch $url');
    }
  }

  Future<Map<String, String>> _listen() async {
    var request = await _redirectServer!.first;
    var params = request.uri.queryParameters;
    request.response.statusCode = 200;
    request.response.headers.set('content-type', 'text/plain');
    request.response.writeln('Authenticated! You can close this tab.');
    await request.response.close();
    await _redirectServer!.close();
    _redirectServer = null;
    return params;
  }

  void _handleCredentialsRefreshed(oauth2.Credentials credentials) {
    developer.log('Credentials refreshed.  Saving...');
    widget.preferences.setString('credentials', credentials.toJson());
  }
}

class _JsonAcceptingHttpClient extends http.BaseClient {
  final _httpClient = http.Client();
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Accept'] = 'application/json';
    return _httpClient.send(request);
  }
}

class JiraLoginException implements Exception {
  const JiraLoginException(this.message);
  final String message;
  @override
  String toString() => message;
}
