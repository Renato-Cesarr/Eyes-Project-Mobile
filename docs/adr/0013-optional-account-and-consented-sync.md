# ADR 0013: conta opcional e sincronização consentida

- **Status:** aceito
- **Data:** 2026-09-18
- **Card:** REN-27

## Contexto

O valor assistivo do MVP está no processamento local de câmera, detecção,
proximidade, voz e vibração. Condicionar esse fluxo a uma conta ou à rede
criaria um ponto único de falha incompatível com o produto. Ao mesmo tempo, uma
sessão remota será necessária para futuras funções administrativas e para uma
sincronização limitada, sempre opcional.

## Decisão

1. A conta é opcional e nunca participa do gate de inicialização da varredura.
2. O login usa `POST /api/v1/auth/login`; a senha existe somente durante a
   requisição e não é persistida.
3. O token e o perfil mínimo retornado pela API ficam no armazenamento seguro.
4. Um interceptor adiciona `Bearer` às requisições autenticadas. Uma resposta
   `401` remove apenas a sessão remota e produz estado recuperável; câmera,
   modelo e preferências locais permanecem ativos.
5. Sincronização exige consentimento explícito e revogável. Revogar o
   consentimento apaga a fila local pendente.
6. A fila é idempotente e aceita somente metadados escalares. Chaves ligadas a
   imagem, frame, vídeo, áudio, senha ou token são rejeitadas antes da
   persistência.
7. O MVP não possui refresh token. Uma sessão expirada exige novo login quando
   houver conexão.

## Consequências

- Falhas da API degradam apenas recursos remotos.
- O aplicativo continua demonstrável integralmente offline.
- A fronteira de sessão pode ser reutilizada por endpoints futuros sem acoplar
  autenticação ao domínio de visão computacional.
- A existência da fila não autoriza envio: o consumidor futuro ainda deverá
  comprovar consentimento ativo antes de transmitir cada item.
- O protocolo de sincronização do backend ainda precisa ser definido antes de
  habilitar qualquer envio real.
