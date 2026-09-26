# ADR 0014: design system mobile acessível e alinhado entre plataformas

- **Status:** aceito
- **Data:** 2026-09-26
- **Card:** REN-51

## Contexto

O MVP já possuía telas funcionais, mas estilos e componentes eram definidos em
cada feature. Essa dispersão aumentava o risco de inconsistência entre Mobile e
Web, contraste inadequado, alvos de toque pequenos e árvores semânticas
duplicadas. O produto precisa manter identidade visual própria sem sacrificar a
operação por pessoas cegas ou com baixa visão.

## Decisão

1. O Mobile adota os tokens canônicos publicados pelo design system do projeto:
   cores, espaçamento, raios, movimento e tipografia têm uma única definição.
2. São suportados quatro temas Material 3: claro, escuro, alto contraste claro e
   alto contraste escuro. Texto principal busca contraste mínimo de 7:1; nenhum
   significado depende somente de cor.
3. Títulos usam Lexend e textos de leitura usam Atkinson Hyperlegible. As fontes
   e licenças OFL são empacotadas no aplicativo e não dependem de rede.
4. Componentes compartilhados ficam em `lib/core/design_system`. Features podem
   compor esses elementos, mas não devem duplicar primitivas de botão, cartão,
   banner, estado de página ou diálogo sem uma justificativa específica.
5. Os componentes preservam escala de texto, alvos mínimos de 48 dp, ordem
   semântica previsível, ações nomeadas e regiões `live` somente para mudanças
   relevantes. Conteúdo técnico e decorativo não entra no TalkBack.
6. Movimento respeita `disableAnimations`; animações não são necessárias para
   compreender ou concluir tarefas.
7. A galeria `/design-system` existe somente no flavor de desenvolvimento. O
   flavor de produção não registra essa rota.
8. A biblioteca é interna ao aplicativo neste MVP. Não será extraído um pacote
   Flutter antes de existir um segundo consumidor real.

## Consequências

- Novas telas reutilizam decisões já verificadas de identidade e acessibilidade.
- Alterações de marca ou contraste são feitas nos tokens, sem varrer features.
- Testes de widget protegem semântica, escala de 200%, temas e alvos de toque.
- A Web e o Mobile compartilham linguagem visual, mas usam componentes nativos
  às respectivas plataformas em vez de uma dependência de UI cruzada.
- Exceções visuais precisam ser justificadas durante a revisão e não podem
  reduzir os requisitos de acessibilidade.
