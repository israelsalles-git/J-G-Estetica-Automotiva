import 'package:url_launcher/url_launcher.dart';

class WhatsappService {
  WhatsappService._();

  /// TROQUE pelo número real (DDI + DDD + número).
  static const phone = '5511999999999';

  static Future<void> open({String? message}) async {
    final text = Uri.encodeComponent(
        message ?? 'Olá! Gostaria de agendar um horário.');
    final uri = Uri.parse('https://wa.me/$phone?text=$text');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
