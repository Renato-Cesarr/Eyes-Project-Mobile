# ADR 0006 — Proximidade relativa e priorização determinística

- Status: aceito como baseline do MVP
- Data: 2026-08-21
- Validação experimental: pendente na REN-37

## Contexto

Uma caixa delimitadora monocular não fornece distância métrica confiável. Anunciar metros ou centímetros criaria uma precisão inexistente e poderia transmitir falsa segurança. Ao mesmo tempo, detecções quadro a quadro oscilam e não podem gerar fala imediatamente.

## Decisão

O MVP comunica três faixas relativas: `DISTANTE`, `ATENÇÃO` e `MUITO_PRÓXIMO`. O motor é local, puro e determinístico:

1. associa caixas da mesma classe entre frames por IoU;
2. calcula um sinal relativo com 70% de área linear normalizada e 30% da posição da borda inferior;
3. aplica média móvel exponencial, histerese e confirmação temporal;
4. prioriza faixa, risco da classe, centralidade e persistência;
5. emite no máximo um evento por frame, com cooldown por classe/faixa;
6. permite que um evento `MUITO_PRÓXIMO` preempte um alerta `ATENÇÃO`;
7. registra em memória somente o evento anunciado, sem pixels ou imagens.

Parâmetros baseline:

| Parâmetro | Valor inicial |
| --- | ---: |
| IoU mínimo | 0,25 |
| EMA alpha | 0,35 |
| Entrada em atenção | 0,55 |
| Entrada em muito próximo | 0,78 |
| Histerese | ±0,05 |
| Confirmação de novo objeto | 3 frames |
| Confirmação de mudança | 2 frames |
| Cooldown do mesmo alerta | 6 s |
| Intervalo global | 2 s |

Os valores de referência por classe e pesos de risco são versionados em `ProximityPolicy`. Eles são hipóteses iniciais, não resultados científicos.

## Consequências

- a mesma sequência temporal sempre produz os mesmos eventos;
- um único frame nunca gera alerta;
- o caminho crítico continua offline e explicável para o TCC;
- não há promessa de distância métrica;
- mudanças bruscas com IoU insuficiente criam um novo track e precisam ser estabilizadas novamente;
- a REN-37 deve calibrar thresholds e referências no POCO X5 Pro antes de testes com usuários;
- a REN-31 troca `announceAttention`, persistência e cooldown por presets sem alterar o detector.
