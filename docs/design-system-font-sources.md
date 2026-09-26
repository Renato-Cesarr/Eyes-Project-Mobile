# Fontes offline do Eyes Design System

Os arquivos foram obtidos do repositório oficial `google/fonts` e fixados por commit para garantir builds reproduzíveis.

## Lexend

- origem: `ofl/lexend`;
- commit: `e2332cf862ac3145c0ee5f24f04f4c1819b2410b`;
- licença: SIL Open Font License 1.1;
- arquivo: `assets/fonts/Lexend-Variable.ttf`;
- SHA-256: `3add53e641fbc81da64da4bb254285e2831b52b029527bc0714e2b9610832ee6`.

## Atkinson Hyperlegible

- origem: `ofl/atkinsonhyperlegible`;
- commit: `95f4904fc8bcf26d3420fe315560c96417c6dec7`;
- licença: SIL Open Font License 1.1;
- regular SHA-256: `7fb917c89019896d0b52ee84b7cbb3304c18cb90b19a62f5e32712bd23e97669`;
- bold SHA-256: `5a3b0c8cc8ca545155150b4512a1fa248298df121c50d6557e651e61fbdab92f`.

As licenças integrais ficam em `assets/licenses`, são incluídas no bundle e registradas no `LicenseRegistry` durante o bootstrap. Nenhuma fonte é baixada em tempo de execução.

