# ADR 0010 — Onboarding acessível e permissão contextual

- Status: aceito
- Data: 2026-08-31
- Issue: REN-41

## Contexto

O Eyes depende da câmera e de saídas não visuais, mas solicitar uma permissão
na abertura, sem explicar finalidade, privacidade e limites, não produz uma
decisão informada. O primeiro uso também não pode depender de conta, rede ou
ajuda visual, pois o caminho assistivo principal é local e atende pessoas cegas
ou com baixa visão.

## Decisão

Adotar um fluxo de cinco etapas com uma ação primária por etapa:

1. proposta de valor;
2. limites de segurança;
3. processamento local e ausência de sincronização no MVP;
4. testes independentes de voz e vibração;
5. permissão de câmera just-in-time.

`OnboardingController` mantém estado tipado em Riverpod. A apresentação não
importa `permission_handler`: consulta e solicita câmera exclusivamente por
`CameraGateway`. A conclusão é persistida por `OnboardingRepository` com uma
chave local versionada. Não são gravados imagens, credenciais, conteúdo de voz,
identificadores ou escolhas implícitas de sincronização.

Negação temporária oferece nova solicitação. Negação permanente ou restrição
oferece as configurações do aparelho. Conceder câmera não é condição para ler e
concluir as orientações; sem permissão, a varredura continuará indisponível e a
tela principal voltará a apresentar recuperação explícita.

O login é opcional e pertence à REN-27. Esta entrega não cria uma autenticação
parcial: comunica e permite continuar sem conta no modo offline.

## Acessibilidade

- progresso é anunciado como “etapa atual de total”, sem depender da barra;
- títulos são cabeçalhos semânticos e recebem foco previsível após transição;
- ícones são decorativos e excluídos da árvore do TalkBack;
- resultados de testes e permissão usam regiões vivas somente quando mudam;
- ações possuem texto, estado habilitado e alvo mínimo de 64 pontos;
- todo o fluxo permanece rolável com fonte em 200%;
- Ajuda e Segurança permite repetir as orientações e os testes.

## Consequências

- o primeiro frame de câmera nunca é aberto pelo onboarding;
- remover dados do aplicativo faz o fluxo ser apresentado novamente;
- mudanças futuras no texto ou etapas exigem nova versão da chave se precisarem
  de reapresentação obrigatória;
- consentimento para sincronização futura deverá ser explícito, separado e
  revogável, sem reutilizar a conclusão deste onboarding;
- validação automatizada não substitui o teste manual com TalkBack no aparelho
  de referência.
