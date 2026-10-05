# Roteiro de avaliação física — REN-67 / REN-32

**Estado: preparado; nenhuma execução física registrada.** Este roteiro valida a composição restante em aparelho Android real e complementa os testes de widgets. Não substitui o protocolo de calibração, benchmarks de REN-29 ou checklist final REN-74.

## Identificação obrigatória da sessão
Preencher antes de iniciar: responsável; data/hora/fuso; fabricante/modelo; versão Android; resolução/densidade; versão do TalkBack; tema e escala de texto; SHA do código; SHA-256 do APK instalado; versão/flavor; nível de bateria e condições relevantes. Obter o APK do checkpoint de REN-67 e conferir o hash antes da instalação.

Usar o flavor dev em perfil para avaliação. A calibração permanece desabilitada por padrão. Não habilitar coleta só para verificar layout. A conta é opcional e não é necessária para câmera ou avisos. O envio remoto de metadados ainda não está disponível neste pacote.

## Método e registro
Executar cada cenário nos quatro temas; priorizar texto 100% e 200%, modo sem animações e o aparelho de menor viewport disponível. Larguras 320/390 foram testadas em widgets; registrar a largura efetiva do aparelho, sem atribuir a ele uma medida não conferida.

Para cada linha, registrar **não executado / aprovado / reprovado / bloqueado**, observação reproduzível e referência da captura/log. Todas as linhas abaixo estão inicialmente **não executadas**. Capturas físicas são evidência de composição; gravar ou compartilhar conteúdo de câmera exige cuidado com as pessoas presentes. Preferir cenas controladas sem dados pessoais.

| ID | Cenário e resultado esperado | Registro |
| --- | --- | --- |
| F01 | Primeiro uso: cinco etapas, progresso anunciado uma vez, ordem compreensível e botões legíveis | Não executado |
| F02 | Sem permissão prévia: câmera solicitada somente na ação da etapa contextual; negar não inicia sessão | Não executado |
| F03 | Replay pela ajuda: mantém navegação e estado persistido coerentes, sem solicitar câmera antecipadamente | Não executado |
| F04 | Ajuda: teste de voz/vibração facilmente encontrado; execução real e eventual falha descrita com clareza | Não executado |
| F05 | Conta visitante: câmera funciona sem login; aviso de envio indisponível explícito | Não executado |
| F06 | Conta conectada, se houver ambiente de API disponível: identidade e consentimento local legíveis; nenhuma promessa de sincronização pronta | Não executado |
| F07 | Consentimento: confirmar/cancelar, persistir/reabrir e revogar sem ativar envio remoto inexistente | Não executado |
| F08 | Câmera pronta/ativa: preview útil, ajuda/configurações acionáveis e mensagem de privacidade legível | Não executado |
| F09 | Cena clara e escura controlada: painéis opacos, contraste legível e elementos não cobrem controles essenciais | Não executado |
| F10 | Pausa: streaming interrompido, estado claro, retomada acessível; conferir liberação de wake lock com observação/log nativo adequado | Não executado |
| F11 | Encerrar: cancelar mantém comportamento coerente; confirmar libera recursos e oferece próximo passo | Não executado |
| F12 | Permissão negada/bloqueada: recuperação contextual, caminhos alcançáveis e nenhuma sessão indevida | Não executado |
| F13 | Erro de modelo/memória: quando reproduzível com mecanismo controlado autorizado, motivo sanitizado e recuperação única; se indisponível, registrar bloqueado e preservar evidência de widget | Não executado |
| F14 | Texto 200%: título completo, navegação de volta, rolagem até ações finais e alvo mínimo; sem sobreposição/corte | Não executado |
| F15 | TalkBack: títulos/estado/ações anunciados em ordem útil; progresso/erro sem fala duplicada; foco chega à recuperação | Não executado |
| F16 | Voz e vibração Android: alertas reais, estados e recuperação não introduzem repetição; falha de canal continua compreensível | Não executado |
| F17 | Modo avião: câmera, detecção e avisos locais continuam; destinos de conta indicam falha remota sem impedir uso local | Não executado |
| F18 | Background/retorno/bloqueio: recursos liberados/retomados conforme política existente, sem câmera presa ou controle incoerente | Não executado |
| F19 | Quatro temas e redução de movimento: contraste, foco e legibilidade permanecem coerentes | Não executado |
| F20 | Segurança: proximidade relativa e limitações compreensíveis; não apresentar distância métrica ou substituição de bengala/acompanhamento | Não executado |

## Resultado e encaminhamento
Registrar quantos cenários foram executados, aprovados, reprovados e bloqueados; anexar as evidências ao REN-32 com versão exata. Reprovações devem ter passos, resultado esperado/observado e vínculo com o card correspondente. Não marcar aceite físico somente pela existência deste roteiro ou por resultados automatizados.

Melhorias de desempenho só podem ser afirmadas com coleta controlada e comparável: versão/modelo/dispositivo/condições, métricas e método. Este roteiro de interface não cria essa evidência.
