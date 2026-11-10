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

  final bool active;

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
    this.active = true,
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
      price: double.parse(json['preco'].toString()),
      vip: (json['destaque'] as bool?) ?? false,
      active: (json['ativo'] as bool?) ?? true,
    );
  }

  String get priceLabel => 'R\$ ${price.toStringAsFixed(2)}';
}

String formatarDuracao(int minutos) {
  final horas = minutos ~/ 60;
  final resto = minutos % 60;
  if (horas == 0) return '${resto}min';
  if (resto == 0) return '${horas}h';
  return '${horas}h${resto.toString().padLeft(2, '0')}';
}
