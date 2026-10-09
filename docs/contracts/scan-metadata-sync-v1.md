# Sincronização consentida de sessões — REN-75

Implementação do consumidor do contrato backend `docs/contracts/scan-sessions-v1.md` (REN-18, integrado em dev no commit 7a32baa2cca81219999f52ca77dfe20650416521). Esta entrega não comprova TalkBack, modo avião em aparelho, avaliação científica ou aceite visual do responsável.

## Comportamento do produto

A conta é opcional. Câmera, inferência, proximidade relativa, voz e háptico não aguardam chamadas HTTP. A coleta começa somente com conta e consentimento vinculado ao proprietário. A preferência antiga, sem proprietário, exige novo consentimento.

A mudança de estado da câmera inicia/encerra segmentos: pausa, encerramento, erro e background fecham a coleta; retomada inicia outro segmento. Limites de 200 avisos e 119 minutos de frames segmentam a coleta sem parar a assistência. Limites de contadores respeitam o contrato. Não há envio durante a varredura. Iniciar outra varredura bloqueia os próximos lotes do envio anterior.

O produtor conserva apenas contadores e eventos tipados. Confiança é a da última detecção do objeto rastreado, nunca o score de proximidade. A classe table é enviada como table_desk. Somente avisos correlacionados à fala efetivamente solicitada pela fila e ao callback de início do TTS entram nos eventos. Avisos descartados pela fila não viram eventos. O início do TTS não comprova que a pessoa ouviu a mensagem. Volume, saída de áudio e validação física continuam questões distintas.

Latência TTS usa o timestamp do frame e o callback real de início da fala. Somas/contagens inteiras são operacionais, sem promessa de p95, acurácia ou validação do protocolo físico. O recorder de calibração permanece separado e inerte fora dos builds explicitamente habilitados.

## Fila e identidade

Sessões encerradas são imutáveis. UUID v4 aleatório de sessão, instalação e evento; nenhum identificador de hardware. A instalação é renovada ao revogar consentimento. Confiança arredondada uma única vez a seis casas; datas UTC em milissegundos. Tokens, senha, email, texto da fala, mídia, bounding boxes e localização não entram na fila.

SharedPreferences usa chave versionada account.scan-metadata.v1, com executor serial para leitura/modificação/gravação. Até 20 sessões, sem expulsar as anteriores. Ao atingir capacidade, a coleta de novos metadados pausa e a assistência continua. Revogação e saída explícita limpam os pendentes deste aparelho. Outra conta não recebe pendentes anteriores: novo consentimento nessa conta apaga a fila anterior, como informado no diálogo. Expiração da autenticação preserva os pendentes; reautenticação da mesma conta permite retomada.

Dados locais corrompidos não são ignorados silenciosamente. Falha de gravação mantém o segmento em memória e indica coleta pausada; retry tenta persistir novamente. Dados ainda não persistidos podem se perder ao fechar/matar o app. Segmentos ativos são mantidos em memória até encerramento; encerramento abrupto do processo também pode perder esse segmento. A tela não os apresenta como salvos. A fila fechada e persistida sobrevive à reinicialização.

A API retém dados por 30 × 24h desde o início. A fila local não é enviada após esse prazo; o app indica bloqueio e conserva o registro até exclusão local explícita, sem alegar entrega. Pendentes locais não são um histórico remoto sincronizado.

## Envio e recibos

1. POST /api/v1/scan-sessions com versão, consentimento, modelo e IDs persistidos.
2. Validar identidade, início, modelo, versão e expiração do recibo.
3. POST eventos em lotes de até 50. Confirmar sessionId e storedEvents.
4. POST finish depois de todos os lotes. Validar identidade, fim e cada contador.
5. Somente então remover a sessão da fila.

Uma tentativa incompleta repete início/lotes/fechamento com os mesmos IDs e valores. Isso também reconcilia uma resposta perdida depois de o servidor confirmar a transação. O cliente nunca troca o proprietário no retry.

Falhas de rede, 408, 429 e 5xx: até quatro retries automáticos, após 30s, 1min, 2min e 5min. Uma tentativa inicial mais quatro retries; depois aguarda ação explícita. Não é sondagem contínua de conectividade. Não se envia automaticamente apenas por abrir a conta/app: pendentes são enviados após uma varredura ou por ação explícita de tentar novamente/reautenticar.

401 pausa e preserva a fila. A autenticação só é expirada se o token da falha ainda for o da conta atual. 409 indica indisponibilidade/coleta desligada/quota/conflito, sem retry automático. Demais recusas/recibos inválidos preservam a fila e indicam bloqueio. O endpoint de produção placeholder mantém o envio indisponível.

## Revogação e exclusão

Revogação impede nova coleta e novos lotes, cancela timers, aguarda a tentativa em andamento e grava desativação antes de limpar a fila. O gateway drena a requisição HTTP já emitida, com timeout, em vez de considerar o fechamento do socket como confirmação de rollback no servidor. O próximo lote não é emitido depois de cancelamento.

Excluir histórico exige confirmação na UI, desativa o envio/limpa pendentes locais e depois solicita DELETE da conta capturada. Só uma resposta 204 é apresentada como exclusão confirmada. Se falhar, a tela conserva estado de erro e permite nova solicitação explícita; a limpeza local não é prova de exclusão remota.

A API v1 não mantém um registro global de revogação. Outro cliente consentido ainda pode criar novos dados. Uma falha de rede sem recibo não comprova que uma transação no servidor deixou de ocorrer. Não se promete exclusão global ou de backups. A revogação deste aparelho e a exclusão da conta no servidor são operações diferentes.

## UI, desempenho e logs

Controles de envio ficam junto ao consentimento na conta, seguindo tokens/componentes existentes. Banners com liveRegion, contador de pendências, tentativa manual e exclusão explícita. UI informa indisponibilidade, autenticação, fila cheia, falha de armazenamento e ausência de confirmação. Texto e confirmação descrevem vínculo à conta e retenção.

Observação de frames/avisos é síncrona e pequena: não serializa imagens nem aguarda armazenamento/HTTP. Persistência ocorre no encerramento do segmento, de forma assíncrona. Apenas uma tentativa de upload ativa. Não altera toolchains, dependências ou gates.

Logs de HTTP ocultam o ID na rota de metadados; não registram body nem Authorization. Erro genérico não imprime exceção/response.data com material sensível.

## Verificação reproduzível

```powershell
./scripts/check-toolchain.ps1
flutter gen-l10n
dart format --output=none --set-exit-if-changed .
flutter analyze
dart run tool/validate_design_tokens.dart
flutter test --coverage
flutter build apk --debug --flavor dev --target lib/main_dev.dart
```

Prova HTTP opt-in, exclusivamente com API local 127.0.0.1:18080 e Mailpit local 127.0.0.1:8025, coleta habilitada no ambiente de teste e credenciais locais existentes:

```powershell
dart run tool/verify_scan_metadata_api.dart CAMINHO_ENV_LOCAL CAMINHO_RELATORIO_JSON
```

Usa o gateway Dart real do app, cria duas contas sintéticas por convite local, envia 51 + 1 eventos, reenvia a primeira sessão, verifica agregados/idempotência/ownership, exclui apenas os metadados dessas contas e confirma preservação do outro proprietário. Contas e mensagens de teste permanecem no ambiente local; não remove contas/dados preexistentes. Relatório omite tokens, senhas e emails. Payloads e métricas são sintéticos.

O teste HTTP não executa o app em aparelho, câmera, TTS, TalkBack ou modo avião. Essas evidências, a integração conjunta e a confirmação humana ficam na REN-73/DoD da REN-75. REN-71 segue adiada.
