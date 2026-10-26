import 'dart:typed_data';

bool _filled(String? v) => v != null && v.trim().isNotEmpty;

/// Um trabalho da galeria "Últimos Trabalhos".
///
/// Só [id] e [imageUrl] são obrigatórios; título, descrição, categoria e data
/// são opcionais. [imageUrl] pode ser um caminho de asset (hoje) ou uma URL
/// http(s) (quando vier de uma API).
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

  factory Work.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'];
    return Work(
      id: json['id'].toString(),
      imageUrl: (json['imageUrl'] as String?) ?? '',
      title: json['title'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      date: rawDate is String ? DateTime.tryParse(rawDate) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'title': title,
        'description': description,
        'category': category,
        'date': date?.toIso8601String(),
      };

  Work copyWith({
    String? imageUrl,
    String? title,
    String? description,
    String? category,
    DateTime? date,
  }) =>
      Work(
        id: id,
        imageUrl: imageUrl ?? this.imageUrl,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        date: date ?? this.date,
      );

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

/// Dados para CADASTRAR um trabalho novo (ex.: vindo do painel administrativo).
/// Ainda não é usado por nenhuma tela: é o formato que a futura tela de
/// upload vai preencher e entregar ao `WorksProvider.add`.
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

  /// Campos de texto (a imagem vai à parte, como arquivo, em multipart).
  Map<String, String> toFields() => {
        if (_filled(title)) 'title': title!.trim(),
        if (_filled(description)) 'description': description!.trim(),
        if (_filled(category)) 'category': category!.trim(),
        if (date != null) 'date': date!.toIso8601String(),
      };
}
