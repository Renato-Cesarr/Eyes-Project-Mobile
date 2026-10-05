# REN-37 — Execução pelo protocolo unificado

A REN-68 consolida as decisões anteriores no contrato `config/assistive-evaluation.v1.json`, cópia normalizada LF da fonte IA. [Protocolo completo](https://github.com/Renato-Cesarr/Eyes-Project-AI/blob/feat/REN-68-unified-evaluation/docs/assistive-evaluation-protocol.md). Conferir o SHA-256 do contrato e do APK antes da coleta.

## Preparar e congelar
1. Usar Profile/dev opt-in com `EYES_CALIBRATION=true`; Release/produção permanece protegida. O APK visual da REN-67 tem calibração desabilitada e não serve para coleta.
2. Registrar identidade limpa do build (commit/APK/modelo/política), configuração real, aparelho/Android/RAM/fingerprint digest, versão, bateria e estado térmico.
3. Manter processamento offline; telemetria não guarda frames/imagens/vídeo/áudio/nome/texto livre.
4. Separar montagens, exemplares, sessões e ordem de calibração/avaliação; manter registro de sala/sessão/split pseudônimo. Referências 0,50/1,00/2,00 m são somente do ensaio, nunca promessa de distância do produto.
5. Usar quatro classes, três faixas, clara/reduzida, sem/parcial oclusão: 48 segmentos de calibração, 24 novos de avaliação e ≥6 negativos. Contraluz complementa cobertura. Cada janela medida tem 20 s após ≥5 s e ≥30 frames reais de aquecimento. Corpus de detecção continua com ≥30 sessões e ≥30 instâncias de teste por classe; segmentos não o substituem.

## Coletar
Exemplo de metadados de cenário:
```powershell
./scripts/calibration/Start-Ren37Calibration.ps1 -SessionId ren37-cal-001 -ScenarioId chair-attention-bright-clear-01 -DatasetSplit calibration -ExpectedKind chair -ExpectedBand attention -Lighting bright -Occlusion none
./scripts/calibration/Stop-Ren37Calibration.ps1 -SessionId ren37-cal-001
```
Reutilizar o APK com `-SkipBuild` somente quando o recibo/bytes permanecem iguais. Não mudar parâmetros depois de ver o teste. O início de instrumentação não é automaticamente o começo da janela medida: anotar início operacional e timestamps de medição/aquecimento.

## Validar entradas e gerar
Copiar [modelo de manifesto](report-manifest.example.json) para um arquivo local e preencher somente identidades/timestamps/hashes reais. Valores nulos do exemplo são deliberadamente inválidos; não substituir por valores fictícios para passar. Por fonte, declarar JSONL e metadados físicos `.device.json`/identidade com basename/SHA-256, sessão/cenário, início operacional e janela medida. O manifesto tem uma finalidade e um split, APK/modelo/política/configuração congelados.

```text
dart run tool/calibration_report.dart --input artifacts/calibration/calibration-only --output docs/benchmarks/calibration-result.md --manifest artifacts/calibration/calibration-manifest.json
```

O gerador rejeita arquivos não declarados, hashes/identidades/sessões incompatíveis, mistura calibração/avaliação, metadados variáveis numa sessão, pares TTS duplicados/órfãos, relógios invertidos e aquecimento insuficiente. Valida antes de escrever; não modifica JSONL/sidecars originais. Fontes de mesma finalidade/split/build podem ser agrupadas; o JSON também publica resultados por classe/faixa/luz/oclusão.

Para diagnosticar um arquivo histórico ou sintético:
```text
dart run tool/calibration_report.dart --input capture.jsonl --output pilot.md --legacy-purpose pilot
dart run tool/calibration_report.dart --input synthetic.jsonl --output fixture.md --legacy-purpose fixture
```
Legado só aceita arquivo exato, nunca pasta, e não comprova janela/aquecimento/build. Não o rotular como avaliação final. `--device-metrics` opcional exige sessão correspondente; não misturar métricas de outro aparelho/sessão. CLI desconhecida/repetida/sem valor é rejeitada.

## Interpretar
Metas preservadas: inferência p95≤250 ms; frame→fila p95≤500 ms; frame→início TTS p95≤300 ms. Inferência requer ≥300 amostras após aquecimento; plano TTS de engenharia propõe 100 pares/configuração, a revisar/congelar antes da coleta, sem garantia de segurança. Cada métrica informa n/p50/p95/ms; percentil por interpolação linear. Deltas UTC continuam diagnósticos até conferir relógios monotônicos ponta a ponta.

A origem operacional do primeiro alerta é o primeiro frame medido; abertura da sessão tem série separada. Sem marco válido, informar indisponível. Taxa de perigo perdido e falso alerta por frame não equivalem a eventos anotados perdidos ou falsos alertas/minuto. Não escolher parâmetros com o conjunto de avaliação.

## Estabilidade e aceite
Executar **20 min medidos**, substituindo a previsão anterior de 15 min. Registrar memória, térmica, fila, ANR/fatal, bateria/temperatura inicial/final e estado de carregamento. Consumo exige desconexão documentada; estado de bateria carregando não comprova autonomia.

Relatório é descritivo: não declara automaticamente gate final, TalkBack, coleta concluída ou independência física. Aprovação final exige evidências de corpus/ensaios independentes, relógios/amostras, estabilidade e condições do build real. Originais do piloto permanecem intactos. Protocolo IA concentra decisões; este documento trata da operação e do formato mobile.
