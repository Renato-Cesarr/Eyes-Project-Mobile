# ADR 0012 — Telemetria opt-in para calibração assistiva

- Status: aceito
- Data: 2026-09-11
- Issue: REN-37

## Contexto

A calibração precisa correlacionar câmera, inferência, decisão e início do TTS,
mas a aplicação normal não deve registrar cenas nem expor métricas técnicas ao
usuário ou ao TalkBack. Medir somente a duração da chamada de inferência não
representa a latência percebida.

## Decisão

Introduzir um recorder inerte por padrão. Ele só é ativado quando duas
condições independentes são verdadeiras:

1. o APK foi compilado com `--dart-define=EYES_CALIBRATION=true`;
2. o avaliador iniciou o app por ADB com metadados estruturados de um cenário.

O recorder recebe somente `DetectionBatch`, `ProximityEvaluation`, eventos de
alerta e o callback nativo de início do `flutter_tts`. Ele emite JSON Lines com
classes, faixas, caixas normalizadas e durações. Frames, pixels, áudio, nomes,
tokens e mensagens de erro nativas são proibidos.

Os metadados de ground truth usam enumerações fechadas e identificadores sem
texto livre. O código de produção não consulta o canal nativo quando o define
de calibração está ausente. Nenhuma métrica entra na árvore semântica ou na UI.

## Consequências

- a latência câmera → início do TTS pode ser medida em Profile no aparelho;
- uma mesma coleta alimenta matriz de confusão e relatório reproduzível;
- o APK comum permanece sem telemetria de calibração;
- o operador precisa seguir o protocolo e rotular corretamente cada cenário;
- logs de calibração são artefatos locais temporários e não devem ser
  versionados, enquanto relatórios agregados e configurações podem ser
  publicados.
