# ADR 0003 — Acessibilidade por design

- Status: aceito
- Data: 2026-08-17

## Contexto

Pessoas cegas ou com baixa visão são o público principal. Acessibilidade não
pode ser uma correção aplicada ao final das telas.

## Decisão

Toda feature deve modelar estados anunciáveis, usar semântica nativa, respeitar
escala de fonte e contraste do sistema e fornecer feedback multimodal. Regiões
`live` serão preferidas a anúncios imperativos no Android. Feedback tátil e
sonoro fica atrás de uma interface para permitir preferências e testes.

O DoD de cada tela inclui validação manual com TalkBack, fonte ampliada, modo
escuro e alto contraste, além de widget tests para os caminhos críticos.

## Consequências

- componentes decorativos não poluem a árvore semântica;
- layout e textos são avaliados com escalas grandes desde o início;
- qualquer UI sem rótulo, hint ou ordem de foco coerente é considerada
  incompleta;
- configurações futuras poderão desativar som ou vibração sem alterar features.
