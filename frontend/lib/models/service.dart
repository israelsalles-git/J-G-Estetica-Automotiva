/// Serviço do catálogo (ex.: Lavagem de Carro).
///
/// `fromJson`/`toJson` são o único ponto que conhece o formato da API:
/// se o backend usar outros nomes de campo, ajuste só aqui.
class Service {
  final String id;
  final String category;
  final String name;
  final String description;
  final String duration;
  final double price;
  final String imageUrl;
  final bool vip;

  const Service({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.duration,
    required this.price,
    this.imageUrl = '',
    this.vip = false,
  });

  factory Service.fromJson(Map<String, dynamic> json) => Service(
        id: json['id'].toString(),
        category: json['category'] as String,
        name: json['name'] as String,
        description: (json['description'] as String?) ?? '',
        duration: (json['duration'] as String?) ?? '',
        price: (json['price'] as num).toDouble(),
        imageUrl: (json['imageUrl'] as String?) ?? '',
        vip: (json['vip'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'name': name,
        'description': description,
        'duration': duration,
        'price': price,
        'imageUrl': imageUrl,
        'vip': vip,
      };

  String get priceLabel => 'R\$ ${price.toStringAsFixed(2)}';
}
