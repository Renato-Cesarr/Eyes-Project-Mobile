# REN-37 — Protocolo de calibração e avaliação ponta a ponta

## Objetivo

Calibrar e avaliar as faixas relativas `DISTANTE`, `ATENÇÃO` e
`MUITO_PRÓXIMO` no POCO X5 Pro sem atribuir precisão métrica ao produto. As
distâncias abaixo são referências exclusivas do ensaio e nunca são anunciadas
ao usuário.

## Princípios de validade

1. Usar build Flutter **Profile**, flavor `dev`, com
   `EYES_CALIBRATION=true`. Debug não é aceito para latência.
2. Manter o processamento offline e bloquear rede durante a sessão.
3. Não registrar imagens, vídeo, áudio, nomes de pessoas ou texto livre.
4. Separar fisicamente o conjunto de calibração do conjunto de avaliação:
   posições, exemplares e ordem dos cenários não podem ser idênticos.
5. Fixar o celular na altura de 1,20 m, câmera traseira em retrato e lente
   aproximadamente paralela ao chão.
6. Medir a distância entre a lente e a superfície mais próxima do alvo com
   fita métrica, apenas para marcar o cenário.

## Referências operacionais do ensaio

| Faixa esperada | Posição de referência | Interpretação no ensaio |
| --- | ---: | --- |
| `MUITO_PRÓXIMO` | 0,50 m | risco imediato de colisão |
| `ATENÇÃO` | 1,00 m | obstáculo próximo que exige atenção |
| `DISTANTE` | 2,00 m | presença sem alerta de proximidade |

Esses pontos são marcadores experimentais, não uma promessa de alcance ou de
distância estimada pelo aplicativo.

## Matriz mínima de cenários

Executar as quatro classes (`person`, `chair`, `table`, `backpack`) nas três
faixas, em iluminação clara e reduzida, sem oclusão e com oclusão parcial. Cada
segmento deve durar 20 segundos depois de 5 segundos de aquecimento.

- Calibração: 48 segmentos, usados exclusivamente para escolher parâmetros.
- Avaliação: 24 segmentos novos, cobrindo todas as classes e faixas, com uma
  combinação balanceada de iluminação e oclusão que não repita a montagem.
- Controle negativo: ao menos 6 segmentos sem obstáculo relevante próximo,
  rotulados como `distant`, para medir falsos alertas.
- Estabilidade: uma sessão contínua de 15 minutos com aproximações e
  afastamentos naturais, sem trocar o APK.

Para pessoas, usar participante informado e não reter imagens. Não incluir
rosto, nome ou identificador nos artefatos.

## Execução

Exemplo de início de um segmento:

```powershell
./scripts/calibration/Start-Ren37Calibration.ps1 `
  -SessionId ren37-cal-001 `
  -ScenarioId chair-attention-bright-clear-01 `
  -DatasetSplit calibration `
  -ExpectedKind chair `
  -ExpectedBand attention `
  -Lighting bright `
  -Occlusion none
```

Inicie a varredura no aplicativo, aguarde 5 segundos e mantenha o cenário por
20 segundos. Depois encerre a coleta:

```powershell
./scripts/calibration/Stop-Ren37Calibration.ps1 -SessionId ren37-cal-001
```

O primeiro segmento compila e instala o APK. Nos seguintes, use `-SkipBuild`
para reutilizar exatamente o mesmo artefato.

## Métricas e critérios

- Matriz de confusão entre as três faixas e `missed`.
- Taxa de frames de perigo (`ATENÇÃO`/`MUITO_PRÓXIMO`) classificados como
  `DISTANTE` ou perdidos.
- Falsos alertas nos cenários `DISTANTE`/controle negativo.
- Alertas repetidos antes do cooldown de 6 segundos.
- Tempo até o primeiro alerta.
- Latência p50/p95 de pré-processamento, inferência, decisão e câmera até o
  início real do TTS.
- Meta inicial: p95 câmera → início do TTS ≤ 300 ms.
- Na sessão de 15 minutos: bateria inicial/final, temperatura, estado térmico,
  PSS/RSS, ANRs e exceções fatais.

O relatório é gerado por:

```powershell
dart run tool/calibration_report.dart `
  --input artifacts/calibration `
  --output docs/benchmarks/REN-37-resultados.md `
  --device-metrics artifacts/calibration/ren37-cal-001.device.json
```

Quando `--input` aponta para uma pasta, o gerador agrega todos os arquivos
`.jsonl` encontrados nela. Isso permite produzir uma única matriz a partir de
segmentos separados, sem juntar arquivos manualmente.

## Política de ajuste

1. Ajustar somente com o conjunto `calibration`.
2. Alterar um grupo de parâmetros por vez e registrar a justificativa.
3. Atualizar `config/proximity-policy.v1.json` e o código juntos; o teste de
   contrato impede divergência silenciosa.
4. Congelar os parâmetros antes de executar o conjunto `evaluation`.
5. Publicar resultados abaixo da meta como limitação; não descartar amostras
   válidas para melhorar números.
