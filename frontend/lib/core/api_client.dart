import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show VoidCallback, visibleForTesting;
// dart:io não existe no navegador (Flutter Web), por isso só usamos o http.ClientException.
import 'package:http/http.dart' as http;

import 'app_exception.dart';

/// Endereço da API. Troque sem mexer no código, por exemplo:
///   flutter run -d chrome --dart-define=API_URL=https://api.seudominio.com.br
const apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8000',
);

/// Cliente HTTP compartilhado pelos repositórios e pelo login.
///
/// Converte as respostas em JSON e os erros em [AppException] com mensagem pronta
/// para a tela. Depois do login, o token fica aqui e segue em todas as requisições.
class ApiClient {
  ApiClient({required String baseUrl, http.Client? httpClient})
      : _baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl,
        _http = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _http;

  static const _timeout = Duration(seconds: 15);

  String? _token;

  /// Endereço base da API, usado para montar links de fotos (`/arquivos/...`).
  String get baseUrl => _baseUrl;

  bool get hasToken => _token != null;

  /// Chamado quando a API responde 401 a uma requisição que levava token
  /// (sessão vencida). Não dispara no login com senha errada (401 sem token).
  VoidCallback? onSessaoExpirada;

  void setToken(String? token) => _token = token;

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _enviar(() => _http.get(_uri(path, query), headers: _headers));

  Future<dynamic> postJson(String path, Map<String, dynamic> corpo) =>
      _enviar(() => _http.post(
            _uri(path),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode(corpo),
          ));

  Future<dynamic> putJson(String path, Map<String, dynamic> corpo) =>
      _enviar(() => _http.put(
            _uri(path),
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode(corpo),
          ));

  Future<void> delete(String path) async {
    await _enviar(() => _http.delete(_uri(path), headers: _headers));
  }

  /// Envio de arquivo (multipart): campos de texto + uma imagem no campo [campoArquivo].
  Future<dynamic> postArquivo(
    String path, {
    required Map<String, String> campos,
    required String campoArquivo,
    required List<int> bytes,
    required String nomeArquivo,
  }) async {
    final requisicao = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(_headers)
      ..fields.addAll(campos)
      ..files.add(http.MultipartFile.fromBytes(campoArquivo, bytes, filename: nomeArquivo));
    return _enviar(() async {
      final envio = await requisicao.send().timeout(_timeout);
      return http.Response.fromStream(envio);
    });
  }

  Future<dynamic> _enviar(Future<http.Response> Function() chamada) async {
    // Guardado antes da chamada: um 401 só é "sessão expirada" se a requisição
    // realmente levava token (no login, 401 significa senha errada).
    final enviouToken = _token != null;

    final http.Response resposta;
    try {
      resposta = await chamada().timeout(_timeout);
    } on TimeoutException {
      throw const AppException('O servidor demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw const AppException('Não foi possível conectar ao servidor.');
    }

    final corpo = _decodificar(resposta);

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return corpo;
    }
    if (resposta.statusCode == 401 && enviouToken) onSessaoExpirada?.call();
    throw AppException(
      mensagemDeErro(resposta.statusCode, corpo, enviouToken: enviouToken),
    );
  }

  /// Lê o corpo como JSON. Se não for JSON (HTML de proxy/502, texto puro,
  /// UTF-8 inválido), devolve null em vez de lançar exceção.
  static dynamic _decodificar(http.Response r) {
    if (r.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(r.bodyBytes));
    } on FormatException {
      return null;
    }
  }

  /// Escolhe a mensagem mostrada ao usuário. A API manda `{"detail": ...}`:
  /// texto (nossas mensagens em português) ou lista (422 do Pydantic).
  @visibleForTesting
  static String mensagemDeErro(int status, dynamic corpo, {bool enviouToken = false}) {
    if (status == 401 && enviouToken) return 'Sessão expirada. Entre novamente.';

    final detail = corpo is Map ? corpo['detail'] : null;
    if (detail is String) return detail;
    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      final msg = (detail.first as Map)['msg'];
      // Nossos ValueError chegam como "Value error, <texto em português>".
      // Os erros nativos do Pydantic vêm em inglês: nesses casos cai na genérica.
      const prefixo = 'Value error, ';
      if (msg is String && msg.startsWith(prefixo)) {
        return msg.substring(prefixo.length);
      }
    }
    if (status == 422) return 'Confira os dados informados e tente novamente.';
    // Rate limit: a API já manda o detail em português; esta é a reserva para um 429
    // sem detail (ex.: barrado por um proxy na frente da API).
    if (status == 429) return 'Muitas tentativas. Aguarde um pouco e tente novamente.';
    return 'Algo deu errado no servidor. Tente novamente.';
  }

  /// Verifica se a API está no ar (GET /health). Nunca lança exceção.
  Future<bool> verificarSaude() async {
    try {
      final r = await _http
          .get(_uri('/health'), headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
      return r.statusCode >= 200 && r.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void close() => _http.close();
}
