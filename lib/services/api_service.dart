import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_response.dart';
import '../models/system_info.dart';
import '../models/file_info.dart';
import '../models/media_item.dart';
import '../models/config_model.dart';

class ApiService {
  static const String _tokenKey = 'auth_token';
  static const String _hostKey = 'host_address';
  static const String _usernameKey = 'saved_username';
  static const String _passwordKey = 'saved_password';
  static String _baseUrl = 'http://192.168.1.100:8080';
  String? _token;

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String get baseUrl => _baseUrl;
  String? get token => _token;

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    _baseUrl = prefs.getString(_hostKey) ?? 'http://192.168.1.100:8080';
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> saveHost(String host) async {
    _baseUrl = host;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hostKey, host);
  }

  Future<Map<String, String>> loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_usernameKey) ?? '',
      'password': prefs.getString(_passwordKey) ?? '',
      'host': prefs.getString(_hostKey) ?? 'http://192.168.1.100:8080',
    };
  }

  Future<void> saveCredentials(
      String username, String password, String host) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_passwordKey, password);
    await prefs.setString(_hostKey, host);
    _baseUrl = host;
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // -- Auth --
  Future<ApiResponse<Map<String, dynamic>>> checkLogin() async {
    final r = await http.get(Uri.parse('$_baseUrl/api/login'));
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<String>> login(String username, String password) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (d) => (d as Map<String, dynamic>)['token'] as String,
    );
  }

  Future<ApiResponse<void>> logout() async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/logout'),
      headers: _headers,
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (_) {},
    );
  }

  Future<ApiResponse<void>> changePassword(
      String oldPwd, String newPwd) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/change-password'),
      headers: _headers,
      body: jsonEncode({'oldPassword': oldPwd, 'newPassword': newPwd}),
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (_) {},
    );
  }

  // -- Status --
  Future<ApiResponse<SystemStatus>> getStatus() async {
    final r = await http.get(
      Uri.parse('$_baseUrl/api/status'),
      headers: _headers,
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (d) => SystemStatus.fromJson(d as Map<String, dynamic>),
    );
  }

  // -- System --
  Future<ApiResponse<SystemInfo>> getSystemInfo() async {
    final r = await http.get(
      Uri.parse('$_baseUrl/api/system'),
      headers: _headers,
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (d) => SystemInfo.fromJson(d as Map<String, dynamic>),
    );
  }

  // -- Config --
  Future<ApiResponse<AppConfig>> getConfig() async {
    final r = await http.get(
      Uri.parse('$_baseUrl/api/config'),
      headers: _headers,
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (d) => AppConfig.fromJson(d as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> saveConfig(Map<String, dynamic> config) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/config/save'),
      headers: _headers,
      body: jsonEncode(config),
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (_) {},
    );
  }

  Future<ApiResponse<void>> testWebhook({
    required String url,
    required String requestBody,
    required String headers,
  }) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/webhook/test'),
      headers: _headers,
      body: jsonEncode({
        'url': url,
        'requestBody': requestBody,
        'headers': headers,
      }),
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (_) {},
    );
  }

  // -- Logs --
  Future<ApiResponse<List<String>>> getLogs() async {
    final r = await http.get(
      Uri.parse('$_baseUrl/api/logs'),
      headers: _headers,
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (d) => (d as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Future<ApiResponse<void>> clearLogs() async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/logs/clear'),
      headers: _headers,
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (_) {},
    );
  }

  // -- Files --
  Future<ApiResponse<List<FileInfo>>> listFiles(String path) async {
    final r = await http.get(
      Uri.parse('$_baseUrl/api/files?path=${Uri.encodeComponent(path)}'),
      headers: _headers,
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (d) => (d as List<dynamic>)
          .map((e) => FileInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<void>> uploadFile(String dirPath, File file) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/api/files/upload?path=${Uri.encodeComponent(dirPath)}'),
    );
    req.headers.addAll(_headers);
    req.files.add(await http.MultipartFile.fromPath('file', file.path));
    final streamed = await req.send();
    final r = await http.Response.fromStream(streamed);
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (_) {},
    );
  }

  String getDownloadUrl(String path, {String? disposition}) {
    final params = {'path': path, 'token': _token ?? ''};
    if (disposition != null) params['disposition'] = disposition;
    final uri = Uri.parse('$_baseUrl/api/files/download')
        .replace(queryParameters: params);
    return uri.toString();
  }

  String getThumbUrl(String path) {
    return '$_baseUrl/api/files/thumb?path=${Uri.encodeComponent(path)}&token=$_token';
  }

  Future<ApiResponse<void>> createDir(String path) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/files/mkdir'),
      headers: _headers,
      body: jsonEncode({'path': path}),
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (_) {},
    );
  }

  Future<ApiResponse<void>> renameFile(String oldPath, String newName) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/files/rename'),
      headers: _headers,
      body: jsonEncode({'oldPath': oldPath, 'newName': newName}),
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (_) {},
    );
  }

  Future<ApiResponse<void>> deleteFile(String path) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/files/delete'),
      headers: _headers,
      body: jsonEncode({'path': path}),
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (_) {},
    );
  }

  Future<ApiResponse<void>> batchDelete(List<String> paths) async {
    final r = await http.post(
      Uri.parse('$_baseUrl/api/files/batch-delete'),
      headers: _headers,
      body: jsonEncode({'paths': paths}),
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (_) {},
    );
  }

  // -- Gallery --
  Future<ApiResponse<List<MediaItem>>> getGallery() async {
    final r = await http.get(
      Uri.parse('$_baseUrl/api/gallery'),
      headers: _headers,
    );
    return ApiResponse.fromJson(
      jsonDecode(r.body) as Map<String, dynamic>,
      (d) => (d as List<dynamic>)
          .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}