# Eyes Design System no Flutter

Este documento orienta o uso da biblioteca visual interna do Mobile. A fonte
canônica dos princípios e tokens compartilhados com a Web está em
`Eyes-Project-Front/docs/design-system`.

## Princípios

- acessibilidade é requisito funcional, não acabamento;
- componentes devem continuar utilizáveis com TalkBack e fonte em 200%;
- nenhum status depende apenas de cor, ícone, vibração ou animação;
- dados técnicos como FPS, tensores e latência não entram na árvore semântica;
- o fluxo assistivo continua local e offline.

## Estrutura

```text
lib/core/design_system/
├── components/   # primitivas reutilizáveis e acessíveis
├── gallery/      # catálogo disponível apenas em desenvolvimento
├── licenses/     # registro das licenças das fontes
└── tokens/       # cor, layout, movimento e semântica
```

Use o barrel `eyes_design_system.dart` nas telas. Features não devem importar
arquivos internos de tokens quando um componente público já resolve o caso.

## Componentes disponíveis

| Componente | Uso |
| --- | --- |
| `EyesActionTile` | ação secundária de navegação com título e descrição opcional |
| `EyesButton` | ações filled, outlined e text, inclusive loading |
| `EyesCard` | agrupamento visual e semântico de conteúdo relacionado |
| `EyesPageHeader` | título e descrição introdutória de página |
| `EyesPageScaffold` | página rolável, segura e com largura de leitura limitada |
| `EyesSection` | seção de conteúdo com cabeçalho semântico e espaçamento uniforme |
| `EyesStatusBanner` | informação, sucesso, alerta e erro com texto explícito |
| `EyesStateView` | loading, vazio e erro, com ação opcional preservada no TalkBack |
| `EyesConfirmationDialog` | confirmação com ação principal e cancelamento claros |
| `EyesBrandMark` | marca vetorial; decorativa por padrão e rotulável quando necessário |

## Temas e tipografia

`AppTheme` oferece `light`, `dark`, `highContrastLight` e
`highContrastDark`. A pessoa usuária pode seguir o tema do aparelho ou escolher
explicitamente uma dessas opções em **Configurações de áudio e alertas >
Aparência e contraste**. A preferência fica somente no aparelho e uma falha de
persistência mantém o tema anterior. Lexend é reservada a títulos e Atkinson Hyperlegible aos textos de
leitura. Os arquivos são locais e suas origens e hashes estão registrados em
`docs/design-system-font-sources.md`.

Não limite `TextScaler` em páginas de produto. Prefira layout rolável, `Wrap`,
`Expanded` e largura máxima de leitura. O mínimo de 48 dp é uma barreira de
segurança; ações principais devem manter o alvo maior quando o contexto permitir.

## Semântica

- dê a cada ação um rótulo que explique o resultado;
- use hint somente quando o rótulo não for suficiente;
- elimine ícones e textos duplicados com `ExcludeSemantics`;
- preserve botões como nós próprios, mesmo dentro de um estado de erro;
- marque `liveRegion` apenas para transições que exigem atenção imediata;
- não anuncie continuamente frames, FPS ou detalhes do modelo.

## Galeria de desenvolvimento

No flavor `dev`, abra `/design-system` pelo roteador para inspecionar temas e
componentes. A rota não existe em produção. A galeria é uma ferramenta de
desenvolvimento e não substitui testes com TalkBack em aparelho real.

## Checklist para novas telas

1. Reutilizar os componentes existentes antes de criar uma nova primitiva.
2. Validar tema claro, escuro e alto contraste.
3. Validar fonte em 200% sem corte ou sobreposição.
4. Percorrer toda a tela com TalkBack e confirmar rótulos, ordem e ações.
5. Confirmar alvo mínimo de toque e foco visível.
6. Respeitar redução de movimento.
7. Cobrir estados carregando, vazio, erro, offline e sucesso aplicáveis.
8. Adicionar testes de widget para semântica e comportamento, não apenas pixels.

## Acabamento das telas principais (REN-60)

A tela inicial tem uma única ação dominante: abrir a câmera. O estado offline é
explicado perto dela, sem competir visualmente com a ação; ajustes, ajuda e conta
opcional aparecem como navegação secundária contínua. As configurações deixam
de empilhar cartões independentes e passam a usar seções separadas por divisores,
mantendo a ordem de leitura, os alvos de toque e os controles nativos.

O texto abreviado do tema selecionado é apenas visual: o TalkBack recebe o nome
completo da opção. As capturas de referência em
`test/features/home/goldens/windows/` e
`test/features/assistive_feedback/goldens/windows/` foram inspecionadas em
390 × 844; os testes de comportamento e Semantics rodam em todas as plataformas.
Essas capturas não substituem a homologação em aparelho com TalkBack ativado.
