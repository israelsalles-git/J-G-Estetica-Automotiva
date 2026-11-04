String _dois(int n) => n.toString().padLeft(2, '0');

/// Data no formato AAAA-MM-DD (o que a API espera para datas).
String dataIso(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_dois(d.month)}-${_dois(d.day)}';

/// Data e hora sem fuso, AAAA-MM-DDTHH:MM:00. A API lê no horário da empresa (Brasília).
String dataHoraIsoSemFuso(DateTime d) => '${dataIso(d)}T${_dois(d.hour)}:${_dois(d.minute)}:00';

/// Data no formato dd/MM/AAAA, para mostrar ao cliente.
String dataBr(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';
