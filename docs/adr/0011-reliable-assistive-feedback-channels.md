# ADR 0011: canais assistivos verificáveis e vibração explícita no Android

- Status: aceito
- Data: 2026-09-10
- Card: REN-47

## Contexto

A homologação em Profile no POCO X5 Pro mostrou duas falhas de confiança. Os
impactos de aproximadamente 60 ms produzidos por `HapticFeedback` eram
registrados pelo Android, mas não eram perceptíveis para o usuário. Além disso,
uma fala cancelada pelo lifecycle retornava zero no `flutter_tts` e era tratada
como indisponibilidade do mecanismo, mesmo com a voz funcionando.

Preferência habilitada não comprova capacidade física nem entrega do feedback.
Uma interface assistiva não pode afirmar que um canal está ativo apenas porque
o usuário marcou uma opção.

## Decisão

1. Representar separadamente preferência, disponibilidade do canal e mensagem
   transitória da última operação.
2. Consultar a capacidade real do vibrador durante a inicialização e depois de
   falhas recuperáveis.
3. Manter `AssistiveHaptics` como porta da camada de aplicação e implementar no
   Android um `MethodChannel` restrito a capacidade e padrões semânticos:
   confirmação, aviso e alerta crítico.
4. Produzir os padrões com `VibrationEffect`, amplitude explícita quando
   suportada e uso de acessibilidade, sempre respeitando a preferência do
   usuário.
5. Tratar cancelamento de fala solicitado pelo app como interrupção normal. Só
   erros reais alteram a disponibilidade do TTS.
6. Reconfigurar a política de proximidade apenas quando as preferências mudam;
   notificações de voz ou vibração não podem reiniciar o rastreamento.
7. Exibir recuperação e controles antes da câmera. A visualização da câmera não
   participa da árvore semântica e os estados não são duplicados.

## Consequências

- O Android exige a permissão normal `VIBRATE`, sem diálogo em tempo de execução.
- O POCO recebe pulsos mais longos e distintos, adequados a feedback assistivo.
- O estado visual deixa de produzir o falso positivo “vibração ativa”.
- Pausar, encerrar ou enviar o app ao background não gera falso erro de voz.
- A ponte nativa é pequena e testada no limite Dart; mudanças de plataforma
  permanecem isoladas da aplicação e do domínio.
