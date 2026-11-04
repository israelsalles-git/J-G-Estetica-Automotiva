/// Serviço do catálogo (ex.: Lavagem de Carro).
///
/// `fromJson` é o único ponto que conhece o formato da API (`GET /servicos`):
/// se a API mudar nome de campo, ajuste só aqui.
class Service {
  final String id;
  final String category;
  final String name;
  final String description;
  final String duration;
  final int durationMinutes;
  final double price;
  final String imageUrl;
  final bool vip;

  const Service({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.duration,
    required this.durationMinutes,
    required this.price,
    this.imageUrl = '',
    this.vip = false,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    final minutos = (json['duracao_min'] as num).toInt();
    return Service(
      id: json['id'].toString(),
      category: (json['categoria'] as String?) ?? 'Outros',
      name: json['nome'] as String,
      description: (json['descricao'] as String?) ?? '',
      duration: formatarDuracao(minutos),
      durationMinutes: minutos,
      // A API envia o preço como texto com centavos ("70.00"); aceitamos número também.
      price: double.parse(json['preco'].toString()),
      vip: (json['destaque'] as bool?) ?? false,
    );
  }

  String get priceLabel => 'R\$ ${price.toStringAsFixed(2)}';
}

/// 60 -> "1h", 90 -> "1h30", 45 -> "45min".
String formatarDuracao(int minutos) {
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  if (horas == 0) return '${resto}min';
  if (resto == 0) return '${horas}h';
  return '${horas}h${resto.toString().padLeft(2, '0')}';
}
