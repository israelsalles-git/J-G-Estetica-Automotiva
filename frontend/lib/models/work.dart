import 'dart:typed_data';

import '../core/datas.dart';

bool _filled(String? v) => v != null && v.trim().isNotEmpty;

/// Um trabalho da galeria "Últimos Trabalhos".
///
/// Só [id] e [imageUrl] são obrigatórios; título, descrição, categoria e data
/// são opcionais. [imageUrl] é o endereço completo da foto na API
/// (ou um caminho de asset, quando usado sem backend).
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

  /// Converte o JSON de `GET /trabalhos`. [baseUrl] completa o caminho da foto
  /// (`imagem_url` vem como "/arquivos/trabalhos/...").
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

  /// Tem algum texto para mostrar abaixo da foto?
  bool get hasDetails =>
      _filled(title) || _filled(description) || _filled(category) || date != null;

  /// Data no formato dd/MM/aaaa (ou null).
  String? get dateLabel {
    final d = date;
    if (d == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }
}

/// Dados para CADASTRAR um trabalho novo (formulário do painel admin).
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

  /// Campos de texto do envio multipart (a imagem vai à parte, no campo `imagem`).
  Map<String, String> toFields() => {
        if (_filled(title)) 'titulo': title!.trim(),
        if (_filled(description)) 'descricao': description!.trim(),
        if (_filled(category)) 'categoria': category!.trim(),
        // A API espera só a data (AAAA-MM-DD), sem horário.
        if (date != null) 'data': dataIso(date!),
      };
}
