# ADR 0016: navegação auxiliar acessível e aparência persistida

- **Status:** aceito
- **Data:** 2026-09-27
- **Card:** REN-56

## Contexto

O fluxo principal de varredura já era camera-first e offline, mas onboarding,
início, conta, ajuda e configurações ainda combinavam componentes Material
diretos com o design system. Isso gerava diferenças de hierarquia, espaçamento,
recuperação e semântica. Os quatro temas acessíveis também existiam apenas como
resposta à configuração do sistema, sem escolha explícita dentro do aplicativo.

## Decisão

1. Telas auxiliares usam `EyesPageScaffold`, `EyesPageHeader`, `EyesSection`,
   `EyesButton`, `EyesCard`, `EyesStatusBanner` e `EyesStateView` como primitivas
   visuais e semânticas compartilhadas.
2. Conteúdo finito dessas telas é construído integralmente dentro de uma única
   região rolável. Isso mantém ações localizáveis pelo TalkBack antes da rolagem,
   preserva a ordem de foco e evita regiões de rolagem aninhadas.
3. A tela inicial mantém a varredura como única ação primária. Configurações,
   ajuda e conta opcional são agrupadas como ações de suporte e nunca bloqueiam
   o funcionamento local.
4. O onboarding continua contextual: explica segurança e privacidade, permite
   testar voz e vibração e solicita a câmera somente na etapa final. Negar a
   permissão não aprisiona o usuário.
5. Conta e sincronização permanecem opcionais. Falhas remotas oferecem sempre
   uma saída explícita para a varredura offline e não invalidam recursos locais.
6. A preferência de aparência passa a ser uma feature isolada, controlada por
   Riverpod e persistida em `SharedPreferences` com chave versionada. As opções
   são sistema, claro, escuro, alto contraste claro e alto contraste escuro.
7. Falha ao carregar aparência usa o tema do sistema; falha ao salvar mantém a
   escolha anterior e apresenta uma mensagem recuperável, sem comprometer o app.
8. Textos descrevem efeitos para a pessoa usuária e não expõem termos internos,
   nomes de tensores, métricas ou detalhes da arquitetura ao TalkBack.

## Consequências

- A navegação auxiliar compartilha identidade e comportamento previsíveis.
- Contraste pode ser escolhido sem depender das configurações globais do Android.
- O estado visual continua local, não sensível e independente de autenticação.
- Testes cobrem persistência, falha segura, semântica, foco e fonte a 200%.
- A REN-58 pode validar regressões visuais sobre uma fundação estável.
