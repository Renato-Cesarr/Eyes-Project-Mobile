# ADR 0015: experiência camera-first para a varredura assistiva

- **Status:** aceito
- **Data:** 2026-09-26
- **Card:** REN-57

## Contexto

A tela de varredura funcional apresentava preview, estado, capacidades,
recuperação e controles como uma sequência vertical de cartões. A câmera ficava
abaixo das ações e perdia prioridade, principalmente em aparelhos estreitos e
com fonte ampliada. A composição também aproximava a principal experiência do
produto de uma página de configurações, aumentando a carga cognitiva.

O fluxo de domínio já estabiliza detecções, proximidade e anúncios. O redesenho
não pode mover essa responsabilidade para a interface, repetir fala a cada frame
nem alterar o ciclo de vida da câmera e do interpretador.

## Decisão

1. A varredura passa a usar um palco camera-first que ocupa toda a área útil da
   tela abaixo da barra superior.
2. Estado operacional, último alerta estabilizado e ações formam sobreposições
   de alto contraste. O preview permanece decorativo e fora do TalkBack.
3. Iniciar, pausar/retomar e encerrar ficam em um dock persistente. Ajuda e
   preferências continuam acessíveis diretamente pela barra superior.
4. O último alerta usa objeto, faixa de proximidade e direção já produzidos pela
   aplicação. A interface não interpreta caixas, pixels, confiança ou tensores.
5. Falhas bloqueadoras substituem o palco por recuperação segura. Indisponibilidade
   de voz ou vibração usa aviso compacto e não interrompe a inferência local.
6. FPS, latência, threshold e contadores deixam a experiência de produto. A
   telemetria continua disponível internamente para diagnóstico e testes.
7. A proporção do sensor é orientada conforme o viewport e o preview usa
   `BoxFit.cover`, com recorte central e sem deformação.
8. Em fonte ampliada ou viewport baixo, as sobreposições tornam-se roláveis e
   os controles mudam de linha para coluna, preservando todas as ações.
9. A árvore semântica contém somente estado, alerta estabilizado, orientações de
   recuperação e ações. O alerta visual não é `liveRegion`, pois a fala é
   responsabilidade da fila TTS existente.

## Consequências

- a câmera volta a ser a superfície principal do produto;
- a hierarquia fica menor e mais previsível para baixa visão e uso com TalkBack;
- diagnósticos deixam de competir com informações necessárias à segurança;
- o pipeline offline, o backpressure, o wakelock e a liberação de recursos não
  sofrem alteração;
- mudanças futuras no detector não exigem mudanças na composição visual, desde
  que preservem os contratos de `AssistiveScanStatus` e `ProximityAlertEvent`;
- validação visual final em aparelho físico permanece necessária para confirmar
  recorte e safe areas específicos do fabricante.
