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
