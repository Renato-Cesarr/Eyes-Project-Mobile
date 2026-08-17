# Eyes Project Mobile

Aplicativo Android assistivo do Eyes Project para pessoas cegas ou com baixa
visão. Esta fundação prepara o MVP para reconhecimento de objetos com a câmera
do celular, sem incluir antecipadamente câmera externa ou funcionalidades
pós-MVP.

## Stack

- Flutter `3.44.0`, fixado por `.fvmrc`;
- Dart `3.12.0`;
- Riverpod e `AsyncNotifier` para estado e injeção de dependências;
- `go_router` para navegação declarativa;
- `dio` com logging de metadados sem headers, corpos ou query strings;
- `flutter_secure_storage` para credenciais e `shared_preferences` para
  preferências não sensíveis;
- localização oficial do Flutter, inicialmente em `pt-BR`.

## Pré-requisitos

1. Android Studio com Android SDK e um emulador ou aparelho Android;
2. Java 21 disponível para o toolchain Android;
3. FVM instalado:

```powershell
dart pub global activate fvm
```

## Setup reproduzível

```powershell
fvm install
fvm flutter pub get
fvm flutter doctor -v
```

Aceite as licenças do Android SDK na primeira configuração:

```powershell
fvm flutter doctor --android-licenses
```

Nenhum segredo deve ser salvo no repositório. URLs e configurações públicas de
build são fornecidas por `--dart-define`; tokens pertencem exclusivamente ao
armazenamento seguro em tempo de execução.

O `flutter_secure_storage` permanece na linha `10.3.x` durante o MVP: a versão
11 exige Android SDK 37, ainda incompatível com o toolchain Android 36 fixado
pelo Flutter estável usado neste projeto.

## Flavors

| Flavor | Application ID | Entry point | Uso |
| --- | --- | --- | --- |
| `dev` | `br.com.eyesproject.mobile.dev` | `lib/main_dev.dart` | desenvolvimento e homologação |
| `prod` | `br.com.eyesproject.mobile` | `lib/main_prod.dart` | versão final do MVP |

Executar desenvolvimento:

```powershell
fvm flutter run --flavor dev --target lib/main_dev.dart
```

Executar produção com endpoint configurado:

```powershell
fvm flutter run --flavor prod --target lib/main_prod.dart --dart-define=API_BASE_URL=https://api.exemplo.com
```

O endpoint padrão de produção usa o domínio reservado `.invalid`, evitando
conexões acidentais quando a configuração não for fornecida.

## Qualidade

```powershell
dart format --output=none --set-exit-if-changed .
fvm flutter analyze
fvm flutter test --coverage
fvm flutter build apk --debug --flavor dev --target lib/main_dev.dart
fvm flutter build appbundle --release --flavor prod --target lib/main_prod.dart --dart-define=API_BASE_URL=https://api.example.invalid
```

O bundle de produção gerado localmente não contém chave de assinatura. A chave
de release deverá ser fornecida por um cofre de segredos no pipeline de entrega,
nunca versionada.

## Arquitetura

O projeto usa Clean Architecture pragmática organizada por feature:

```text
lib/
├── app/               # composição, ambiente, rotas e tema
├── core/              # erros, logging, rede, persistência e acessibilidade
├── features/
│   └── <feature>/
│       ├── presentation/
│       ├── application/
│       ├── domain/
│       └── infrastructure/  # criada somente quando houver fronteira externa
├── l10n/              # textos visíveis ao usuário
└── main_<flavor>.dart
```

Uma feature não recebe camadas vazias. Repositórios e adapters só existem
quando separam uma fronteira real, como API, banco local, câmera ou modelo de
visão computacional. Consulte [docs/architecture.md](docs/architecture.md) e os
[ADRs](docs/adr/).

## Acessibilidade

- temas claro, escuro e variantes de alto contraste;
- fontes sem limitação artificial de escala;
- alvos de toque com altura mínima de 56 dp;
- conteúdo decorativo excluído da árvore semântica;
- títulos, hints e regiões `live` para TalkBack;
- feedback tátil e sonoro encapsulado em um serviço substituível;
- layouts roláveis para evitar overflow com fontes ampliadas.

Antes de concluir cada tela, valide manualmente com TalkBack, fonte no maior
tamanho suportado, alto contraste e navegação apenas por gestos do leitor de
tela.

## Fluxo Git

As funcionalidades nascem de `dev`, usam `feat/<linear-id>-<nome-curto>` e
retornam para `dev` por Pull Request. A promoção de versão ocorre de `dev` para
`main`, que é protegida.
