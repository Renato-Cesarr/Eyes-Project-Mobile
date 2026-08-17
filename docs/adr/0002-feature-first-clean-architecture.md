# ADR 0002 — Clean Architecture pragmática por feature

- Status: aceito
- Data: 2026-08-17

## Contexto

O aplicativo crescerá em autenticação, câmera, detecção, alertas e configurações.
Uma organização puramente por tipo cria acoplamento global; uma Clean
Architecture cerimonial cria arquivos sem responsabilidade real.

## Decisão

Organizar o código por feature, com `presentation`, `application`, `domain` e
`infrastructure`. Uma camada só é criada quando possuir responsabilidade real.
Riverpod será simultaneamente gerenciador de estado e composition root, usando
`AsyncNotifier` para fluxos assíncronos. BLoC e outros contêineres de DI não
serão usados em paralelo.

`go_router` define a navegação declarativa em `app/routing`. Integrações externas
são acessadas por interfaces próximas à regra que protegem.

## Consequências

- features podem evoluir com baixo acoplamento;
- testes substituem providers nas fronteiras;
- não há repository genérico ou camada `data` universal;
- exceções à direção de dependências exigem revisão arquitetural.
