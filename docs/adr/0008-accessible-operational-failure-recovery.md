# ADR 0008 — Falhas operacionais e recuperação acessível

- Status: aceito
- Data: 2026-08-28
- Issue: REN-43

## Contexto

O pipeline assistivo depende de câmera, modelo TFLite e saídas multimodais. Uma
falha não pode deixar o usuário em silêncio, manter carregamento indefinido nem
apresentar a varredura como ativa quando câmera ou modelo estão indisponíveis.
Mensagens nativas também não são apropriadas para a interface e podem carregar
detalhes técnicos ou dados inadequados para logs.

## Decisão

Adotar uma taxonomia estável de `OperationalFailure` antes da camada de
apresentação. A taxonomia separa:

- impacto `blocking`, que impede a varredura assistiva;
- impacto `degraded`, no qual o processamento local continua com uma capacidade
  explicitamente indisponível;
- ação primária de recuperação e saída secundária segura;
- código diagnóstico opcional, que nunca é renderizado nem anunciado.

`ScanFailurePolicy` traduz falhas de câmera, runtime TFLite e feedback. A UI usa
um único `AccessibleRecoveryPanel`, com resumo em região semântica viva, foco
inicial previsível, ação primária e alternativa em ordem lógica. A chave da
falha controla novas solicitações de foco e evita anunciar novamente a mesma
ocorrência a cada frame ou rebuild.

Os timeouts permanecem nas fronteiras proprietárias dos recursos:

- câmera: 12 segundos;
- inicialização do worker/modelo: 20 segundos;
- inferência: 5 segundos;
- encerramento do worker: 3 segundos.

Retry de câmera e modelo é explícito e recria recursos nativos de forma
controlada. Backoff automático fica reservado para rede; indisponibilidade da
API ou sessão remota nunca bloqueia a futura varredura offline.

Falhas de TTS, vibração e preferências são degradáveis. O usuário recebe texto,
semântica e acesso às configurações, mas o detector local não é encerrado. A
taxonomia já reserva categorias de autenticação, sincronização, bateria e
pressão térmica; seus adapters serão conectados quando essas capacidades forem
implementadas e medidas no aparelho de referência.

## Segurança e observabilidade

O `AppErrorReporter` recebe somente tipo, origem e código diagnóstico
sanitizado. Mensagens de exceção, tokens, imagens, bytes de frames, tensores e
descrições de fabricante não entram no contexto estruturado.

## Consequências

- A apresentação não conhece exceções de plugin nem códigos TFLite.
- Erros críticos deixam claro que a varredura está desligada.
- Todo fluxo bloqueador oferece recuperação ou retorno seguro.
- Novas integrações devem mapear suas falhas para a taxonomia, sem criar textos
  técnicos ad hoc em widgets.
- Detecção de bateria e temperatura depende de adapter nativo e de limiares que
  serão calibrados na REN-37; não inferiremos risco sem dados do aparelho.
