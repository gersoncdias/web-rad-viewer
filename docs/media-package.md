# Pacote para WEB-RAD MEDIA

O workflow `Build WebRad media viewer` (`.github/workflows/build-media-viewer.yml`)
compila e testa o reactor Maven, monta a distribuição e executa `jpackage` em
Windows x64, Mac Intel e Apple Silicon. Cada aplicativo inclui seu runtime Java.
O resultado do job `assemble` é `web-rad-viewer-media.zip` e seu `.sha256`.
Este ZIP é o contrato de entrada do repositório irmão `web-rad-media`.
Não confundir com `weasis-native.zip`, que contém apenas a base para jpackage.

Estrutura do ZIP final:

```text
viewer-manifest.json
windows-x86-64/WebRad Viewer.exe
windows-x86-64/app/...
windows-x86-64/runtime/...
macosx-x86-64.zip
macosx-aarch64.zip
```

O manifesto versão 1 identifica o produto e contém SHA-256 de todos os arquivos.
Os ZIPs de Mac guardam `WebRad Viewer.app`, criados com `ditto` para preservar
permissões, links e metadados. Não extrair esses ZIPs no Windows. A mídia mantém
os ZIPs e os extrai no Mac para uma sessão no cache do usuário; ao fechar o
visualizador, o script remove essa sessão. Os exames continuam na mídia.

## Execução

1. Disponibilizar este código no repositório GitHub e executar manualmente
   `Build WebRad media viewer` na revisão desejada.
2. Baixar o artefato `web-rad-viewer-media` e extrair o ZIP externo do GitHub.
3. No `web-rad-media`, executar:
   `python3 src-tauri/scripts/prepare-viewer.py /caminho/web-rad-viewer-media.zip SHA256`.
4. Compilar o MEDIA e validar um ZIP e uma ISO com exames de teste em cada sistema.

Para builds locais em Windows (Git Bash) ou macOS, com JDK 25 no PATH:
`bash scripts/build-media-viewer.sh /caminho/native-extraido /caminho/saida`.
A entrada deve ser a extração limpa de `weasis-native.zip`, gerado com compressXZ.
Reunir os três arquivos nativos em uma pasta e executar
`python3 scripts/assemble-media-viewer.py /caminho/nativos /caminho/web-rad-viewer-media.zip`.

## Limites de entrega

Este fluxo gera app-images, não instaladores. Ele não configura certificados de
assinatura Windows nem assinatura Developer ID/notarização Apple. A distribuição
final para pacientes exige decidir e validar essa etapa: não considerar que um
aplicativo sem assinatura estará liberado em máquinas limpas. Não desabilitar
as proteções do sistema para contornar essa pendência.

O build Windows/macOS e a abertura gráfica precisam ser executados nos ambientes
correspondentes. Os testes de contrato usam dados sintéticos e não substituem
abertura offline de exames representativos, mídia somente para leitura e teste
físico da gravação. Os ícones nativos removidos pelo usuário permanecem removidos;
na ausência de `.icns`, jpackage utiliza seu ícone padrão para Mac.

## Verificações locais em 2026-09-08

- ZIP intermediário existente conferido: íntegro e com os quatro nativos OpenCV
  (Windows x64, Linux x64, Mac Intel e Apple Silicon).
- Contrato de montagem/importação exercitado com aplicativos sintéticos.
- Quatro testes Python do importador passaram (hash, integridade, composição e caminhos).
- Backend MEDIA: 13 testes passaram. O teste de mídia criou e reabriu ZIP e ISO
  com `zip`, `unzip` e `xorriso`, usando instâncias e dcmmkdir sintéticos.
- Sintaxe dos scripts Bash e leitura dos workflows YAML verificadas.
- Não foram gerados executáveis Windows/macOS nem executados os workflows remotos.
  Assinatura/notarização e validação gráfica permanecem pendentes.
