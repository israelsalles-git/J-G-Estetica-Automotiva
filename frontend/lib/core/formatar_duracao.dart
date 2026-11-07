/// Texto curto para a duração de um atendimento: "45 min", "1h", "1h30".
String formatarDuracao(Duration duracao) {
  final total = duracao.inMinutes;
  if (total < 60) return '$total min';
  final horas = total ~/ 60;
  final resto = total % 60;
  if (resto == 0) return '${horas}h';
  return '${horas}h${resto.toString().padLeft(2, '0')}';
}
