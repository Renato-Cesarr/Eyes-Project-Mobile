# ADR 0017 — Gates automatizados de UI e acessibilidade

## Status

Aceito.

## Decisão

Usar golden tests nativos do Flutter para superfícies determinísticas e manter
testes de Semantics, escala de texto e tamanho de alvos na mesma suíte bloqueante.
O CI também valida que cores literais permaneçam nos tokens, com exceção explícita
do preto e branco necessários ao contraste do preview da câmera.

As fontes utilizadas nas imagens de referência devem ser determinísticas. As
fontes do produto são carregadas dos assets e o Material Icons é mantido como
fixture de teste versionado, acompanhado da licença e sem entrar no bundle do
aplicativo. O teste não pode depender de caminhos privados do SDK Flutter.

## Consequências

Mudanças acidentais de tema, espaçamento, tipografia ou hierarquia passam a
falhar no PR. Atualizações intencionais exigem comando explícito e revisão das
imagens. Câmera e dados dinâmicos continuam cobertos por comportamento e pela
homologação manual no aparelho, não por snapshots frágeis.
