# ADR 0004: ciclo de câmera, backpressure e privacidade

- Status: aceito
- Data: 2026-08-17
- Linear: REN-28

## Contexto

O MVP usa a câmera do celular continuamente e, no REN-29, entregará os frames a
um modelo TensorFlow Lite. Uma fila convencional pode consumir memória e fazer
o modelo analisar imagens antigas. Permissões e falhas nativas também precisam
ser compreensíveis por uma pessoa que usa TalkBack.

## Decisão

1. Usar os plugins `camera` e `permission_handler`, encapsulados por
   `MobileCameraGateway`.
2. Manter tipos do plugin fora de `domain` e `application`; a fronteira entrega
   `CameraFrame` neutro ao consumidor configurado por Riverpod.
3. Começar com câmera traseira, resolução média, áudio desativado, NV21 e alvo
   de 12 FPS, sujeito a benchmark no aparelho de referência.
4. Processar no máximo um frame e reter no máximo o frame mais recente. Imagens
   intermediárias são descartadas e contabilizadas.
5. Liberar stream e controller ao pausar, sair da tela ou ir para segundo plano.
   Uma sessão antes ativa é preparada novamente quando o app retorna.
6. Representar permissão, preparação, operação e falhas como estados tipados. A
   apresentação fornece as mensagens e ações acessíveis.
7. Não salvar nem registrar imagens. A telemetria contém somente contadores,
   FPS, duração e códigos técnicos não sensíveis.

## Consequências

- O REN-29 pode substituir o consumidor vazio por inferência sem conhecer o
  plugin da câmera.
- Latência e memória ficam limitadas mesmo se a inferência for mais lenta que o
  produtor de frames.
- Retomar exige nova inicialização, com pequeno custo de tempo em troca da
  liberação correta do hardware e de um lifecycle previsível.
- A câmera externa permanece fora desta implementação; outro gateway poderá ser
  adicionado quando esse requisito entrar no escopo.
