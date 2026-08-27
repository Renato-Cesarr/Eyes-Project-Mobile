# ADR 0007 — Feedback multimodal determinístico e acessível

- Status: aceito para o MVP
- Data: 2026-08-27
- Aparelho de referência: POCO X5 Pro

## Contexto

O alerta é a saída principal do Eyes. Ele precisa chegar com baixa latência,
sem depender de rede e sem competir com o TalkBack. Fala excessiva, mensagens
instáveis ou vibrações impossíveis de desativar prejudicam justamente quem
depende desses canais.

## Decisão

1. `flutter_tts` usa o mecanismo TTS instalado no Android, em `pt-BR`;
2. templates locais e determinísticos combinam classe, faixa relativa e
   direção aproximada (`esquerda`, `frente`, `direita`); LLM e áudio espacial
   ficam fora do MVP;
3. a fila mantém até quatro alertas, deduplica frases e permite que
   `MUITO_PRÓXIMO` interrompa fala informativa;
4. o motor de proximidade continua responsável pela estabilização temporal e
   pelo cooldown de segurança; a fila aplica uma segunda proteção curta contra
   duplicação de saída;
5. alertas críticos usam duas vibrações curtas, sempre redundantes à fala;
6. desativar vibração vale para alertas e confirmações não essenciais;
7. a região visual do alerta permanece na árvore semântica, mas não é uma
   `liveRegion`, evitando que TalkBack e TTS anunciem simultaneamente;
8. preferências não sensíveis ficam em `SharedPreferencesAsync`. Imagens,
   detecções e histórico de fala não são persistidos;
9. os presets alteram persistência e intervalos do anúncio, nunca o limiar de
   confiança do modelo.

## Presets iniciais

| Preset | Persistência inicial | Intervalo global | Cooldown do mesmo alerta |
| --- | ---: | ---: | ---: |
| Conservador | 2 frames | 1,5 s | 4 s |
| Equilibrado | 3 frames | 2 s | 6 s |
| Menos alertas | 4 frames | 3 s | 10 s |

Esses valores são baselines de UX. A REN-37 deve validá-los no aparelho e no
cenário de referência antes da avaliação com usuários.

## Consequências

- o caminho câmera → IA → proximidade → fala continua totalmente offline;
- a aplicação e o domínio não dependem do plugin TTS nem das APIs hápticas;
- falhas de voz ou vibração são sanitizadas e não encerram o aplicativo;
- pausar, sair da câmera ou ir para segundo plano interrompe a fila;
- velocidade, volume, detalhe, frequência e vibração são configuráveis sem
  revelar thresholds técnicos;
- a validação manual ainda deve observar interrupções do TalkBack e fadiga
  auditiva no POCO X5 Pro.
