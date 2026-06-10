import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController(text: 'root');
  final _passwordController = TextEditingController(text: 'root');
  final _hostController = TextEditingController();
  final _api = ApiService();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;
  bool _showHostConfig = false;

  @override
  void initState() {
    super.initState();
    _hostController.text = _api.baseUrl;
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    await _api.loadSaved();
    if (_api.token != null) {
      final res = await _api.checkLogin();
      if (res.isSuccess && mounted) {
        _navigateToHome();
      }
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    await _api.saveHost(_hostController.text.trim());

    final res = await _api.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (res.isSuccess && res.data != null) {
      await _api.saveToken(res.data!);
      _navigateToHome();
    } else {
      setState(() {
        _loading = false;
        _error = res.message ?? '登录失败';
      });
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dns, size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  'GNAS',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '网络附加存储',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                if (_showHostConfig) ...[
                  TextField(
                    controller: _hostController,
                    decoration: InputDecoration(
                      labelText: '服务器地址',
                      hintText: 'http://192.168.1.100:8080',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            size: 18, color: theme.colorScheme.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: TextStyle(
                                  color: theme.colorScheme.onErrorContainer)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _loading ? null : _login,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('登 录',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showHostConfig = !_showHostConfig),
                  icon: Icon(
                    _showHostConfig ? Icons.expand_less : Icons.settings,
                    size: 18,
                  ),
                  label: Text(_showHostConfig ? '收起设置' : '服务器设置'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}