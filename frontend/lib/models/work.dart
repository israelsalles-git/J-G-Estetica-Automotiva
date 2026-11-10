import 'dart:typed_data';

import '../core/datas.dart';

bool _filled(String? v) => v != null && v.trim().isNotEmpty;

class Work {
  final String id;
  final String imageUrl;
  final String? title;
  final String? description;
  final String? category;
  final DateTime? date;

  const Work({
    required this.id,
    required this.imageUrl,
    this.title,
    this.description,
    this.category,
    this.date,
  });

  factory Work.fromJson(Map<String, dynamic> json, {String baseUrl = ''}) {
    final rawDate = json['data'];
    return Work(
      id: json['id'].toString(),
      imageUrl: '$baseUrl${json['imagem_url'] ?? ''}',
      title: json['titulo'] as String?,
      description: json['descricao'] as String?,
      category: json['categoria'] as String?,
      date: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }

  bool get isNetworkImage =>
      imageUrl.startsWith('http://') || imageUrl.startsWith('https://');

  bool get hasDetails =>
      _filled(title) || _filled(description) || _filled(category) || date != null;

  String? get dateLabel {
    final d = date;
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

class WorkDraft {
  final Uint8List imageBytes;
  final String imageFileName;
  final String? title;
  final String? description;
  final String? category;
  final DateTime? date;

  const WorkDraft({
    required this.imageBytes,
    required this.imageFileName,
    this.title,
    this.description,
    this.category,
    this.date,
  });

  Map<String, String> toFields() => {
        if (_filled(title)) 'titulo': title!.trim(),
        if (_filled(description)) 'descricao': description!.trim(),
        if (_filled(category)) 'categoria': category!.trim(),
        // A API espera só a data (AAAA-MM-DD), sem horário.
        if (date != null) 'data': dataIso(date!),
      };
}
