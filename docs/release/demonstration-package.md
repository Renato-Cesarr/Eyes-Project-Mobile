# Pacote Android rastreável — REN-40

A CI existente passa a produzir APK **release do flavor dev**, instalável
com assinatura de teste. Não é publicação em loja, assinatura de produção nem
aceite em aparelho. O applicationId é br.com.eyesproject.mobile.dev; o flavor
prod e seu bundle continuam sem adoção desta chave. A execução de testes,
análise, goldens, cobertura e Sonar permanece obrigatória.

## Gerar em checkout limpo

Fixar o commit antes do build. Usar Flutter 3.44.0/Dart 3.12.0 e Java 21,
Android SDK/build-tools e PowerShell 7; conferir scripts/check-toolchain.ps1.
Não usar um build antigo depois de mudar o checkout. O pacote documentado usa
lib/main_dev.dart e API dev padrão http://10.0.2.2:8080 (host do emulador).

```powershell
flutter pub get
./scripts/check-toolchain.ps1 -Ci
flutter analyze
dart run tool/validate_design_tokens.dart
flutter test --coverage
flutter build apk --release --flavor dev --target lib/main_dev.dart
./scripts/package-demo.ps1
```

A assinatura dev é gerada pelo SDK na máquina/runner. Segredos de produção
não são necessários nem incluídos no pacote. Uma assinatura de teste diferente
em outro runner pode exigir desinstalar a versão anterior; preservar/exportar
dados antes dessa decisão. Não prometer hashes binários iguais entre runners.

package-demo.ps1 exige checkout Git limpo, lê seu HEAD real e recusa output
existente. Confere SHA/tamanho do modelo original e do binário dentro do APK,
manifesto embarcado byte a byte com o manifesto versionado, assinatura via
apksigner e identidade/versão via aapt. Recusa APK debuggable, outro flavor,
versão divergente, assets ausentes/duplicados, fonte alterada e APK alterado
durante a verificação. Flutter/Java no manifesto são os pins; o passo de
toolchain da CI valida os executáveis. O pacote não afirma que o Sonar passou.

Saída em build/demo, fora do Git:

- eyes-dev-release-COMMIT.apk: commit completo do checkout usado no build;
- demo-manifest.json: commit, versão, hash/tamanho APK, modelo/manifesto,
  flavor, assinatura de teste e limitações;
- signature.txt: verificação/certificado público, sem chave privada;
- SHA256SUMS: recibo dos três arquivos.

Para repetir, escolher uma pasta nova com -OutputDirectory. Não sobrescrever
evidência anterior. -RepositoryRoot e -ApkPath permitem verificar um checkout
e seu APK explicitamente; não mudam os requisitos de identidade/assets/fonte.

## Recuperar e verificar a CI

O upload ocorre **somente depois de todos os gates passarem**. Nome:
eyes-mobile-demo-CHECKOUT_SHA-RUN_ATTEMPT; retenção de 14 dias. Inclui pacote
e coverage/lcov.info. Em PR, o checkout pode ser merge sintético: o HEAD no
manifesto é o commit efetivamente compilado, não necessariamente o head da
branch do autor. Conferir run, PR e ancestrais antes de congelar entrega.

```powershell
gh run download RUN_ID --repo Renato-Cesarr/Eyes-Project-Mobile --name NOME_ARTIFACT --dir PASTA_NOVA
Get-FileHash PASTA_NOVA/build/demo/eyes-dev-release-COMMIT.apk -Algorithm SHA256
```

Comparar todos os arquivos com SHA256SUMS e manifesto. No Linux, executar
sha256sum -c SHA256SUMS dentro de build/demo. Como APK e LCOV têm raiz comum,
o download mantém build/demo/ e coverage/. A assinatura e assets podem ser
reconferidos com o script no checkout correspondente, em output novo.
Artifacts temporários não são uma release permanente; preservar a cópia
verificada com o manifesto conjunto das quatro áreas para a REN-74.

## Congelar a versão conjunta

Registrar commits Mobile, IA, Back e Front, runs/checks das branches de
destino, hashes do APK e do modelo, relatórios e configuração efetiva. Conferir
que o manifesto do modelo Mobile corresponde ao contrato da IA. O relatório
IA de smoke/tempo de tensor sintético deve identificar seu próprio commit;
ele não mede câmera/TTS em Android nem qualidade em corpus de sala.

O roteiro web integrado está em docs/qa/real-product-flows.md do Front.
API/PostgreSQL/Mailpit precisam estar na versão registrada. REN-73/75/18/32
mantêm prova física, offline, consentimento, TalkBack, câmera/voz/háptico.
REN-34/35/37/69 mantêm avaliação científica. Gate verde de PR não comprova dev
após merge; gate ausente/falho não pode ser removido para concluir a REN-40.

## Uso da demonstração

Assistência é local e conta é opcional. No emulador, a API padrão exige
localhost:8080 no host. Em aparelho, preparar e registrar uma configuração
dev apropriada antes de recompilar/validar; o pacote padrão não comprova
conectividade física. Nenhum deploy, envio externo ou instalação é automático.
O app com este APK ainda precisa do roteiro de validação humana e física.
