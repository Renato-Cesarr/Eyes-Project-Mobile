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
- plugins oficiais `camera` e `permission_handler` para câmera Android e
  permissões em tempo de execução.

## Pré-requisitos

1. Android Studio com Android SDK e um emulador ou aparelho Android;
2. Java 21 disponível para o toolchain Android;
3. FVM instalado:

```powershell
dart pub global activate fvm 4.1.2
```

## Setup reproduzível

```powershell
fvm install
fvm flutter pub get
fvm flutter doctor -v
./scripts/check-toolchain.ps1
```

O diagnóstico exige Flutter `3.44.0` por FVM e Java 21. A CI usa as mesmas
versões declaradas em `.fvmrc` e `.java-version`, validando-as antes de baixar
as dependências. Não regenere `pubspec.lock` com outro SDK sem revisão.

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

O `permission_handler` está fixado em `12.0.3`. A linha 13 passou a exigir
compile SDK 37, enquanto o Android Gradle Plugin 9.0.1 usado pelo Flutter 3.44
recomenda no máximo SDK 36. A atualização será feita somente junto com uma
migração revisada do toolchain, evitando quebrar builds reproduzíveis.

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

Pull Requests para `dev` e `main`, assim como pushes nessas branches, executam
formatação, análise estática, testes com cobertura LCOV, builds dos flavors e
análise no SonarQube Cloud. O job só é aprovado quando o Quality Gate do Sonar
é aprovado. O repositório está vinculado ao projeto
`Renato-Cesarr_Eyes-Project-Mobile` no SonarQube Cloud e usa o secret
`SONAR_TOKEN` do GitHub Actions para autenticar a análise.

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

## Câmera e varredura local

A feature `scanning` mantém o domínio independente dos plugins nativos. A
implementação Android usa a câmera traseira, resolução média, áudio desativado e
meta inicial de 12 frames por segundo. O pipeline aceita apenas um frame em
processamento e um frame pendente; quando chegam imagens adicionais, preserva a
mais recente e descarta as intermediárias para impedir crescimento de memória e
alertas baseados em imagens antigas.

O botão **Abrir câmera** conduz à tela de diagnóstico acessível. A permissão é
solicitada somente após a ação do usuário. Negação temporária, bloqueio
permanente, câmera ocupada, ausência de hardware, timeout e falha de stream são
estados distintos e recuperáveis. Fotos e vídeos nunca são salvos.

Ao pausar, sair da tela ou enviar o aplicativo para segundo plano, o stream e o
controller nativo são liberados. Se a varredura estava ativa antes de o app ir
para segundo plano, ela é preparada novamente no retorno. Rotação e orientação
do preview permanecem sob responsabilidade do plugin oficial e das
configurações Android versionadas.

Validação manual em aparelho Android:

1. executar `flutter run --flavor dev --target lib/main_dev.dart`;
2. abrir **Câmera e varredura** e conceder a permissão;
3. confirmar preview, pausa, retomada e encerramento;
4. repetir negando a permissão e, depois, bloqueando-a nas configurações;
5. alternar entre o Eyes e outro aplicativo e confirmar a liberação da câmera;
6. repetir com TalkBack e fonte em 200%.

Consulte o [ADR 0004](docs/adr/0004-camera-stream-lifecycle-and-backpressure.md)
para as decisões de lifecycle, backpressure e privacidade.

## Visão computacional offline

O EfficientDet-Lite0 e seu manifesto são distribuídos como assets e validados
por tamanho, SHA-256 e contrato de tensores antes do uso. A inferência roda
localmente em um isolate persistente; frames atravessam a fronteira por
`TransferableTypedData`, e somente as entidades Pessoa, Cadeira, Mesa e Mochila
retornam à aplicação. Não existe upload, persistência de imagem ou fallback de
rede.

O `VisionController` expõe `loading`, `ready` e `error` por Riverpod e encerra o
isolate no background. A conexão desse controller à tela e ao lifecycle da
câmera pertence à Fase 4 da REN-29. Consulte o
[ADR 0005](docs/adr/0005-vision-worker-isolate-and-transferable-frames.md).

## Fluxo Git

As funcionalidades nascem de `dev`, usam `feat/<linear-id>-<nome-curto>` e
retornam para `dev` por Pull Request. A promoção de versão ocorre de `dev` para
`main`, que é protegida.
