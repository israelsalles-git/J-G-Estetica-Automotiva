import 'dart:async';
import 'dart:convert';

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

  /// Chamado quando a API responde 401 a uma requisição que levou token
  /// (sessão vencida). O token é descartado ANTES de chamar, então vários 401
  /// ao mesmo tempo disparam o aviso só uma vez. Um 401 no login (sem token)
  /// não dispara nada.
  void Function()? onSessaoExpirada;

  /// Endereço base da API, usado para montar links de fotos (`/arquivos/...`).
  String get baseUrl => _baseUrl;

  bool get hasToken => _token != null;

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
    final tokenUsado = _token;
    final http.Response resposta;
    try {
      resposta = await chamada().timeout(_timeout);
    } on TimeoutException {
      throw const AppException('O servidor demorou para responder. Tente novamente.');
    } on http.ClientException {
      throw const AppException('Não foi possível conectar ao servidor.');
    }

    final corpo = resposta.bodyBytes.isEmpty
        ? null
        : jsonDecode(utf8.decode(resposta.bodyBytes));

    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return corpo;
    }
    // 401 com token = sessão vencida. Só avisa se o token ainda é o mesmo que
    // foi enviado (se já foi limpo ou trocado por outro login, ignora).
    if (resposta.statusCode == 401 && tokenUsado != null && _token == tokenUsado) {
      _token = null;
      onSessaoExpirada?.call();
    }
    throw AppException(_mensagemDeErro(resposta.statusCode, corpo));
  }

  /// A API manda `{"detail": "..."}` com mensagens em português. Erros de validação
  /// (422) vêm como lista, então usamos uma mensagem genérica para eles.
  static String _mensagemDeErro(int status, dynamic corpo) {
    if (status == 401) return 'Sessão expirada. Entre novamente.';
    if (corpo is Map && corpo['detail'] is String) return corpo['detail'] as String;
    if (status == 422) return 'Confira os dados informados e tente novamente.';
    return 'Algo deu errado no servidor. Tente novamente.';
  }

  /// Pergunta se a API está de pé (`GET /health`). Nunca lança erro.
  Future<bool> verificarSaude({String path = '/health'}) async {
    try {
      final r = await _http.get(_uri(path)).timeout(_timeout);
      return r.statusCode >= 200 && r.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void close() => _http.close();
}
