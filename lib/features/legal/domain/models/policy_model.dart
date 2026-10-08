class PolicyLink {
  final String label;
  final String href;

  const PolicyLink({required this.label, required this.href});

  factory PolicyLink.fromJson(Map<String, dynamic> json) {
    return PolicyLink(
      label: json['label'] as String? ?? '',
      href: json['href'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'href': href,
      };
}

class PolicySection {
  final String title;
  final List<String> paragraphs;
  final List<String> items;
  final List<PolicyLink> links;

  const PolicySection({
    required this.title,
    this.paragraphs = const [],
    this.items = const [],
    this.links = const [],
  });

  factory PolicySection.fromJson(Map<String, dynamic> json) {
    return PolicySection(
      title: json['title'] as String? ?? '',
      paragraphs: (json['paragraphs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      links: (json['links'] as List<dynamic>?)
              ?.map((e) => PolicyLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'paragraphs': paragraphs,
        'items': items,
        'links': links.map((e) => e.toJson()).toList(),
      };
}

class PolicyModel {
  final String key;
  final String title;
  final String label;
  final String icon;
  final String description;
  final String intro;
  final List<PolicySection> sections;
  final bool requestForm;
  final String webUrl;

  const PolicyModel({
    required this.key,
    required this.title,
    required this.label,
    required this.icon,
    required this.description,
    required this.intro,
    required this.sections,
    this.requestForm = false,
    required this.webUrl,
  });

  factory PolicyModel.fromJson(String key, Map<String, dynamic> json) {
    final cleanSlug =
        key.replaceFirst(RegExp(r'^/+'), '').replaceFirst(RegExp(r'/+$'), '');
    return PolicyModel(
      key: cleanSlug,
      title: json['title'] as String? ?? '',
      label: json['label'] as String? ?? '',
      icon: json['icon'] as String? ?? 'shield',
      description: json['description'] as String? ?? '',
      intro: json['intro'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => PolicySection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      requestForm: json['requestForm'] == true,
      webUrl: 'https://hamimneo.github.io/necTeam-official/$cleanSlug/',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'label': label,
        'icon': icon,
        'description': description,
        'intro': intro,
        'sections': sections.map((e) => e.toJson()).toList(),
        'requestForm': requestForm,
      };
}
