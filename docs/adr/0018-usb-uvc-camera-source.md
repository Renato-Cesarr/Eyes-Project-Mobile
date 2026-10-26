# ADR 0018 — Fonte de imagem USB/UVC para a varredura assistiva

- **Status:** aceito para implementação; homologação física pendente.
- **Card:** REN-76.

## Contexto

O Eyes usa a câmera traseira do Android para alimentar inferência TFLite local,
proximidade relativa e avisos acessíveis. O TCC prevê uma câmera corporal.
Precisamos permitir a escolha da fonte de imagem sem alterar o contrato de
detecção, enviar vídeo pela rede ou presumir que todo Android disponibiliza
webcams USB como câmeras Camera2.

## Decisão

`SelectableCameraGateway` implementa o contrato `CameraGateway` e seleciona
entre `MobileCameraGateway` e `UvcCameraGateway`. Sem preferência persistida,
uma webcam USB/UVC detectada tem prioridade; na ausência dela, usa-se a câmera
do celular. A seleção manual é persistida localmente. Se a preferência explícita
for webcam e ela não estiver disponível, o app mostra erro recuperável; não
liga outra câmera sem conhecimento do usuário. Se a seleção era automática e
a webcam enumerada não consegue iniciar vídeo, o adaptador abre a câmera do
celular antes da varredura e informa a alternativa no estado acessível. Não há
troca automática após a varredura começar.

`flutter_ffi_uvc` fornece enumeração USB, pedido de acesso ao dispositivo,
prévia por `Texture` e quadros RGBA. O adaptador captura apenas quadros novos
até o limite configurado de 12 FPS, envia-os ao `LatestFrameProcessor` com fila
limitada e traduz RGBA para RGB dentro da infraestrutura de visão. O domínio e
o modelo recebem os mesmos contratos de detecção. A perda do dispositivo ou
um fluxo sem quadros úteis encerra a sessão, os avisos, o worker e o wake lock.

A interface oferece seletor com rótulos e estados para TalkBack. O app não
armazena nem transmite fotos ou vídeo. Permissões e erros nativos são
traduzidos para estados recuperáveis sem detalhes técnicos na voz.

## Consequências e limites

- A webcam precisa expor UVC e ser alimentada de forma estável pelo celular e
  adaptador OTG. Suporte USB host sozinho não garante operação dessa webcam.
- A imagem USB chega sem rotação automática do sensor do celular; o dispositivo
  deve ser montado na orientação correta durante a validação inicial.
- A calibração de proximidade para câmera corporal ainda não foi medida. Os
  alertas de distância não podem ser apresentados como validados para a webcam
  até teste físico e ajuste dos limiares conforme REN-37/REN-70.
- Testes automatizados cobrem preferência, seleção e conversão RGBA. Build
  Android valida empacotamento, mas não substitui verificação em POCO X5 Pro
  com webcam e adaptador reais, TalkBack, desconexão, aquecimento e latência.
