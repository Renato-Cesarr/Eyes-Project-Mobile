# Arquitetura Mobile

## Objetivo

Manter o núcleo do aplicativo testável e independente das escolhas de UI,
armazenamento e integração, sem introduzir abstrações que não protejam uma
fronteira real.

## Dependências permitidas

```text
presentation → application → domain
      │              │
      └──── infrastructure (por interfaces/providers) ────┘
```

- `domain` contém regras e modelos puros e não importa Flutter, Dio ou Riverpod;
- `application` coordena casos de uso e estado por `AsyncNotifier`;
- `presentation` traduz estado em widgets e semântica acessível;
- `infrastructure` implementa fronteiras externas;
- `core` possui capacidades transversais, sem regras específicas de feature;
- providers Riverpod são a composition root e substituem um segundo contêiner
  de injeção.

## Estado e erros

`AsyncValue` representa carregamento, sucesso e falha. Exceções técnicas são
mapeadas para `AppException` antes de alcançarem a apresentação. Erros não
tratados passam por `AppErrorReporter`, que registra somente tipo, origem e
stack trace, sem conteúdo pessoal.

## Rede e persistência

O cliente Dio não registra headers, bodies ou parâmetros de consulta. Tokens
devem permanecer em `flutter_secure_storage`; `shared_preferences` fica restrito
a preferências não sensíveis, como escolhas de feedback ou interface.

## Acessibilidade como requisito transversal

A árvore semântica é a fonte primária do TalkBack. Mudanças importantes de
estado aparecem em regiões `live`, evitando anúncios imperativos que interrompam
a fila de fala do Android. Vibração e som são fornecidos por uma interface
substituível, permitindo preferências futuras e testes determinísticos.

## Critério para criar um repository

Crie uma interface de repository somente quando existir pelo menos uma dessas
fronteiras:

1. API remota;
2. banco ou armazenamento local;
3. câmera ou sensor;
4. runtime/modelo de visão computacional;
5. necessidade comprovada de alternar implementações.

Não crie repositories para transformar ou repassar dados dentro da memória.

## Pipeline da câmera

`CameraGateway` é a porta da aplicação para permissão, inicialização, stream e
liberação de hardware. `MobileCameraGateway` concentra `camera` e
`permission_handler`; nenhum tipo desses plugins atravessa para o domínio.

```text
CameraDiagnosticsPage
        ↓ observa
ScanController (AsyncNotifier<CameraSessionState>)
        ↓ depende de
CameraGateway ← MobileCameraGateway ← câmera Android
        ↓ entrega
CameraFrameHandler ← inferência TFLite no REN-29
```

Os estados `idle`, `requestingPermission`, `preparing`, `streaming`, `paused`,
`denied`, `permanentlyDenied`, `busy` e `unavailable` são explícitos. A UI
traduz esses estados em texto e região semântica `live`; o adapter nativo não
abre diálogos nem produz mensagens visuais.

O `LatestFrameProcessor` limita o processamento e mantém somente a imagem mais
recente enquanto existe trabalho em voo. Sua telemetria agrega frames recebidos,
processados, descartados, FPS e duração do processamento sem registrar pixels.

## Pipeline de visão computacional

O `VisionWorker` é uma porta da aplicação. Sua implementação mantém um isolate
de longa duração que possui, com exclusividade, o interpretador TFLite. O modelo,
o manifesto, o pré-processamento e os tensores permanecem na infraestrutura;
somente `DetectionBatch` retorna à aplicação e ao domínio.

```text
CameraFrame (root isolate)
        ↓ adaptação REN-29 / Fase 4
VisionFrame
        ↓ TransferableTypedData
VisionWorker isolate
        ├── verifica manifesto + SHA-256
        ├── converte NV21/YUV420 → RGB 320×320
        ├── executa EfficientDet-Lite0
        └── devolve DetectionBatch
        ↓
VisionController (AsyncNotifier: loading / ready / error)
```

A criação do `TransferableTypedData` materializa um buffer transferível e custa
tempo proporcional ao frame; seu envio entre isolates é constante e não cria
uma segunda cópia. Apenas uma inferência fica em voo. O descarte de frames
antigos continua sendo responsabilidade do `LatestFrameProcessor`.

No background ou ao fechar a sessão, o comando de encerramento aguarda o
`close()` do detector antes de confirmar o `dispose`. Timeouts ou quedas do
isolate invalidam a sessão inteira; um `start()` posterior sempre cria runtime
e interpretador novos.

## Proximidade e priorização

O `ProximityEngine` recebe somente `DetectionBatch` e não conhece câmera,
TFLite, Riverpod ou widgets. Ele mantém tracks temporais por classe e IoU,
suaviza o sinal por EMA e aplica histerese antes de produzir uma faixa relativa.

```text
DetectionBatch
      ↓
ProximityEngine (IoU → EMA → histerese → persistência)
      ↓
ProximityEvaluation (DISTANTE / ATENÇÃO / MUITO_PRÓXIMO)
      ↓
prioridade + cooldown + deduplicação
      ↓
ProximityAlertEvent (sem imagem)
      ↓
ProximityController (Riverpod)
```

O score combina área normalizada da caixa e posição da borda inferior com
calibração por classe. Ele não representa metros. Os parâmetros em
`ProximityPolicy` são um baseline versionado que deverá ser calibrado na
REN-37. Pausar, encerrar ou enviar o aplicativo ao background limpa todos os
tracks e cooldowns para impedir que eventos de uma sessão vazem para outra.

Somente eventos que passaram pela estabilização chegam à saída assistiva e ao
cartão semântico. Detecções brutas e telemetria continuam fora do TalkBack.

## Feedback assistivo e preferências

O evento estabilizado ganha apenas uma direção relativa derivada do centro da
caixa; coordenadas e pixels continuam fora da saída. O binding de aplicação
conecta Riverpod sem acoplar os domínios:

```text
ProximityAlertEvent
        ↓
AssistiveAlertMessageComposer (template pt-BR determinístico)
        ↓
VoiceAlertQueue (prioridade, preempção, deduplicação, backlog limitado)
        ├── SpeechGateway ← FlutterTtsSpeechGateway
        └── AssistiveHaptics ← APIs nativas do Flutter
```

`FeedbackPreferencesRepository` persiste somente velocidade, volume, detalhe,
frequência de anúncios e vibração. Os presets são traduzidos em
`ProximityPolicy` por um controller de aplicação; nenhum parâmetro do tensor ou
confidence threshold é exposto.

TalkBack continua podendo explorar o cartão visual do último alerta, mas esse
cartão não é uma `liveRegion`: a fala do produto é responsabilidade da fila TTS
e não deve ser duplicada pelo leitor de tela. Estados operacionais e erros
continuam em regiões `live`.
