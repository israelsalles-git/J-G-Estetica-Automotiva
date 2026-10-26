/// Textos e opções fixas da interface.
/// (Dados do negócio que mudam — serviços, horários ocupados, fotos — vêm do backend.)
class BusinessConfig {
  BusinessConfig._();

  static const name = 'Tal da Estética Automotiva';

  /// Logo (PNG com fundo transparente). Mesmo arquivo que o pubspec.yaml já declara.
  static const logoAsset = 'assents/ClientPageImages/Logo.png';

  /// Atendimento somente aos fins de semana.
  static const days = ['Sábado', 'Domingo'];

  static const timeSlots = [
    '07:00', '08:00', '09:00', '10:00', '11:00',
    '13:00', '14:00', '15:00', '16:00',
  ];
}
