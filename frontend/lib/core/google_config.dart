/// Client ID do cliente OAuth (tipo Web application) usado no login do painel com Google.
/// É um identificador público, não um segredo. Pode ser trocado sem mexer no código:
///   flutter run -d chrome -t lib/main_admin.dart --dart-define=GOOGLE_CLIENT_ID=...
const googleClientId = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
  defaultValue:
      '829865536534-hvarjptdqmf06cqcan81bae58nrskdhk.apps.googleusercontent.com',
);
