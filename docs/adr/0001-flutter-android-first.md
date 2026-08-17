# ADR 0001 — Flutter Android-first no MVP

- Status: aceito
- Data: 2026-08-17

## Contexto

O MVP precisa usar a câmera do celular e oferecer uma experiência confiável com
TalkBack. O prazo de TCC não comporta homologação simultânea em Android e iOS.

## Decisão

Usar Flutter estável `3.44.0`, fixado por FVM, e entregar/homologar apenas
Android no MVP. O código Dart permanece portável, mas não serão criados projetos,
pipelines ou compromissos de suporte iOS nesta fase.

Existem dois flavors: `dev` e `prod`. O flavor de desenvolvimento possui
application ID próprio para coexistir com produção no mesmo aparelho.

## Consequências

- o time mantém uma única base mobile;
- testes e acessibilidade concentram-se em aparelhos Android de referência;
- decisões específicas de iOS são adiadas e deverão gerar um novo ADR;
- câmera externa permanece fora do escopo desta fundação.
