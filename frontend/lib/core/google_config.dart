/// Client ID do cliente OAuth (tipo Web application) usado no login do painel com Google.
/// É um identificador público, não um segredo. Pode ser trocado sem mexer no código:
///   flutter run -d chrome -t lib/main_admin.dart --web-port=5000 --dart-define=GOOGLE_CLIENT_ID=...
/// A porta 5000 precisa estar em "Origens JavaScript autorizadas" do cliente OAuth
/// (senão o Google recusa com origin_mismatch).
const googleClientId = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
  defaultValue:
      '829865536534-hvarjptdqmf06cqcan81bae58nrskdhk.apps.googleusercontent.com',
);
