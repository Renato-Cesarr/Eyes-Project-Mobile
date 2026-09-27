# Gates de UI e acessibilidade no Mobile

Os gates protegem a aparência, o uso com TalkBack e a adaptação do texto sem
transformar snapshots em substitutos para testes de comportamento ou validação
no aparelho real.

## Matriz automatizada mínima

| Superfície | Tamanho | Tema | Escala de texto |
| --- | --- | --- | --- |
| Catálogo determinístico assistivo | 390 × 844 dp | claro | 100% |
| Catálogo determinístico assistivo | 390 × 844 dp | escuro | 100% |
| Catálogo determinístico assistivo | 390 × 844 dp | alto contraste claro | 100% |
| Catálogo determinístico assistivo | 390 × 844 dp | alto contraste escuro | 100% e 200% |

O catálogo contém cabeçalho, estado, ação principal e navegação auxiliar. Além
dos goldens, o teste verifica Semantics, ausência de overflow e alvos de pelo
menos 48 dp. Câmera ao vivo, relógio e dados voláteis ficam fora dos snapshots.

As fontes do produto são carregadas dos assets reais. A fonte Material Icons
usada pelo catálogo fica fixada exclusivamente em `test/fixtures/fonts`, com a
respectiva licença, para que os resultados não dependam do caminho interno do
SDK instalado no computador ou no CI. Esse fixture não integra o bundle do app.

As referências ficam separadas em `windows` e `linux`, pois o rasterizador do
Flutter pode produzir pixels diferentes entre os sistemas mesmo com fontes e
SDK idênticos. Ambas são geradas com Flutter 3.44 e revisadas; não se amplia a
tolerância para esconder divergências entre plataformas.

## Comandos

- `flutter test`: executa comportamento, Semantics e comparação dos goldens.
- `flutter test --update-goldens test/core/design_system/ui_quality_gate_golden_test.dart`:
  atualiza as referências do sistema operacional atual após aprovação da
  mudança. As referências Linux devem ser geradas no ambiente reproduzível
  descrito abaixo.
- `docker run --rm -v "${PWD}:/workspace" -w /workspace ghcr.io/cirruslabs/flutter:3.44.0 flutter test --update-goldens test/core/design_system/ui_quality_gate_golden_test.dart`:
  atualiza as referências Linux com a mesma versão usada pelo CI.
- `dart run tool/validate_design_tokens.dart`: impede novas cores literais fora
  dos tokens. Preto e branco permanecem permitidos somente nas superfícies de
  câmera documentadas.

Goldens nunca devem ser atualizados apenas para silenciar o CI. O PR precisa
explicar a mudança, mostrar a diferença e confirmar os critérios acessíveis.

## Checklist manual no aparelho

- [ ] TalkBack anuncia título, estado, ação e direção na ordem da tarefa.
- [ ] Texto ampliado não corta conteúdo nem esconde controles.
- [ ] Temas claro, escuro e alto contraste preservam leitura e foco.
- [ ] Animações reduzidas não removem informação.
- [ ] Voz não se sobrepõe nem repete detecções a cada frame.
- [ ] Vibração funciona, é distinguível e não é excessiva.
- [ ] Safe areas, rotação e preview estão corretos no POCO X5 Pro.
- [ ] Falhas de voz ou vibração não bloqueiam a varredura.

## Relação com a pipeline

O CI executa o validador de tokens antes da suíte completa; qualquer golden,
Semantics, overflow ou alvo mínimo divergente bloqueia o merge. A REN-40 poderá
publicar relatórios e artefatos, e a REN-32 continua responsável pela homologação
física final.
