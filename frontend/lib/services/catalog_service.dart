import '../models/service.dart';

/// Fonte de dados do catálogo. Hoje é local; depois pode vir de uma API.
class CatalogService {
  CatalogService._();

  static const services = <Service>[
    Service(
      category: 'Carro',
      name: 'Lavagem de Carro',
      description:
          'Limpeza completa externa e interna com produtos premium pH neutro.',
      duration: '2hrs',
      price: 70,
      image:
          'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?w=800',
    ),
    Service(
      category: 'Carro',
      name: 'Lavagem de Carro + Cera',
      description:
          'Lavagem detalhada com aplicação de cera para brilho e proteção da pintura.',
      duration: '3hrs',
      price: 80,
      image:
          'https://images.unsplash.com/photo-1601362840469-51e4d8d58785?w=800',
    ),
    Service(
      category: 'Moto',
      name: 'Lavagem de Moto',
      description:
          'Lavagem cuidadosa de motos com produtos específicos e secagem técnica.',
      duration: '1hr',
      price: 50,
      image:
          'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=800',
    ),
    Service(
      category: 'Moto',
      name: 'Lavagem de Moto + Cera',
      description:
          'Lavagem completa com acabamento em cera para brilho duradouro.',
      duration: '1h30',
      price: 60,
      image:
          'https://images.unsplash.com/photo-1558980664-10e7170b5df9?w=800',
    ),
    Service(
      category: 'Moto',
      name: 'Lavagem Detalhada de Moto',
      description:
          'Tratamento de alta precisão: limpeza minuciosa de cada componente.',
      duration: '4hrs',
      price: 150,
      image:
          'https://images.unsplash.com/photo-1449426468159-d96dbf08f19f?w=800',
      vip: true,
    ),
  ];

  static const categories = ['Carro', 'Moto'];

  static const days = ['Sábado', 'Domingo'];

  static const timeSlots = [
    '07:00', '08:00', '09:00', '10:00', '11:00',
    '13:00', '14:00', '15:00', '16:00',
  ];

  /// Horários já ocupados (exemplo fixo).
  static const busySlots = {'10:00', '13:00'};

  static List<Service> byCategory(String category) =>
      services.where((s) => s.category == category).toList();
}
