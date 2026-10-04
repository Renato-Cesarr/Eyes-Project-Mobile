# REN-62 — Integração da instrumentação de calibração

Registro de 04/10/2026. Base integrada: `a893cacfe289aefd29ea123a9730910ce2a0ace7`
da `dev`, após o PR mobile #16. A integração reaplica `b764cf1`, `36cffad` e
`8cece0b`, preservando conta opcional, persistência, aparência, acessibilidade e
o fluxo atual da câmera. Os commits reaplicados são `5263cdb`, `1743958` e
`813617b`.

## Ativação e isolamento

O bootstrap usa `PlatformCalibrationConfigurationSource.forBuild`. Sem
`EYES_CALIBRATION=true`, ou no ambiente `prod`, não consulta o canal Android.
Para habilitar uma sessão, o canal também exige APK `debuggable` e uma intent
ADB com `calibrationEnabled=true`. `emitEvent` verifica novamente essas duas
condições nativas antes de escrever no log. A fonte inválida gera diagnóstico
técnico e mantém o coletor desativado.

O observador acompanha decisões e fila de alertas. O callback nativo do TTS
registra seu início e procura um alerta correspondente. Eventos estruturados
contêm classes/faixas, caixas normalizadas e durações; não incluem imagens,
áudio, senha ou token. A correlação e seus marcos temporais ainda precisam do
protocolo científico consolidado na REN-68 e validação física na REN-37.

## Execução reproduzível e identidade

Siga [REN-37-protocol.md](REN-37-protocol.md). A primeira execução do script
compila Profile/dev com opt-in e registra ao lado do APK um recibo
`.calibration.json`, com commit, indicação de alterações locais e SHA-256 do
APK, modelo e política. Coletas comparáveis devem partir de árvore limpa.
`-SkipBuild` requer esse recibo e rejeita um APK cujo hash mudou. Os metadados
inicial e final incluem a identidade do build e modelo/versão/API do aparelho.
O gerador inclui esses campos quando recebe `--device-metrics`.

Use um arquivo `.jsonl` exato por relatório, ou uma pasta dedicada a um único
split, versão e finalidade. A agregação atual percorre apenas os `.jsonl` do
nível informado e não separa automaticamente calibração de avaliação. Não
inclua fixtures no diretório de ensaios físicos. A seleção e validação de
entradas permanece na REN-68. O serial ADB fica em evidência local; anonimizar
antes de publicar resultados.

## Verificações desta integração

- `flutter test --no-pub --coverage --reporter compact`: 220 testes aprovados.
- `flutter analyze --no-pub`: nenhuma ocorrência.
- `dart run tool/validate_design_tokens.dart`: aprovado.
- `dart format --output=none --set-exit-if-changed lib test tool`: 197 arquivos
  verificados, sem alterações pendentes.
- Sintaxe dos dois scripts PowerShell e geração da identidade do build
  verificadas; commit, árvore com alterações e hash do APK conferidos.
- `aapt2 dump badging`: pacote `br.com.eyesproject.mobile.dev` e
  `application-debuggable` confirmados no APK Profile.
- `flutter build apk --profile --flavor dev --target lib/main_dev.dart
  --dart-define=EYES_CALIBRATION=true --no-pub`: APK gerado com sucesso.
- `dart run tool/calibration_report.dart --input
  test/fixtures/calibration/session.jsonl --output <arquivo-fora-da-coleta.md>`:
  relatório e JSON gerados a partir da fixture de quatro eventos.

Esses comandos verificam integração, comportamento automatizado, compilação
nativa e funcionamento do gerador. O relatório da fixture é sintético e não
representa latência, precisão ou estabilidade de um aparelho.

O formatador na raiz após o build encontrou uma falha de enumeração em uma
pasta gerada pelo Gradle no Windows; o check deve operar nos diretórios de
fonte, e a CI limpa continua como verificação adicional.

## Evidências anteriores e pendências

Os 31 arquivos locais anteriores foram preservados na origem e copiados, com
manifesto SHA-256, para `output/execucao-2026-10-04/` do workspace de auditoria.
O piloto de 16/09 permanece histórico e não é uma avaliação desta integração.
Não havia aparelho autorizado no ADB em 04/10 para realizar nova coleta.

REN-37/68 cobrem protocolo final, avaliação separada, amostra suficiente,
latência e sessão prolongada. REN-32/41/42 cobrem ensaios assistivos e físicos.
REN-63 cobre o Quality Gate da `dev`, que em 04/10 estava sem definição de
New Code no Sonar. A integração não comprova essas aprovações.
