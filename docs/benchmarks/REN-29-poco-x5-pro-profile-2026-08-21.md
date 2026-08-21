# REN-29 — Benchmark físico no POCO X5 Pro

## Objetivo

Validar, em hardware real, a inferência local do EfficientDet-Lite0 integrada ao aplicativo Flutter. A execução foi feita sem rede e sem envio de imagens para serviços externos.

## Ambiente

- Dispositivo: Xiaomi POCO X5 Pro 5G (`22101320G`, codinome `redwood`)
- Android: 14 (API 34)
- Build: flavor `dev`, modo Flutter Profile
- Modelo: EfficientDet-Lite0 quantizado, executado com LiteRT/TFLite e quatro threads de CPU
- Entrada: stream CameraX a 12 quadros por segundo
- Data: 21 de agosto de 2026

## Metodologia

1. Descartar 30 inferências de aquecimento.
2. Medir 300 ciclos consecutivos para o resultado formal.
3. Manter a câmera e a inferência ativas até 2.040 amostras para observar estabilidade.
4. Acompanhar PSS/RSS, temperatura da bateria, estado térmico, ANRs e exceções fatais.
5. Ativar o TalkBack no aparelho e inspecionar a árvore semântica exposta pelo aplicativo.

As métricas foram coletadas em modo Profile. Builds Debug não foram usados na medição.

## Resultado formal — 300 amostras

| Métrica | Média |
| --- | ---: |
| Pré-processamento | 29,41 ms |
| Inferência TFLite | 64,16 ms |
| Pós-processamento | 0,04 ms |
| Pipeline de visão | 93,61 ms |
| Ciclo ponta a ponta | 94,51 ms |
| Maior ciclo ponta a ponta | 205,37 ms |

## Estabilidade — 2.040 amostras

| Métrica | Resultado |
| --- | ---: |
| Pré-processamento médio | 30,15 ms |
| Inferência média | 59,49 ms |
| Pipeline médio | 89,68 ms |
| Ciclo ponta a ponta médio | 90,52 ms |
| PSS observado | 244.914–262.437 KB |
| PSS final | 254.085 KB |
| Temperatura da bateria | 37–38 °C |
| Estado térmico Android | 0 — sem throttling |
| ANR/exceção fatal | Nenhum |

Não houve crescimento monotônico de memória. A oscilação de PSS foi compatível com ciclos normais do coletor de lixo.

## Acessibilidade no aparelho

Com o TalkBack ativo, a tela expôs apenas conteúdo orientado ao usuário:

- “Câmera e varredura”;
- explicação de privacidade do processamento;
- “Estado da varredura: Câmera pronta. Varredura assistiva ativa.”;
- ações “Pausar câmera” e “Encerrar câmera”.

A árvore semântica não expôs FPS, milissegundos, thresholds, tensores ou outros dados técnicos. O serviço de vibração registrou o feedback háptico no fluxo de inicialização. A avaliação automatizada confirma a integração técnica; a compreensão do áudio e o conforto do padrão háptico ainda devem passar por teste de aceitação com pessoas do público-alvo.

## Incidente encontrado e corrigido

O primeiro build físico revelou que o `AssetBundle` do Flutter não podia carregar o manifesto dentro do isolate de visão. O carregamento e a validação dos assets passaram a ocorrer no isolate raiz, e os bytes do modelo são transferidos ao worker com `TransferableTypedData`. Depois da correção, o modelo inicializou normalmente e concluiu todo o benchmark.

## Conclusão

O fluxo câmera → pré-processamento → EfficientDet-Lite0 → detecções opera integralmente offline no POCO X5 Pro, sem bloquear a interface, sem falhas de estabilidade e com latência média ponta a ponta inferior a 100 ms no ensaio formal.
