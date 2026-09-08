# WebRad Viewer Lite — primeira composição V1

A composição padrão mantém o Viewer DICOM 2D e MPR, sem alterar branding,
layout ou código de leitura/renderização. Os diretórios dos módulos permanecem no Git.

## Arquivos alterados

- `weasis-dicom/pom.xml`: exclui SR, AU, Wave, RT e o agregador 3D do reactor.
- `weasis-distributions/pom.xml`: deixa de copiar os quatro viewers especializados,
  Viewer 3D, JogAmp e seus cinco pacotes nativos.
- `weasis-distributions/etc/config/base.json`: remove sua instalação/inicialização,
  desabilita Send e elimina preferências exclusivas de RT/3D.
- `weasis-launcher/conf/base.json`: aplica a mesma seleção na execução local.
- `docs/web-rad-lite-v1.md`: registra decisões e limites de validação.

## Dependências e composição

| Componente | Build | Viewer padrão |
| --- | --- | --- |
| Codec, Explorer, Viewer 2D | Mantidos | Ativos |
| Query/Retrieve, ISO Writer | Mantidos | Ativos |
| SR, AU, Wave, RT | Excluídos | Ausentes |
| Agregador 3D, Viewer 3D, JogAmp, agregador de nativos e cinco nativos | Excluídos | Ausentes |
| Send | Mantido para aquisição | Não instalado/iniciado; página de envio desabilitada |
| Aquisição/Dicomizer | Mantido | Somente no perfil separado Dicomizer |

Não há dependência obrigatória dos módulos excluídos no Viewer 2D, QR ou ISO Writer.
RT depende do Viewer 2D, e não o contrário. O POM raiz e o parent DICOM não
precisaram de alteração.

MPR, inclusive sua implementação de volumes, pertence a `weasis-dicom-viewer2d`.
JOML é usado tanto ali quanto na geometria do codec, e foi preservado. A interface
`VolumeProvider` permite integração opcional com outros viewers; não exige o Viewer 3D.
JOGL (`jogl-all`), GlueGen (`gluegen-rt`), JOCL e seus nativos pertencem à árvore
3D excluída. Nenhum import dessas bibliotecas foi encontrado nos módulos mantidos.
A propriedade `jogamp.version` permanece para não quebrar os POMs arquivados.
OpenCV e seus nativos, core image, ImageIO, Swing, docking, launcher, base, Jackson,
DICOM tools e bibliotecas de ISO continuam preservados.

### Exceção: Send

`weasis-acquire-explorer` depende de Send e importa `StowRS` em
`AcquirePublishPanel`. O agregador de testes também depende do acquire-explorer.
Por isso, Send continua compilado e seu JAR continua copiado para a distribuição
compartilhada. Os arquivos `dicomizer.json` existentes já ativam Send separadamente.
No viewer padrão Lite ele não é instalado nem iniciado, e
`weasis.export.dicom.send=false`. QR e ISO Writer não dependem dele.
A distribuição ainda inclui o Dicomizer: separar esse produto permitirá excluir
fisicamente o JAR Send sem quebrar aquisição em uma próxima etapa.

## Interface e funcionalidades

Os menus de abertura consultam as factories OSGi registradas
(`ThumbnailMouseAndKeyAdapter`). A exportação consulta `DicomExportFactory`;
exportação local e ISO permanecem. Ferramentas adicionais do Viewer 2D são
registradas via `InsertableFactory`. Remover os bundles elimina os respectivos
viewers/ferramentas sem editar menus Java. A exportação de anotações, que abre
`DicomExportPR` com uma página Send, já permanece oculta por configuração.
`AutoProcessor` desinstala bundles em cache que não constam da configuração atual.

Permanecem implementados: importação DICOM e DICOMDIR, paciente/estudo/série,
thumbnails, navegação, Window/Level, presets, zoom, pan, scroll, rotação/flip,
medições, cine e MPR/MIP. Os codecs de modalidades comuns CT/MR/CR/DX/US
não foram alterados. Não são oferecidos pelo perfil padrão os viewers SR,
áudio, ECG/waveform, RT, volume 3D ou a página Send.

## Validação

As verificações estáticas validam JSON, unicidade das chaves, permanência dos
bundles necessários e ausência dos viewers excluídos e JogAmp na lista de cópia.
`git diff --check` verifica a integridade do diff.

O build da raiz não inclui `weasis-distributions`; a montagem é uma validação
separada. `-DskipTests` compila os testes, mas não os executa.
A aprovação funcional exige ainda executar o aplicativo em ambiente gráfico e
abrir exames representativos e um DICOMDIR, verificando ferramentas e menus.
Build bem-sucedido não substitui essa verificação visual e de modalidades.

## Próxima fase

1. Validar a interface e imagens CT/MR/CR/DX/US, incluindo séries multiframe,
   DICOMDIR, medições, cine e MPR.
2. Separar o empacotamento Dicomizer para poder excluir Send do build e do pacote Lite.
3. Avaliar QR/Orthanc e ISO Writer com dados de teste.
4. Tratar branding e identidade visual em tarefa própria.

## Resultados desta execução (2026-09-07)

- Java 25.0.4 e Maven 3.8.7.
- `mvn clean install -DskipTests`: **BUILD SUCCESS**, 58,544 s, 28 projetos.
- `mvn -f weasis-distributions/pom.xml clean package -DskipTests`:
  **BUILD SUCCESS**, 11,647 s.
- Pacote: `weasis-distributions/target/native-dist/weasis-native.zip`, 37 bundles.
  A lista de cópia perdeu 11 JARs (quatro viewers especializados, Viewer 3D,
  JogAmp e cinco nativos). Send permanece no pacote pela exceção descrita acima.
- ZIP inspecionado: ausência dos 11 JARs e resolução de todas as referências
  de bundles do `base.json` gerado, substituindo o seletor nativo por Linux x86-64.
- Manifests gerados de codec, explorer, viewer2d, QR e ISO Writer inspecionados:
  sem dependências de pacotes dos módulos excluídos, Send ou JogAmp.
- O sandbox inicialmente bloqueou escrita em `~/.m2`; os mesmos comandos foram
  reexecutados com permissão e concluíram sem correções adicionais de código.
- Não foi realizado teste interativo de inicialização/importação/renderização.
  O aceite funcional permanece pendente; a compilação e montagem estão validadas.
- Logs locais: `/tmp/web-rad-lite-build.log` e `/tmp/web-rad-lite-distribution.log`.

## Atualização: distribuição para Windows e Linux

Por decisão do usuário, a distribuição Lite deixa de copiar os nativos OpenCV
`macosx-aarch64` e `macosx-x86-64`. Permanecem Windows x86-64, Linux x86-64 e
Linux ARM64. Os fontes e módulos Maven de macOS permanecem preservados; apenas
a seleção de artefatos da distribuição mudou. Os scripts de macOS existentes
não representam suporte nesta edição Lite, cujo pacote não contém seus nativos.

- JARs retirados nesta etapa: 20.240.063 bytes.
- ZIP anterior: 75.443.857 bytes; novo ZIP: 55.244.480 bytes (redução de 26,8%).
- Bundles: 37 → 35.
- `mvn -f weasis-distributions/pom.xml clean package -DskipTests`:
  **BUILD SUCCESS**, 9,068 s.
- Verificadas todas as referências de bundles no `base.json` do ZIP para as
  três arquiteturas preservadas e ausência de JARs nativos de macOS.
- Portátil Linux regenerado em `weasis-distributions/target/lite-linux/Weasis`.
  O ZIP é a base de distribuição; um executável/instalador Windows ainda precisa
  ser gerado no ambiente de empacotamento Windows.

## Correção da interface simplificada

A remoção inicial dos bundles não ocultava os menus e painéis genéricos.
Agora `weasis.ui.simple=true` ativa uma interface dedicada, e o perfil
`lite-dvd` separa as preferências do perfil padrão anterior.

- Menu superior simplificado para Arquivo/Sair, sem os menus genéricos de
  importação, exportação, impressão, launchers, configuração e ferramentas.
- Importação/exportação DICOM desabilitadas na interface; as barras vazias
  também deixam de ser criadas pelo `DicomExplorerFactory`.
- Painéis MiniTool, ImageTool, DisplayTool e MeasureTool desabilitados;
  seleção de séries no DICOM Explorer preservada.
- Barras adicionais de screenshot, medição, rotação, cabeçalho DICOM,
  key objects e launchers desabilitadas no Viewer 2D. O MPR também respeita
  o modo simples para medição, rotação e cabeçalho.
- Preservadas as barras de ações do mouse, zoom, janelamento/presets e MPR/MIP.
  O botão com ícone 3D nessa barra corresponde ao MPR, não ao viewer volumétrico removido.
- Leitura de arquivos continua disponível por argumento de inicialização:
  `Weasis /caminho/da/pasta-DICOM`. Isso permite testar sem reintroduzir o menu Importar.
- A preparação final da mídia para abrir automaticamente o exame permanece
  uma etapa separada. A interface simplificada não desativa os codecs ou o leitor DICOMDIR.

Arquivos Java adicionais alterados: `WeasisWin.java`, `DicomExplorerFactory.java`
e `MprContainer.java`. As configurações de distribuição e execução local são equivalentes.

Validação da correção: `mvn clean install -DskipTests` terminou com **BUILD SUCCESS**
(58,571 s); distribuição com **BUILD SUCCESS** (9,948 s); portátil Linux regenerado.
Verificados os flags efetivos do perfil simples e a identidade dos três JARs Java
recompilados com os JARs incluídos no portátil. Verificação visual interativa pendente.

## Ajuste para testes: importação local disponível

A pedido do usuário, a interface simples mantém `Arquivo → Importar`.
`weasis.import.dicom=true` permite selecionar exames locais e DICOMDIR pelo
 diálogo existente. Importação de imagens comuns e QR, exportação e preferências
continuam desabilitadas/ocultas. Não é necessário passar um exame como argumento
para iniciar o programa e selecionar posteriormente os arquivos.

Validação deste ajuste: build raiz **SUCCESS** (58,283 s), empacotamento
**SUCCESS** (7,507 s), portátil Linux regenerado e configuração/JAR da interface
conferidos. Teste visual interativo ainda não realizado.

## Atualização: Linux ARM64 excluído da distribuição

Removida a cópia de `weasis-opencv-core-linux-aarch64` do POM da distribuição,
por solicitação do usuário. Permanecem os nativos Windows x86-64 e Linux x86-64;
os diretórios e módulos fonte de outras arquiteturas não foram apagados.

- Economia de 11.142.373 bytes em JARs.
- ZIP: 55.245.482 → 44.150.036 bytes (aproximadamente 20,1% menor).
- 34 bundles; referências de instalação verificadas para ambas as arquiteturas.
- Empacotamento Maven: **BUILD SUCCESS**, 8,527 s.
- Portátil Linux x86-64 regenerado no mesmo caminho de teste.

## Restauração de macOS (2026-09-08)

O destino da mídia de exames passa a incluir Windows x86-64 e macOS,
tanto Intel (x86-64) quanto Apple Silicon (aarch64). Restaurada no POM da
distribuição a cópia dos dois bundles OpenCV de macOS. Linux x86-64 permanece;
Linux ARM64 continua excluído. Esta decisão substitui a exclusão de macOS
documentada anteriormente. Os módulos 3D e JogAmp continuam excluídos.

A inclusão dos nativos no ZIP compartilhado não gera o aplicativo macOS.
Ainda são necessários o empacotamento nos ambientes Windows/macOS e testes
com exames em mídia somente para leitura, sem internet. O workflow Windows/macOS
ainda usa o nome `Weasis`, enquanto `package-weasis.sh` usa `WebRad Viewer`;
os scripts da mídia devem ser alinhados ao nome final antes da entrega.

Validação: `mvn -o -f weasis-distributions/pom.xml package -PcompressXZ -DskipTests`
concluído com **BUILD SUCCESS** e 36 arquivos submetidos à compressão.
Na conferência posterior, o diretório `target/native-dist` já não estava
disponível, impedindo verificar o ZIP final. A integridade do artefato deve ser
conferida novamente após sua geração. Não foram executados testes funcionais.
