class NetworkInterface {
  final String name;
  final List<String> address;

  NetworkInterface({required this.name, required this.address});

  factory NetworkInterface.fromJson(Map<String, dynamic> json) {
    return NetworkInterface(
      name: json['name'] as String? ?? '',
      address: (json['address'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class DnsConfig {
  int id;
  String name;
  String dnsName;
  String dnsId;
  String dnsSecret;
  String dnsExtParam;
  String ttl;
  bool ipv4Enable;
  String ipv4GetType;
  String ipv4Url;
  String ipv4NetInterface;
  String ipv4Cmd;
  String ipv4Domains;
  bool ipv6Enable;
  String ipv6GetType;
  String ipv6Url;
  String ipv6NetInterface;
  String ipv6Cmd;
  String ipv6Reg;
  String ipv6Domains;
  String httpInterface;

  DnsConfig({
    this.id = 0,
    this.name = '',
    this.dnsName = '',
    this.dnsId = '',
    this.dnsSecret = '',
    this.dnsExtParam = '',
    this.ttl = '600',
    this.ipv4Enable = false,
    this.ipv4GetType = 'url',
    this.ipv4Url = '',
    this.ipv4NetInterface = '',
    this.ipv4Cmd = '',
    this.ipv4Domains = '',
    this.ipv6Enable = false,
    this.ipv6GetType = 'netInterface',
    this.ipv6Url = '',
    this.ipv6NetInterface = '',
    this.ipv6Cmd = '',
    this.ipv6Reg = '',
    this.ipv6Domains = '',
    this.httpInterface = '',
  });

  factory DnsConfig.fromJson(Map<String, dynamic> json) {
    return DnsConfig(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      dnsName: json['dnsName'] as String? ?? '',
      dnsId: json['dnsId'] as String? ?? '',
      dnsSecret: json['dnsSecret'] as String? ?? '',
      dnsExtParam: json['dnsExtParam'] as String? ?? '',
      ttl: json['ttl'] as String? ?? '600',
      ipv4Enable: json['ipv4Enable'] as bool? ?? false,
      ipv4GetType: json['ipv4GetType'] as String? ?? 'url',
      ipv4Url: json['ipv4Url'] as String? ?? '',
      ipv4NetInterface: json['ipv4NetInterface'] as String? ?? '',
      ipv4Cmd: json['ipv4Cmd'] as String? ?? '',
      ipv4Domains: json['ipv4Domains'] as String? ?? '',
      ipv6Enable: json['ipv6Enable'] as bool? ?? false,
      ipv6GetType: json['ipv6GetType'] as String? ?? 'netInterface',
      ipv6Url: json['ipv6Url'] as String? ?? '',
      ipv6NetInterface: json['ipv6NetInterface'] as String? ?? '',
      ipv6Cmd: json['ipv6Cmd'] as String? ?? '',
      ipv6Reg: json['ipv6Reg'] as String? ?? '',
      ipv6Domains: json['ipv6Domains'] as String? ?? '',
      httpInterface: json['httpInterface'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dnsName': dnsName,
      'dnsId': dnsId,
      'dnsSecret': dnsSecret,
      'dnsExtParam': dnsExtParam,
      'ttl': ttl,
      'ipv4Enable': ipv4Enable,
      'ipv4GetType': ipv4GetType,
      'ipv4Url': ipv4Url,
      'ipv4NetInterface': ipv4NetInterface,
      'ipv4Cmd': ipv4Cmd,
      'ipv4Domains': ipv4Domains,
      'ipv6Enable': ipv6Enable,
      'ipv6GetType': ipv6GetType,
      'ipv6Url': ipv6Url,
      'ipv6NetInterface': ipv6NetInterface,
      'ipv6Cmd': ipv6Cmd,
      'ipv6Reg': ipv6Reg,
      'ipv6Domains': ipv6Domains,
      'httpInterface': httpInterface,
    };
  }
}

class AppConfig {
  final List<DnsConfig> dnsConf;
  final bool notAllowWanAccess;
  final String username;
  final String webhookUrl;
  final String webhookRequestBody;
  final String webhookHeaders;
  final List<NetworkInterface> ipv4Interfaces;
  final List<NetworkInterface> ipv6Interfaces;

  AppConfig({
    required this.dnsConf,
    required this.notAllowWanAccess,
    required this.username,
    required this.webhookUrl,
    required this.webhookRequestBody,
    required this.webhookHeaders,
    required this.ipv4Interfaces,
    required this.ipv6Interfaces,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      dnsConf: (json['dnsConf'] as List<dynamic>?)
              ?.map((e) => DnsConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      notAllowWanAccess: json['notAllowWanAccess'] as bool? ?? true,
      username: json['username'] as String? ?? '',
      webhookUrl: json['webhookUrl'] as String? ?? '',
      webhookRequestBody: json['webhookRequestBody'] as String? ?? '',
      webhookHeaders: json['webhookHeaders'] as String? ?? '',
      ipv4Interfaces: (json['ipv4Interfaces'] as List<dynamic>?)
              ?.map((e) => NetworkInterface.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ipv6Interfaces: (json['ipv6Interfaces'] as List<dynamic>?)
              ?.map((e) => NetworkInterface.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}