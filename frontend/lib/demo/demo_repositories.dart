import 'package:flutter/services.dart';

import '../core/app_exception.dart';
import '../models/booking_request.dart';
import '../models/service.dart';
import '../models/work.dart';
import '../services/booking_repository.dart';
import '../services/catalog_repository.dart';
import '../services/works_repository.dart';


class DemoCatalogRepository implements CatalogRepository {
  const DemoCatalogRepository();

  @override
  Future<List<Service>> fetchServices() async => _services;

  static const _services = <Service>[
    Service(
      id: 'lavagem-carro',
      category: 'Carro',
      name: 'Lavagem de Carro',
      description:
          'Limpeza completa externa e interna com produtos premium pH neutro.',
      duration: '2hrs',
      price: 70,
      imageUrl:
          'https://images.pexels.com/photos/20051469/pexels-photo-20051469.jpeg?auto=compress&cs=tinysrgb&w=800',
    ),
    Service(
      id: 'lavagem-carro-cera',
      category: 'Carro',
      name: 'Lavagem de Carro + Cera',
      description:
          'Lavagem detalhada com aplicação de cera para brilho e proteção da pintura.',
      duration: '3hrs',
      price: 80,
      imageUrl:
          'https://images.pexels.com/photos/6026083/pexels-photo-6026083.jpeg?auto=compress&cs=tinysrgb&w=800',
    ),
    Service(
      id: 'lavagem-moto',
      category: 'Moto',
      name: 'Lavagem de Moto',
      description:
          'Lavagem cuidadosa de motos com produtos específicos e secagem técnica.',
      duration: '1hr',
      price: 50,
      imageUrl:
          'https://images.pexels.com/photos/4513028/pexels-photo-4513028.jpeg?auto=compress&cs=tinysrgb&w=800',
    ),
    Service(
      id: 'lavagem-moto-cera',
      category: 'Moto',
      name: 'Lavagem de Moto + Cera',
      description:
          'Lavagem completa com acabamento em cera para brilho duradouro.',
      duration: '1h30',
      price: 60,
      imageUrl:
          'https://images.pexels.com/photos/4513031/pexels-photo-4513031.jpeg?auto=compress&cs=tinysrgb&w=800',
    ),
    Service(
      id: 'lavagem-detalhada-moto',
      category: 'Moto',
      name: 'Lavagem Detalhada de Moto',
      description:
          'Tratamento de alta precisão: limpeza minuciosa de cada componente.',
      duration: '4hrs',
      price: 150,
      imageUrl:
          'https://images.pexels.com/photos/4876631/pexels-photo-4876631.jpeg?auto=compress&cs=tinysrgb&w=800',
      vip: true,
    ),
  ];
}

/// Não envia nada: só mostra que o botão funciona visualmente.
class DemoBookingRepository implements BookingRepository {
  const DemoBookingRepository();

  @override
  Future<Set<String>> fetchBusySlots(String day) async => const <String>{};

  @override
  Future<BookingResult> submit(BookingRequest request) async => const BookingResult(
      message: 'Pré-visualização: nenhum agendamento foi enviado (backend não conectado).');
}

/// Mostra as imagens que estiverem em `assets/trabalhos/` (declare a pasta no
/// pubspec.yaml). Apenas exibe; não cadastra, edita nem remove nada.
class DemoWorksRepository implements WorksRepository {
  const DemoWorksRepository();

  static const folder = 'assets/trabalhos/';
  static const _extensions = ['.jpg', '.jpeg', '.png', '.webp'];

@override
Future<List<Work>> fetchWorks() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

  final paths = manifest
      .listAssets()
      .where((path) =>
          path.startsWith(folder) &&
          _extensions.any((e) => path.toLowerCase().endsWith(e)))
      .toList()
    ..sort();

  return [
    for (final path in paths)
      Work(id: path, imageUrl: path),
  ];
}

  @override
  Future<Work> createWork(WorkDraft draft) async => throw backendNotConnected;

  @override
  Future<Work> updateWork(Work work) async => throw backendNotConnected;

  @override
  Future<void> deleteWork(String id) async => throw backendNotConnected;
}
