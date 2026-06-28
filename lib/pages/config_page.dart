import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/config_model.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage>
    with AutomaticKeepAliveClientMixin {
  final _api = ApiService();
  AppConfig? _config;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  final List<_DnsFormData> _dnsForms = [];
  bool _notAllowWan = true;
  final _webhookUrlCtl = TextEditingController();
  final _webhookBodyCtl = TextEditingController();
  final _webhookHeadersCtl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    for (final form in _dnsForms) {
      form.dispose();
    }
    _webhookUrlCtl.dispose();
    _webhookBodyCtl.dispose();
    _webhookHeadersCtl.dispose();
    super.dispose();
  }

  void _setDnsForms(List<DnsConfig> configs) {
    for (final form in _dnsForms) {
      form.dispose();
    }
    _dnsForms
      ..clear()
      ..addAll(configs.map(_DnsFormData.fromConfig));
  }

  Future<void> _loadConfig() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _api.getConfig();
    if (!mounted) return;
    if (res.isSuccess && res.data != null) {
      _config = res.data!;
      _notAllowWan = _config!.notAllowWanAccess;
      _webhookUrlCtl.text = _config!.webhookUrl;
      _webhookBodyCtl.text = _config!.webhookRequestBody;
      _webhookHeadersCtl.text = _config!.webhookHeaders;
      _setDnsForms(_config!.dnsConf);
      setState(() => _loading = false);
    } else {
      setState(() {
        _error = res.message ?? '加载失败';
        _loading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() {
      _saving = true;
    });

    final config = {
      'notAllowWanAccess': _notAllowWan,
      'webhookUrl': _webhookUrlCtl.text,
      'webhookRequestBody': _webhookBodyCtl.text,
      'webhookHeaders': _webhookHeadersCtl.text,
      'dnsConf': _dnsForms.map((f) => f.toJson()).toList(),
    };

    final res = await _api.saveConfig(config);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = false);
    if (res.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('配置保存成功'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      _loadConfig();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.message ?? '保存失败'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: _loadConfig, child: const Text('重试')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConfig,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // General settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('通用设置', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('禁止公网访问'),
                    subtitle: const Text('开启后仅内网 IP 可访问'),
                    value: _notAllowWan,
                    onChanged: (v) => setState(() => _notAllowWan = v),
                    secondary: const Icon(Icons.public_off),
                  ),
                  TextField(
                    controller: _webhookUrlCtl,
                    decoration: const InputDecoration(
                      labelText: 'Webhook URL',
                      hintText: 'https://hooks.example.com/webhook',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _webhookBodyCtl,
                    decoration: const InputDecoration(
                      labelText: 'Webhook 请求体',
                      hintText: '{"text":"IP 已更新"}',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _webhookHeadersCtl,
                    decoration: const InputDecoration(
                      labelText: 'Webhook 自定义头',
                      hintText: '每行一个 Key: Value',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // DNS Configs
          ..._dnsForms.asMap().entries.map((entry) {
            final i = entry.key;
            final form = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dns, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'DDNS 配置 #${i + 1}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              final removed = _dnsForms.removeAt(i);
                              removed.dispose();
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: '名称',
                        border: OutlineInputBorder(),
                      ),
                      controller: form.nameCtl,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: form.dnsNameCtl.text.isEmpty
                          ? null
                          : form.dnsNameCtl.text,
                      decoration: const InputDecoration(
                        labelText: 'DNS 服务商',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'dnspod',
                          child: Text('DNSPod'),
                        ),
                        DropdownMenuItem(value: 'aliyun', child: Text('阿里云')),
                        DropdownMenuItem(
                          value: 'cloudflare',
                          child: Text('Cloudflare'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => form.dnsNameCtl.text = v ?? '');
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'DNS API ID/Key',
                        border: OutlineInputBorder(),
                      ),
                      controller: form.dnsIdCtl,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'DNS API Secret/Token',
                        border: OutlineInputBorder(),
                      ),
                      controller: form.dnsSecretCtl,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'TTL',
                        border: OutlineInputBorder(),
                      ),
                      controller: form.ttlCtl,
                    ),
                    const SizedBox(height: 12),
                    Text('IPv4', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      title: const Text('启用 IPv4'),
                      value: form.ipv4Enable,
                      onChanged: (v) => setState(() => form.ipv4Enable = v),
                      dense: true,
                    ),
                    if (form.ipv4Enable) ...[
                      DropdownButtonFormField<String>(
                        initialValue: form.ipv4GetTypeCtl.text,
                        decoration: const InputDecoration(
                          labelText: 'IPv4 获取方式',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'url', child: Text('URL')),
                          DropdownMenuItem(
                            value: 'netInterface',
                            child: Text('网卡'),
                          ),
                          DropdownMenuItem(value: 'cmd', child: Text('命令')),
                        ],
                        onChanged: (v) {
                          setState(() => form.ipv4GetTypeCtl.text = v ?? 'url');
                        },
                      ),
                      const SizedBox(height: 8),
                      if (form.ipv4GetTypeCtl.text == 'url')
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'IPv4 URL',
                            border: OutlineInputBorder(),
                          ),
                          controller: form.ipv4UrlCtl,
                        ),
                      if (form.ipv4GetTypeCtl.text == 'netInterface')
                        DropdownButtonFormField<String>(
                          initialValue:
                              _config!.ipv4Interfaces
                                  .map((e) => e.name)
                                  .toList()
                                  .contains(form.ipv4NetInterfaceCtl.text)
                              ? form.ipv4NetInterfaceCtl.text
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'IPv4 网卡',
                            border: OutlineInputBorder(),
                          ),
                          items: _config!.ipv4Interfaces
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.name,
                                  child: Text(e.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(
                              () => form.ipv4NetInterfaceCtl.text = v ?? '',
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'IPv4 域名（每行一个）',
                          border: OutlineInputBorder(),
                        ),
                        controller: form.ipv4DomainsCtl,
                        maxLines: 3,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text('IPv6', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    SwitchListTile(
                      title: const Text('启用 IPv6'),
                      value: form.ipv6Enable,
                      onChanged: (v) => setState(() => form.ipv6Enable = v),
                      dense: true,
                    ),
                    if (form.ipv6Enable) ...[
                      DropdownButtonFormField<String>(
                        initialValue: form.ipv6GetTypeCtl.text,
                        decoration: const InputDecoration(
                          labelText: 'IPv6 获取方式',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'url', child: Text('URL')),
                          DropdownMenuItem(
                            value: 'netInterface',
                            child: Text('网卡'),
                          ),
                          DropdownMenuItem(value: 'cmd', child: Text('命令')),
                        ],
                        onChanged: (v) {
                          setState(() => form.ipv6GetTypeCtl.text = v ?? 'url');
                        },
                      ),
                      const SizedBox(height: 8),
                      if (form.ipv6GetTypeCtl.text == 'url')
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'IPv6 URL',
                            border: OutlineInputBorder(),
                          ),
                          controller: form.ipv6UrlCtl,
                        ),
                      if (form.ipv6GetTypeCtl.text == 'netInterface')
                        DropdownButtonFormField<String>(
                          initialValue:
                              _config!.ipv6Interfaces
                                  .map((e) => e.name)
                                  .toList()
                                  .contains(form.ipv6NetInterfaceCtl.text)
                              ? form.ipv6NetInterfaceCtl.text
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'IPv6 网卡',
                            border: OutlineInputBorder(),
                          ),
                          items: _config!.ipv6Interfaces
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.name,
                                  child: Text(e.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(
                              () => form.ipv6NetInterfaceCtl.text = v ?? '',
                            );
                          },
                        ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'IPv6 域名（每行一个）',
                          border: OutlineInputBorder(),
                        ),
                        controller: form.ipv6DomainsCtl,
                        maxLines: 3,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(() => _dnsForms.add(_DnsFormData())),
            icon: const Icon(Icons.add),
            label: const Text('添加 DDNS 配置'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _saving ? null : _saveConfig,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      '保存配置',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _DnsFormData {
  final nameCtl = TextEditingController();
  final dnsNameCtl = TextEditingController();
  final dnsIdCtl = TextEditingController();
  final dnsSecretCtl = TextEditingController();
  final ttlCtl = TextEditingController(text: '600');
  bool ipv4Enable = false;
  final ipv4GetTypeCtl = TextEditingController(text: 'url');
  final ipv4UrlCtl = TextEditingController();
  final ipv4NetInterfaceCtl = TextEditingController();
  final ipv4DomainsCtl = TextEditingController();
  bool ipv6Enable = false;
  final ipv6GetTypeCtl = TextEditingController(text: 'netInterface');
  final ipv6UrlCtl = TextEditingController();
  final ipv6NetInterfaceCtl = TextEditingController();
  final ipv6DomainsCtl = TextEditingController();
  int id = 0;

  _DnsFormData();

  factory _DnsFormData.fromConfig(DnsConfig c) {
    final f = _DnsFormData();
    f.id = c.id;
    f.nameCtl.text = c.name;
    f.dnsNameCtl.text = c.dnsName;
    f.dnsIdCtl.text = c.dnsId;
    f.dnsSecretCtl.text = c.dnsSecret;
    f.ttlCtl.text = c.ttl;
    f.ipv4Enable = c.ipv4Enable;
    f.ipv4GetTypeCtl.text = c.ipv4GetType;
    f.ipv4UrlCtl.text = c.ipv4Url;
    f.ipv4NetInterfaceCtl.text = c.ipv4NetInterface;
    f.ipv4DomainsCtl.text = c.ipv4Domains;
    f.ipv6Enable = c.ipv6Enable;
    f.ipv6GetTypeCtl.text = c.ipv6GetType;
    f.ipv6UrlCtl.text = c.ipv6Url;
    f.ipv6NetInterfaceCtl.text = c.ipv6NetInterface;
    f.ipv6DomainsCtl.text = c.ipv6Domains;
    return f;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': nameCtl.text,
      'dnsName': dnsNameCtl.text,
      'dnsId': dnsIdCtl.text,
      'dnsSecret': dnsSecretCtl.text,
      'ttl': ttlCtl.text,
      'ipv4Enable': ipv4Enable,
      'ipv4GetType': ipv4GetTypeCtl.text,
      'ipv4Url': ipv4UrlCtl.text,
      'ipv4NetInterface': ipv4NetInterfaceCtl.text,
      'ipv4Domains': ipv4DomainsCtl.text,
      'ipv6Enable': ipv6Enable,
      'ipv6GetType': ipv6GetTypeCtl.text,
      'ipv6Url': ipv6UrlCtl.text,
      'ipv6NetInterface': ipv6NetInterfaceCtl.text,
      'ipv6Domains': ipv6DomainsCtl.text,
    };
  }

  void dispose() {
    nameCtl.dispose();
    dnsNameCtl.dispose();
    dnsIdCtl.dispose();
    dnsSecretCtl.dispose();
    ttlCtl.dispose();
    ipv4GetTypeCtl.dispose();
    ipv4UrlCtl.dispose();
    ipv4NetInterfaceCtl.dispose();
    ipv4DomainsCtl.dispose();
    ipv6GetTypeCtl.dispose();
    ipv6UrlCtl.dispose();
    ipv6NetInterfaceCtl.dispose();
    ipv6DomainsCtl.dispose();
  }
}
