import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/core/app_exception.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Cria um ApiClient que sempre responde [status] com [body].
/// Usa Response.bytes porque Response(String) codifica em latin1 e estraga acentos.
ApiClient api(int status, String body, {String? token}) {
  final c = ApiClient(
    baseUrl: 'http://x',
    httpClient: MockClient(
      (_) async => http.Response.bytes(utf8.encode(body), status),
    ),
  );
  if (token != null) c.setToken(token);
  return c;
}

Matcher erroComMensagem(String texto) => throwsA(
      isA<AppException>().having((e) => e.message, 'message', texto),
    );

void main() {
  group('mensagens de erro do ApiClient', () {
    test('401 sem token mostra o detail (login)', () {
      expect(
        api(401, '{"detail":"E-mail ou senha incorretos"}')
            .postJson('/auth/login', {}),
        erroComMensagem('E-mail ou senha incorretos'),
      );
    });

    test('401 com token mostra "Sessão expirada"', () {
      expect(
        api(401, '{"detail":"Token inválido"}', token: 'abc').get('/admin'),
        erroComMensagem('Sessão expirada. Entre novamente.'),
      );
    });

    test('422 com lista e "Value error, ..." mostra o texto limpo', () {
      const corpo =
          '{"detail":[{"type":"value_error","msg":"Value error, A data do agendamento deve ser futura"}]}';
      expect(
        api(422, corpo).postJson('/agendamentos', {}),
        erroComMensagem('A data do agendamento deve ser futura'),
      );
    });

    test('422 com msg nativa em inglês cai na mensagem genérica de validação', () {
      const corpo = '{"detail":[{"type":"missing","msg":"Field required"}]}';
      expect(
        api(422, corpo).postJson('/agendamentos', {}),
        erroComMensagem('Confira os dados informados e tente novamente.'),
      );
    });

    test('502 com HTML não lança FormatException e usa a mensagem genérica', () {
      expect(
        api(502, '<html><body>Bad Gateway</body></html>').get('/servicos'),
        erroComMensagem('Algo deu errado no servidor. Tente novamente.'),
      );
    });

    test('409 com detail mostra o detail', () {
      expect(
        api(409, '{"detail":"Horário já ocupado"}').postJson('/agendamentos', {}),
        erroComMensagem('Horário já ocupado'),
      );
    });

    test('429 com detail mostra o detail da API', () {
      expect(
        api(429, '{"detail":"Muitas tentativas. Aguarde um pouco e tente novamente."}')
            .postJson('/agendamentos/publico', {}),
        erroComMensagem('Muitas tentativas. Aguarde um pouco e tente novamente.'),
      );
    });

    test('429 sem detail (ex.: proxy) usa a mensagem própria', () {
      expect(
        api(429, '<html><body>Too Many Requests</body></html>')
            .postJson('/auth/login', {}),
        erroComMensagem('Muitas tentativas. Aguarde um pouco e tente novamente.'),
      );
    });

    test('429 com token não derruba a sessão', () async {
      final c = api(429, '{"error":"Rate limit exceeded"}', token: 'abc');
      var expirou = false;
      c.onSessaoExpirada = () => expirou = true;

      await expectLater(
        c.get('/servicos'),
        erroComMensagem('Muitas tentativas. Aguarde um pouco e tente novamente.'),
      );
      expect(expirou, isFalse);
    });

    test('sucesso com corpo vazio devolve null', () async {
      expect(await api(204, '').get('/x'), isNull);
    });

    test('sucesso com JSON devolve o corpo', () async {
      expect(await api(200, '{"ok":true}').get('/x'), {'ok': true});
    });
  });

  group('mensagemDeErro', () {
    test('detail vazio ou de tipo inesperado cai na genérica', () {
      expect(
        ApiClient.mensagemDeErro(500, {'detail': []}),
        'Algo deu errado no servidor. Tente novamente.',
      );
      expect(
        ApiClient.mensagemDeErro(500, null),
        'Algo deu errado no servidor. Tente novamente.',
      );
    });

    test('401 sem token e sem detail cai na genérica', () {
      expect(
        ApiClient.mensagemDeErro(401, null),
        'Algo deu errado no servidor. Tente novamente.',
      );
    });
  });
}
