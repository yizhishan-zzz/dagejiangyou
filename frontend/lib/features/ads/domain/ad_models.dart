class AdSlot {
  const AdSlot({
    required this.id,
    required this.placement,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionRoute,
    required this.accentHex,
    this.imageUrl,
  });

  final String id;
  final String placement;
  final String label;
  final String title;
  final String subtitle;
  final String actionLabel;
  final String actionRoute;
  final String accentHex;
  final String? imageUrl;

  factory AdSlot.fromJson(Map<String, dynamic> json) {
    return AdSlot(
      id: json['id']?.toString() ?? '',
      placement: json['placement']?.toString() ?? '',
      label: json['label']?.toString() ?? '社区推荐',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      actionLabel: json['actionLabel']?.toString() ?? '查看',
      actionRoute: json['actionRoute']?.toString() ?? '',
      accentHex: json['accentHex']?.toString() ?? '#2257D9',
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}
