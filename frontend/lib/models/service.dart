class Service {
  final String category;
  final String name;
  final String description;
  final String duration;
  final double price;
  final String image;
  final bool vip;

  const Service({
    required this.category,
    required this.name,
    required this.description,
    required this.duration,
    required this.price,
    required this.image,
    this.vip = false,
  });

  String get priceLabel => 'R\$ ${price.toStringAsFixed(2)}';
}
