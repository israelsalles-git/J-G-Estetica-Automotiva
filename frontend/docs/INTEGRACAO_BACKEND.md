# Ligando o site ao backend

O site é **só visual** (Flutter + Dart, usando apenas o pacote `provider`, que você já tem).
Ele **não busca, não decide e não envia nada por conta própria**: mostra o que o backend entrega e
avisa o backend quando o cliente toca em algo. Não há cliente HTTP, URL, endpoint nem regra de negócio
dentro do código. **Como** o backend é chamado (http, dio, GraphQL, o que for) é decisão de quem o conectar.

## Onde o backend se liga

Só em **`lib/main.dart`**, no bloco "LIGAÇÃO COM O BACKEND". Ali ficam 3 objetos, cada um implementando
um **contrato** (classe abstrata) de `lib/services/`:

| Contrato | O que o backend entrega / faz |
|---|---|
| `CatalogRepository` | `fetchServices()` → lista de `Service` |
| `BookingRepository` | `fetchBusySlots(day)` → horários ocupados · `submit(BookingRequest)` → recebe o pedido e devolve o texto para o cliente |
| `WorksRepository` | `fetchWorks()` → fotos da galeria · `createWork` / `updateWork` / `deleteWork` (painel admin) |

Exemplo (o `ApiClient` abaixo é só ilustração — escreva com a biblioteca que preferir):

```dart
class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._api);
  final MeuClienteHttp _api;

  @override
  Future<List<Service>> fetchServices() async {
    final lista = await _api.get('/servicos') as List;          // caminho definido pelo backend
    return [for (final j in lista) Service.fromJson(j as Map<String, dynamic>)];
  }
}
```

Depois, no `main.dart`, troque `DemoCatalogRepository()` por `ApiCatalogRepository(...)` (idem para os outros).
Para erros que o cliente deve ver, lance `AppException('mensagem em português')`.

## Dados de demonstração (`lib/demo/`)

Existem **só para o site mostrar algo na tela** enquanto não há backend: lista de serviços de exemplo,
um "agendamento" que não envia nada e a galeria lendo `assets/trabalhos/`. **Apague a pasta `lib/demo/`**
quando o backend entrar. Para ver o site "sem nada" (como ficará se o backend estiver fora do ar), use
`NotConnectedCatalogRepository()` etc. — a tela mostra o estado de erro com "Tentar novamente".

## Botão flutuante de contato

`HomePage(onContactPressed: ...)` — sem ação padrão. Hoje, ao tocar, aparece um aviso de que o contato ainda
não está conectado. Quem conectar decide o que ele faz.

## Formato dos dados

`fromJson` / `toJson` dos modelos (`lib/models/`) são apenas conversores, para facilitar. Se o backend usar
outros nomes de campo, ajuste **só ali**.

- **Service**: `id, category, name, description, duration, price, imageUrl, vip`
- **Work**: `id, imageUrl, title?, description?, category?, date? (ISO 8601)`
- **BookingRequest** (enviado): `serviceId, day, time, customerName?, customerPhone?, customerEmail?, notes?`

`imageUrl` aceita endereço `http(s)` **ou** caminho de arquivo do projeto (`assets:` do pubspec).
Observação: `day` hoje é "Sábado"/"Domingo"; um backend real provavelmente vai querer uma **data**.

## O que a interface já tem pronto

- **Estados de tela** (carregando / erro com "Tentar novamente" / vazio) no catálogo, na galeria e nos horários;
  botão "Confirmar" com "Enviando…".
- **Validações visuais** em `lib/core/validators.dart` (obrigatório, nome, telefone BR, e-mail) e o campo reutilizável
  `AppTextField` (o parâmetro `name` = nome da propriedade enviada ao backend). Hoje o formulário pede só
  dia e horário; se o backend exigir nome/telefone, adicione os `AppTextField` na `_BookingForm`.
- **Galeria**: card 4:3 com título, descrição, categoria e data opcionais; `WorksProvider` já tem
  `add / update / remove` para o painel admin (chamam o `WorksRepository`).

## Pendências (do backend / painel admin)

- Implementar os 3 contratos e definir o formato do JSON.
- Armazenamento das fotos (devolver `imageUrl`) e a tela de upload do admin (precisará de um seletor de arquivo).
- Autenticação do painel admin e regras de agendamento (conflito, confirmação, cancelamento).
