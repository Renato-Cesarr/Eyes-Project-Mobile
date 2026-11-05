# ADR 0020 — Diagnóstico local voluntário sem USB

- Data: 05/11/2026
- Status: aceito para implementação; homologação Android pendente
- Card: REN-78, apoio à REN-32

## Contexto

Uma integrante precisa testar com Android e sem computador. O ADR 0012 exige ADB,
cenário rotulado e APK debuggable. Seus guards não serão alterados para Release.

## Decisão

Diagnóstico de suporte separado, somente dev. O usuário lê o resumo, marca sua
escolha e inicia. Assistência offline, sem conta ou envio automático. Controles
usam Orbit e localização pt-BR. Não criar biblioteca paralela ou dependência nova.

O recorder recebe entidades existentes, sem frames/tensores. Mantém contagens de
frames/classes/alertas, 100 eventos recentes, 512 amostras por marco temporal e 16
correlações de fala pendentes. Mensagens TTS ficam somente na correlação em memória.
Problemas globais emitem evento fixo, sem texto nativo, stack trace, token ou URL.
Tempos negativos são descartados, sem transformá-los em resultados favoráveis.

Salvar última sessão a cada cinco segundos e ao encerrar, AtomicFile em Android
noBackupFilesDir, até 100.000 bytes. Excluir vencidos na próxima abertura/consulta
após sete dias. Não há serviço ou agendamento com app fechado. Uma interrupção é
identificada no relatório, sem retomar coleta automaticamente. Falha de gravação
encerra diagnóstico, preservando assistência.

Compartilhamento explícito via JSON em subdiretório restrito de cache, FileProvider
não exportado e concessão de leitura. Destinatário escolhido no Android. Abrir
seletor não confirma entrega. Adicionar apenas fabricante/modelo, versão Android
e identidade do app; sem identificadores únicos/lista de aplicativos. Apagar local
não revoga cópias enviadas. Prod não expõe rota e rejeita operações nativas.

Build demonstrável injeta HEAD em EYES_BUILD_COMMIT, mantendo recibo de proveniência.
Sem define, declara unidentified. Pacote atual inclui Orbit ainda em PR, identificado
explicitamente na entrega. Não confundir APK candidato com dev integrada.

## Limites e verificação

Não é corpus, calibração, teste com pessoa cega ou avaliação científica. Não mede
acurácia, FPS, memória, bateria ou temperatura. Estatísticas das últimas amostras
incluem custo da instrumentação. Callback TTS não prova som audível ou vibração.
Process kill pode perder cinco segundos; crashes nativos/ANRs/OOM não têm captura
completa. Horários dependem do relógio do aparelho. Relato manual é evidência
separada; REN-32/37/77 não encerram com um JSON exportado.

Testar opt-in, limites, estatísticas, conteúdo permitido, restauração, expiração,
falhas de persistência/exportação e interface em 320 px/texto 200%. Build Android
confirma compilação; envio por outro aplicativo exige prova física real.
