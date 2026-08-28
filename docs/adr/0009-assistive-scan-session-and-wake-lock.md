# ADR 0009 — Sessão principal de varredura e tela ligada

- Status: aceito
- Data: 2026-08-28
- Issue: REN-42

## Contexto

A tela principal precisa representar com precisão a disponibilidade conjunta da
câmera e da inteligência artificial local. Para uma pessoa cega, uma ação que
pareça ativa quando o pipeline está carregando, pausado ou indisponível é um
risco de segurança. Durante a varredura, o Android também não deve apagar a tela
e suspender o fluxo sem que o usuário tenha solicitado pausa ou encerramento.

## Decisão

Adotar `AssistiveScanStatus` como estado derivado de produto sobre câmera e
runtime de visão. A interface apresenta uma única ação primária estável para
iniciar, pausar ou retomar; o encerramento é uma ação separada e confirmada. A
alternativa segura do diálogo — continuar a varredura — recebe o foco inicial.

`AssistiveScanCoordinator` coordena todas as transições e preserva estas
invariantes:

- varredura ativa exige câmera em `streaming` e modelo em `ready`;
- pausa e encerramento liberam câmera, interpretador, alertas e proximidade;
- encerramento produz o estado explícito `ended`, distinto de uma sessão nunca
  iniciada;
- background e saída da tela liberam os mesmos recursos sem anúncio duplicado;
- feedback de início, pausa e fim usa padrões hápticos distintos e um som curto,
  respeitando a preferência de vibração.

Introduzir `ScanWakeLockGateway` na camada de aplicação, implementado por
`wakelock_plus` na infraestrutura. O wakelock é habilitado somente após câmera e
modelo confirmarem estado ativo. Toda outra transição solicita sua desativação.
Falhas nessa capacidade são degradáveis, sanitizadas e não impedem a varredura.

As dependências necessárias ao encerramento são capturadas antes de qualquer
espera assíncrona. Isso permite liberar recursos mesmo quando a rota está sendo
descartada e evita acessar um `Ref` do Riverpod depois do fim do escopo.

## Acessibilidade e segurança

- preview, FPS, latência e detalhes de tensor não entram no TalkBack;
- estados operacionais usam região viva somente quando não há painel de erro
  concorrente;
- botões têm rótulo, dica, alvo mínimo e ordem de foco determinística;
- alto contraste e escala de texto de 200% não ocultam ações essenciais;
- a ajuda explica privacidade offline, permissão de câmera e limites de uso;
- o aplicativo é uma tecnologia assistiva e não substitui bengala, cão-guia ou
  técnicas de orientação e mobilidade.

## Consequências

- a UI não combina estados técnicos por conta própria;
- plugins de wakelock e háptica permanecem fora de `domain` e `presentation`;
- testes podem substituir ambas as fronteiras e verificar o ciclo completo;
- manter a tela ligada tem custo energético deliberado e limitado à sessão
  ativa;
- futuras políticas térmicas podem solicitar pausa pelo mesmo coordenador sem
  alterar o contrato visual.
