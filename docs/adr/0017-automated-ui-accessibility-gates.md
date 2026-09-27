# ADR 0017 — Gates automatizados de UI e acessibilidade

## Status

Aceito.

## Decisão

Usar golden tests nativos do Flutter para superfícies determinísticas e manter
testes de Semantics, escala de texto e tamanho de alvos na mesma suíte bloqueante.
O CI também valida que cores literais permaneçam nos tokens, com exceção explícita
do preto e branco necessários ao contraste do preview da câmera.

## Consequências

Mudanças acidentais de tema, espaçamento, tipografia ou hierarquia passam a
falhar no PR. Atualizações intencionais exigem comando explícito e revisão das
imagens. Câmera e dados dinâmicos continuam cobertos por comportamento e pela
homologação manual no aparelho, não por snapshots frágeis.
