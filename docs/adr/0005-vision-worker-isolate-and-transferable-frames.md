# ADR 0005: isolate persistente e frames transferíveis

- Status: aceito
- Data: 2026-08-20
- Card: REN-29

## Contexto

O EfficientDet-Lite0 precisa receber continuamente imagens da câmera sem
bloquear animações, TalkBack ou gestos da thread principal. Copiar buffers entre
isolates, recriar o interpretador a cada frame ou acumular uma fila ilimitada
causaria latência, pressão de memória e alertas desatualizados.

## Decisão

1. Usar um isolate persistente, proprietário exclusivo do interpretador TFLite,
   do pré-processamento e dos detalhes de tensores.
2. Carregar e verificar modelo e manifesto dentro desse isolate usando o token
   do isolate raiz. Nenhuma inferência depende de rede.
3. Empacotar todos os planos de cada frame em um único
   `TransferableTypedData`. A criação do buffer é linear, mas a transferência
   entre isolates é constante e sem cópia adicional.
4. Aceitar somente uma requisição em voo. O pipeline da câmera mantém no máximo
   o frame pendente mais recente e descarta frames obsoletos.
5. Usar protocolo tipado para `ready`, detecção, falha e `dispose`; mensagens de
   erro não transportam pixels nem conteúdo sensível.
6. Confirmar `dispose` apenas depois de liberar o interpretador. Se o prazo de
   encerramento expirar, matar o isolate e marcar a sessão como falha.
7. Expor `loading`, `ready` e `error` por `AsyncNotifier`/Riverpod. UI e TalkBack
   não conhecem ports, isolates, tensores ou TFLite.
8. Manter CPU com quatro threads como baseline. Delegates só serão considerados
   depois de medição no POCO X5 Pro.

## Consequências

- A thread principal não executa conversão de pixels nem inferência.
- O modelo é alocado uma vez por sessão ativa e liberado no background.
- Uma falha fatal invalida a sessão; `retry` cria um isolate limpo.
- `TransferableTypedData` evita uma nova cópia no envio, mas não elimina o custo
  de formar o buffer transferível a partir dos planos entregues pelo plugin.
- A Fase 4 deve conectar o lifecycle da tela ao `VisionController` e adaptar a
  orientação da câmera para `VisionRotation`.
