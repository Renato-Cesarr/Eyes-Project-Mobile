# Teste técnico Android sem computador — REN-78

## Para quem vai testar

1. Receba o APK do Renato e instale em Android 8 ou superior. Se solicitado,
   permita instalação pelo aplicativo usado para abrir o arquivo. Depois pode
   retirar essa permissão. Não desinstale versão anterior sem preservar os dados.
2. Abra Eyes e conclua as orientações. Siga sem login; permita câmera na etapa
   correspondente. A varredura não precisa de servidor ou internet.
3. No início abra **Ajuda e segurança**, depois **Diagnóstico de teste**.
4. Leia o resumo; se concordar, marque a escolha e toque **Iniciar diagnóstico**.
5. Toque **Abrir câmera**. Teste com visão normal, sentada ou em local seguro,
   apontando para cadeira, pessoa, mesa e mochila, um de cada vez. Não caminhe
   vendada nem use o protótipo como orientação de deslocamento.
6. Observe se os avisos fazem sentido, se a voz sai pelo fone/alto-falante escolhido
   e se sente a vibração nos alertas quando ativada. Configurações também permite
   testar voz e vibração separadamente.
7. Volte ao diagnóstico e toque **Encerrar diagnóstico**.
8. Toque **Compartilhar relatório**, escolha WhatsApp ou outro aplicativo e envie
   **eyes-diagnostico.json** ao Renato. Confira se o anexo realmente foi enviado.
9. Mande também um relato curto: objeto apontado, o que funcionou, demora,
   travamento e eventual falta de voz/vibração. Não inclua senhas ou imagens de
   outras pessoas.

Ao reabrir, o último relatório pode ser recuperado na mesma tela; a coleta não
recomeça. Até cinco segundos finais podem se perder. Se a instalação falhar,
envie a mensagem exibida e o modelo do celular antes de apagar qualquer versão.

Para novo teste, compartilhe o anterior se desejar, depois **Apagar relatório
local**. Isso não remove cópias enviadas. Registros com sete dias vencidos são
removidos na próxima abertura/consulta. Não precisamos do seu login.

## Para a equipe

Dev/release otimizado, assinatura de desenvolvimento; não é loja/produção.
Conferir recibo, manifesto e SHA-256 do pacote exato. O candidato de 05/11 inclui
Orbit 3f12eb1 ainda em PR e REN-78. Endpoint api.example.invalid é intencional:
sem backend no teste; não usar login/sincronização. Inferência/voz/háptico locais.
Proximidade em outro aparelho ainda não está calibrada.

JSON contém report e device. Contagem de classe é de frames, não de objetos únicos.
Alertas são enfileirados; callback TTS não comprova som ouvido ou vibração sentida.
Estatísticas cobrem até 512 amostras recentes, sem mAP/recall/FPS. Diagnóstico não
substitui corpus, protocolo de calibração ou homologação do POCO.

Guardar arquivo recebido sem publicá-lo em Git; contém horários e modelo do
aparelho. Registrar somente evidência observada no card. REN-77 mantém aprovação
própria; este roteiro não autoriza pesquisa com venda. Não há acompanhamento ao
vivo: recebemos o arquivo que a pessoa optar por compartilhar e seu relato.

Build em checkout limpo (ver ADR 0020 e guia de pacote demonstrável):

```powershell
./scripts/build-demo.ps1 -ApiBaseUrl https://api.example.invalid
./scripts/package-demo.ps1 -ExpectedApiBaseUrl https://api.example.invalid -OutputDirectory build/demo-remote-test
```

O compartilhamento Android continua sem homologação até execução no aparelho.
