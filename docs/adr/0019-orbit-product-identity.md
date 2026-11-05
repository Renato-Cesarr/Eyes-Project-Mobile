# ADR 0019 — Identidade Orbit e reutilização da apresentação

Data: 04/11/2026. Direção aprovada pelo responsável na REN-65; implementação
mobile na REN-60. Esta decisão evolui o Design System existente, sem substituir
Riverpod, Material 3, navegação, gateways ou o modelo local.

## Contexto

O responsável aprovou a alternativa Orbit após comparar propostas web/mobile e
solicitou acabamento de produto, claro/escuro, componentes reutilizáveis e
preservação das funcionalidades. A implementação precisa respeitar escala de
texto, leitores de tela, preferência persistida e alto contraste.

## Decisão

Centralizar a paleta em `EyesColorSchemes` e as superfícies, fontes, raios e
controles em `AppTheme`. O fundo azul noturno, o azul de ação, os planos de
superfície e as bordas estruturais correspondem à direção web. Os dois temas
de alto contraste mantêm pares próprios; não são uma transparência sobre o tema
padrão. Fontes continuam empacotadas para operação offline.

Reutilizar `EyesPageScaffold`, `EyesPageHeader`, `EyesButton`, `EyesActionTile`,
`EyesCard`, `EyesSection` e os estados/banners existentes. `EyesButton` ganha
alinhamento opcional do ícone, preservando o padrão anterior e seus callbacks,
loading e Semantics. O início utiliza ícone ao final da ação principal.

`EyesOrbitEmblem` é a única assinatura orbital, usada no início e na etapa de
boas-vindas. Reutiliza `EyesBrandMark`, pinta apenas formas estáticas com tokens
e é excluída da árvore semântica. Não gira, não emite sons, não representa uma
varredura ativa. É omitida quando a escala de texto excede 150%, reservando
espaço para a tarefa. Não há imagem baixada ou dependência nova.

A aplicação da identidade às demais páginas ocorre pela composição/tema
compartilhados. Câmera, seleção USB, backpressure, isolates, tensores, política
de proximidade, voz/vibração, consentimento e sincronização não são alterados.
Os overlays de câmera preservam seus contrastes e estados operacionais reais.

## Consequências e verificação

Uma mudança comum alcança todas as features; por isso verificar a suíte completa,
Semantics, alvos de toque, contraste, larguras 320/390 e escalas 100/150/200,
além dos goldens e APK release. Referências Windows e Linux devem ser geradas em
seus motores nativos e inspecionadas, sem reduzir critérios existentes.

Goldens com serviços de teste não validam áudio físico, TalkBack real, vibração,
webcam/OTG ou performance no POCO X5 Pro. Esses aceites permanecem nos cards de
homologação, e a atualização visual não os encerra. Resultados reais da entrega
ficam no relatório ilustrado e no checkpoint; não se presume CI ou merge antes
de suas execuções.
