# 4.2 Metodologia de software

Esta seção descreve como o JacalorIA foi desenvolvido. Trata-se de um aplicativo que identifica alimentos a partir de fotos, calcula calorias e macronutrientes, e utiliza recursos de gamificação e interação social para manter o usuário engajado. A construção do artefato combinou a *Design Science Research* (DSR) e a *Action Design Research* (ADR) com um processo de engenharia iterativo, percorrendo planejamento, análise de requisitos, diagramas, design, codificação, testes e *deploy*. Os artefatos intermediários produzidos nessas etapas — documentos de requisitos, diagramas e especificações detalhadas — subsidiaram o desenvolvimento internamente e não são reproduzidos neste capítulo. O Capítulo 5 apresenta o sistema em funcionamento.

## 4.2.1 Abordagem de pesquisa: Design Science Research e Action Design Research

A *Design Science Research* é um método de pesquisa voltado à produção de conhecimento por meio da concepção, construção e avaliação de artefatos capazes de resolver classes de problemas (HEVNER et al., 2004; LACERDA et al., 2013). Diferentemente de abordagens apenas descritivas, a DSR reconhece que o conhecimento emerge tanto do artefato quanto da evidência de que ele é útil no ambiente para o qual foi projetado. Hevner et al. (2004) situam essa lógica no campo dos sistemas de informação. Peffers et al. (2007) a operacionalizam em um processo com identificação do problema, definição dos objetivos da solução, projeto e desenvolvimento, demonstração, avaliação e comunicação.

Neste trabalho, a classe de problemas corresponde ao registro alimentar digital de elevado esforço, associado ao abandono precoce das aplicações, conforme discutido nos Capítulos 1 e 2. O artefato é o JacalorIA. A demonstração ocorre pela disponibilização do protótipo em produção. A avaliação segue o protocolo da Seção 4.1, com uso da aplicação por participantes durante 30 dias. A comunicação materializa-se neste TCC.

A *Action Design Research* complementa a DSR ao reconhecer que artefatos de tecnologia da informação são moldados no contexto de intervenção, e não apenas em laboratório (SEIN et al., 2011; SCHACHT et al., 2015). O ciclo central da ADR é o BIE (*Building, Intervention and Evaluation*): constrói-se o artefato, coloca-se em uso e avalia-se o resultado para alimentar o ciclo seguinte. Sein et al. (2011) argumentam que construir, intervir e avaliar são atividades entrelaçadas, e não fases estanques.

A adaptação dessas abordagens ao JacalorIA ocorreu da seguinte forma. A DSR organizou o trabalho no nível da pesquisa: o problema foi delimitado, os objetivos da solução foram definidos, o artefato foi projetado e desenvolvido, e a avaliação empírica foi planejada para verificar a utilidade da proposta. A ADR organizou a evolução incremental do software. Autenticação e metas calóricas, reconhecimento alimentar com a tabela TACO, gamificação, interação social e infraestrutura de produção constituíram ciclos de construção, uso interno e refinamento, antes da intervenção com os participantes. Cada incremento foi tratado como uma hipótese de projeto a ser ajustada.

Essa combinação justifica-se pelo caráter aplicado do TCC. Era necessário um enquadramento que legitimasse a construção do software como atividade de pesquisa (DSR) e, ao mesmo tempo, reconhecesse que decisões de interface, de reconhecimento nutricional e de engajamento só se estabilizam quando o artefato é efetivamente utilizado (ADR).

## 4.2.2 Etapas de desenvolvimento

Embora a DSR e a ADR definam o enquadramento da pesquisa, a construção do software exigiu um processo de engenharia. O desenvolvimento foi conduzido de forma iterativa e incremental. Isso significa que o sistema foi construído em etapas sucessivas. Em cada ciclo, definiram-se requisitos, implementou-se o código e verificou-se o funcionamento antes de avançar para a próxima funcionalidade. Essa estratégia permitiu entregar partes do aplicativo de forma progressiva, sem perder a organização geral do projeto.

O trabalho foi organizado por áreas funcionais do sistema, como autenticação, registro de refeições com Inteligência Artificial, perfil do usuário, desempenho, missões e área social. Em cada ciclo, as etapas clássicas de planejamento, análise de requisitos, diagramas, design, codificação, testes e *deploy* foram percorridas. Os produtos detalhados de cada etapa permanecem fora deste capítulo; registra-se, a seguir, apenas o papel que cada uma cumpriu.

**Planejamento.** Partiu-se dos objetivos específicos e da delimitação do estudo. Definiu-se construir um cliente multiplataforma, concentrar as regras de negócio em uma API REST e apoiar-se em serviços gerenciados para persistência, mídia e implantação, de modo a disponibilizar a aplicação aos participantes no prazo do estudo.

**Análise de requisitos.** Os requisitos foram extraídos dos objetivos do Capítulo 1, das barreiras identificadas no Capítulo 2 e das lacunas do mapeamento sistemático. Privilegiou-se reduzir o esforço de registro, manter o usuário no controle da confirmação nutricional e sustentar o uso por gamificação e interação social. O elenco detalhado desses requisitos não é reproduzido aqui.

**Diagramas.** Foram elaborados diagramas de casos de uso, de arquitetura, de implantação e do fluxo de reconhecimento alimentar, além de um modelo das entidades persistidas. Esses diagramas cumpriram a função de comunicar o desenho da solução entre os autores e de orientar a implementação. Sua especificação gráfica não é reproduzida neste capítulo.

**Design.** O desenho privilegiou baixo acoplamento entre interface, regras de negócio e serviços externos. No cliente, a organização é por funcionalidade. No servidor, cada domínio constitui um módulo da API. O reconhecimento alimentar foi separado em visão computacional e enriquecimento nutricional pela TACO, com revisão do usuário antes da persistência. As metas calóricas aplicam a equação de Mifflin-St Jeor, apresentada no Capítulo 2.

**Codificação.** A implementação utilizou Dart no cliente e TypeScript no servidor, com Git como controle de versão. Senhas são armazenadas com *hash*, sessões utilizam *JSON Web Token* (JWT) e as entradas da API são validadas de forma sistemática.

**Testes.** Os testes automatizados acompanharam as regras de maior risco, como o cálculo de metas, a correspondência com a TACO, a revisão da refeição, a captura de imagens e as superfícies de missões e de interação social. A avaliação de uso contínuo com participantes pertence à Seção 4.1. Os testes de regressão cumprem o papel de avaliação interna do artefato, prevista pela DSR (HEVNER et al., 2004).

**Deploy.** A implantação é contínua. Um fluxo de integração dispara no envio à ramificação principal, empacota a API em imagem de contêiner, publica o cliente web e atualiza a rede de distribuição de conteúdo. Interface e API compartilham o mesmo domínio sob HTTPS, condição necessária para o estudo de 30 dias. Aplicativos nativos reutilizam a mesma API.

## 4.2.3 Arquitetura do sistema

O JacalorIA adota um modelo em que o aplicativo no celular ou navegador (o cliente) se comunica com um programa remoto (o servidor). O cliente é responsável pela interface com o usuário. O servidor processa as solicitações, aplica as regras do sistema e se comunica com serviços externos, como a Inteligência Artificial. Essa separação facilita a manutenção do software, pois cada parte pode ser atualizada de forma independente.

No cliente, utilizou-se o Flutter, ferramenta que permite criar o mesmo aplicativo para Android, iOS e navegador web a partir de um único código. A linguagem de programação empregada é o Dart. O aplicativo foi dividido em módulos por funcionalidade — autenticação, registro de refeições, perfil, desempenho, missões e área social — e cada módulo reúne telas, componentes visuais e lógica de funcionamento, o que evita que alterações em uma área prejudiquem as demais.

No servidor, utilizou-se o NestJS, escrito em TypeScript (versão tipada da linguagem JavaScript). O servidor expõe uma API REST, conjunto de endereços na internet pelos quais o aplicativo solicita e recebe informações (por exemplo, registrar uma refeição ou consultar missões). A API está organizada em módulos que correspondem às áreas do sistema, como autenticação, Inteligência Artificial, refeições, missões, interação social, desempenho, notificações e *analytics*. A escolha de um único processo HTTP com fronteiras por domínio reduz o custo operacional do protótipo e simplifica transações que cruzam refeição, ofensiva e missões.

Para armazenar os dados, utiliza-se o PostgreSQL, sistema de banco de dados relacional (organiza informações em tabelas com linhas e colunas, como uma planilha estruturada). O banco é hospedado na plataforma Supabase, que também armazena as fotos de perfil, das refeições e das conversas. O acesso ao banco é feito pelo Sequelize, ferramenta que traduz as operações do programa para comandos de banco de dados. A API persiste apenas as URLs das mídias, o que evita inflar o banco com arquivos binários.

Na implantação, o usuário acessa a aplicação em jacaloria.online. Uma rede de distribuição (Amazon CloudFront) entrega o cliente web a partir de um *bucket* S3 e encaminha as requisições da API ao *backend* hospedado no AWS Elastic Beanstalk. A análise de imagens é uma invocação ao provedor Google Gemini. O GitHub Actions atualiza *frontend* e *backend* a cada integração na ramificação principal.

Dois desacoplamentos merecem registro. O primeiro é o das mídias: fotos de refeição, avatares e imagens de conversa ficam no *Storage* do Supabase, e a API guarda somente o endereço do arquivo. O segundo é o do reconhecimento alimentar: a chamada ao Gemini é isolada atrás de uma interface de provedor, e o enriquecimento pela TACO ocorre depois da inferência. Isso permite trocar o modelo de visão sem alterar o restante da API, o que sustenta a evolução incremental prevista pela ADR.

## 4.2.4 Stack tecnológica

A Tabela 7 resume as ferramentas e as tecnologias de desenvolvimento adotadas, a função de cada componente e a justificativa de uso, conforme implementado no JacalorIA.

**Tabela 7: Principais tecnologias e ferramentas utilizadas no JacalorIA**

| Componente | Tecnologia | Função | Justificativa |
| --- | --- | --- | --- |
| Design da interface | Figma | Prototipação visual das telas, definição de layout, cores, tipografia e fluxo de navegação | O Figma foi escolhido por possibilitar a prototipação e a validação da interface do aplicativo antes da implementação, permitindo a definição e o refinamento iterativo dos elementos visuais e do fluxo de navegação. Além disso, sua interface intuitiva, os recursos de colaboração em tempo real e a familiaridade da equipe com a ferramenta contribuíram para sua adoção no desenvolvimento do projeto |
| Cliente | Flutter / Dart | Interface multiplataforma do aplicativo, com exibição das telas, captura de fotos das refeições e envio dos dados ao servidor | O Flutter foi escolhido por permitir o desenvolvimento de uma única base de código para diferentes plataformas, reduzindo o esforço de manutenção em comparação ao desenvolvimento de aplicações nativas separadas. Além disso, sua integração com recursos do dispositivo, como câmera, e sua capacidade de execução em navegador atenderam às necessidades do projeto, especialmente relacionadas à captura de imagens e testes da aplicação |
| Servidor | NestJS / TypeScript | Processamento das requisições, validação de dados, login e coordenação dos serviços | O NestJS permitiu organizar o servidor em módulos independentes (autenticação, IA, refeições, missões e rede social), com mais estrutura que alternativas como o Express.js. O TypeScript acrescentou tipagem estática ao código, reduzindo erros na manipulação dos dados e facilitando a integração entre o cliente, o servidor e os serviços externos |
| Hospedagem do *backend* | AWS Elastic Beanstalk | Publicação e execução da API em produção | O Elastic Beanstalk foi utilizado para hospedar o *backend*, disponibilizando a API NestJS na internet com implantação por imagem de contêiner e menor esforço operacional em comparação com a configuração manual de servidores |
| Hospedagem do cliente web | Amazon S3 e CloudFront | Publicação do Flutter Web e distribuição sob HTTPS no domínio jacaloria.online | O S3 armazena os arquivos estáticos do cliente web, e o CloudFront os entrega com certificado TLS, encaminhando as chamadas `/api/*` ao *backend*. Essa organização coloca interface e API na mesma origem, evita conteúdo misto e acomoda o tempo da análise de alimentos |
| Banco de dados | PostgreSQL | Armazenamento de usuários, refeições, TACO, missões e grupos | O PostgreSQL foi escolhido devido à sua adequação ao modelo de dados do projeto, que envolve relacionamentos entre usuários, refeições, grupos e interações sociais, permitindo organizar as informações de forma estruturada e confiável |
| Hospedagem do banco | Supabase | Hospedagem gerenciada do PostgreSQL e serviços complementares | O Supabase foi adotado como plataforma de hospedagem do banco de dados, reduzindo a complexidade de configuração da infraestrutura e oferecendo recursos adicionais, como armazenamento de imagens e suporte a dados em formato JSON |
| Acesso ao banco | Sequelize | Tradução entre o código do servidor e o banco de dados | O Sequelize foi adotado por sua integração com o ambiente de desenvolvimento utilizado e pela familiaridade da equipe com a ferramenta. Sua utilização facilitou a comunicação entre a aplicação e o banco de dados, reduzindo a necessidade de consultas SQL manuais e tornando o desenvolvimento das operações de persistência mais eficiente |
| Armazenamento de mídia | Supabase Storage | Arquivos públicos de avatar, foto de refeição e conversa | A persistência de mídia foi desacoplada da API. O banco guarda apenas a URL do arquivo, o que evita inflar as tabelas com binários e simplifica a exibição das imagens no cliente |
| Login e segurança | JWT, bcrypt, Passport | Identificação segura do usuário e proteção de senhas | A combinação de JWT, bcrypt e Passport foi escolhida por permitir a implementação de autenticação segura mantendo o controle da lógica de acesso dentro do próprio *backend*. Essa abordagem se mostrou adequada ao contexto da aplicação, que utiliza uma API REST consumida por um aplicativo móvel, evitando a dependência de serviços externos de autenticação |
| Login com Google | Google Sign-In / OAuth | Entrada no aplicativo com conta Google, sem criar nova senha | Em comparação com cadastro apenas por e-mail e senha, o login com Google reduz etapas iniciais e diminui o risco de abandono no primeiro acesso. Isso se alinha ao objetivo do projeto de facilitar o uso contínuo do aplicativo |
| E-mail | Nodemailer (SMTP) | Envio de mensagens para verificação de conta e recuperação de senha | O Nodemailer foi adotado por integrar-se facilmente ao NestJS e atender às necessidades básicas do projeto, permitindo a verificação de conta e a recuperação de senha sem exigir infraestrutura adicional |
| Inteligência artificial | Google Gemini | Análise de fotos de alimentos e estimativa de calorias e nutrientes | O Google Gemini foi escolhido por possibilitar a análise de imagens de alimentos sem a necessidade de desenvolvimento e treinamento de um modelo próprio de visão computacional, em linha com a delimitação do estudo. Além disso, sua capacidade de retornar informações estruturadas e sua integração com o *backend* facilitaram sua aplicação na estimativa de calorias e nutrientes a partir das imagens capturadas pelos usuários |
| Tabela nutricional | TACO (4ª edição) | Base oficial brasileira de composição dos alimentos para refinar estimativas | A base TACO foi escolhida por apresentar informações nutricionais de alimentos presentes no contexto brasileiro, tornando-se mais adequada ao público-alvo da aplicação. Sua utilização permitiu complementar as estimativas geradas pela Inteligência Artificial com dados de uma referência nacional de composição de alimentos |
| Metas calóricas | Equação de Mifflin-St Jeor | Cálculo da meta diária de calorias e macronutrientes | A equação proposta por Mifflin et al. (1990), apresentada no Capítulo 2, foi adotada para estimar o gasto energético em repouso a partir de peso, altura, idade e sexo, mantendo consistência com a fundamentação teórica do trabalho |
| Integração contínua | GitHub Actions, Docker | Empacotamento e publicação automática de *frontend* e *backend* | A publicação automática a cada integração na ramificação principal reduz o esforço operacional e sustenta os ciclos de construção, uso e refinamento previstos pela ADR |
| Captura de imagem | Câmera, seletor de imagens e otimização JPEG | Entrada principal do reconhecimento alimentar | A foto é redimensionada e recodificada antes do envio, reduzindo o volume transmitido e o tempo de inferência sem impedir a identificação visual dos alimentos |
| Instrumentação de uso | Eventos de *analytics* | Registro de pedido, sucesso e falha da análise, além de telas visitadas | A instrumentação atende à avaliação descrita na Seção 4.1, permitindo relacionar o uso efetivo da aplicação às percepções dos participantes |

Fonte: Elaboração própria (2026).

A *stack* reflete restrições do TCC: não treinar um classificador próprio de larga escala; fundamentar calorias em referência nacional; e manter o sistema disponível durante o período de uso. Tecnologias de propósito geral foram preferidas a *frameworks* experimentais, a fim de reduzir o risco de entrega do artefato.

## 4.2.5 Fluxo de reconhecimento alimentar com Inteligência Artificial e tabela TACO

O registro de uma refeição com auxílio de IA no aplicativo desenvolvido é composto por cinco etapas, sendo elas a captura da imagem, análise da Inteligência Artificial, refinamento dos dados nutricionais, cálculo das metas calóricas e confirmação do registro. O desenho separa duas preocupações. A visão computacional identifica o que está no prato e estima a porção em gramas. A TACO, quando há correspondência, define energia e macronutrientes por 100 g. Essa separação evita que o modelo generativo seja, ao mesmo tempo, único juiz da composição nutricional — ponto alinhado à delimitação de não substituir acompanhamento profissional e à recomendação, extraída do Capítulo 3, de ancorar informações em referências reconhecidas pela área da nutrição.

A TACO utilizada é a 4ª edição da Tabela Brasileira de Composição de Alimentos (NEPA/UNICAMP, 2011), carregada no PostgreSQL. Cada registro oferece descrição, categoria, energia (kcal) e macronutrientes (proteína, carboidrato e lipídeos) por 100 g.

### 4.2.5.1 Captura e envio da imagem

O usuário tira uma foto da refeição ou seleciona uma imagem da galeria. Também é possível informar a refeição por texto livre — inclusive a partir de um rótulo nutricional — ou reutilizar uma refeição previamente salva. No caso de foto, o aplicativo redimensiona a imagem, recodifica-a em JPEG e a converte para um formato de texto (Base64) adequado ao envio pela internet, encaminhando-a ao servidor de forma autenticada. Se o serviço de IA estiver sobrecarregado ou temporariamente indisponível, o aplicativo exibe uma mensagem explicativa ao usuário.

### 4.2.5.2 Reconhecimento dos alimentos por Inteligência Artificial

No servidor, a imagem é enviada ao modelo de IA Google Gemini, configurado com instruções específicas para identificar alimentos do contexto brasileiro e estimar quantidades em gramas, calorias e macronutrientes. O modelo retorna os resultados em formato estruturado (JSON, padrão de organização de dados legível por programas). A cadeia percorre modelos da família Flash, com *fallback* em caso de sobrecarga ou esgotamento de tempo, de modo a degradar com graça sob cota e não bloquear o registro.

Se a mesma foto já tiver sido analisada pelo mesmo usuário, o resultado em cache é reenriquecido com a TACO atual, sem nova inferência visual. Se o usuário corrigir algum alimento identificado incorretamente, o sistema reenvia apenas os itens ajustados para novo cálculo, sem exigir que o usuário preencha todos os dados manualmente.

### 4.2.5.3 Refinamento com a tabela TACO

Após a análise da IA, um serviço complementar consulta a tabela TACO para refinar os valores calóricos. Para cada alimento identificado, o sistema realiza, em ordem: (1) se o usuário informou tabela nutricional, aplica-se a proporção entre a quantidade consumida e a porção de referência; (2) busca-se uma correspondência direta na TACO, favorecendo preparos e cortes compatíveis e rejeitando conflito entre formas crua e cozida; (3) caso o alimento seja uma preparação composta, sua composição é estimada a partir de ingredientes disponíveis na TACO; (4) se não houver uma correspondência adequada, os valores estimados pelo modelo de IA são preservados e marcados como estimativa. Com o casamento na tabela, calorias e macronutrientes vêm de (valor por 100 g × gramas) / 100.

### 4.2.5.4 Cálculo de metas calóricas

As metas diárias de calorias e macronutrientes são calculadas com base nas informações indicadas no cadastro inicial, que podem ser editadas posteriormente. O sistema aplica a equação proposta por Mifflin et al. (1990) para estimar a energia que o corpo gasta em repouso, ajusta esse valor conforme o nível de atividade física e modifica o resultado de acordo com o objetivo do usuário (perder peso, manter peso ou ganhar massa muscular).

### 4.2.5.5 Confirmação e armazenamento

Depois que o usuário revisa e confirma os dados, a refeição é salva no banco de dados. A foto, se existir, é enviada ao armazenamento, e a API persiste título, totais, tipo, horário, URL e os itens. Essa informação alimenta a tela principal do dia, o histórico de desempenho, o progresso nas missões e as estatísticas sociais.

Três propriedades desse fluxo merecem registro metodológico. Primeiro, o humano permanece no ciclo: a automação reduz o esforço de partida, mas a persistência é deliberada, o que mitiga erros de visão e de porção. Segundo, a TACO funciona como camada de fundamentação nutricional, e não como classificador visual — coerente com a delimitação de não treinar base própria de larga escala. Terceiro, cache, *fallback* de modelos e recálculo sem visão tornam o recurso utilizável no cotidiano de 30 dias, condição necessária para avaliar engajamento, e não apenas a acurácia pontual de um modelo.

## 4.2.6 Síntese

A metodologia de software deste trabalho articula três camadas. No nível da pesquisa, a DSR justifica a construção de um artefato para uma classe de problema — o registro alimentar com alto atrito — e a ADR explica a evolução desse artefato em ciclos de construção, uso e avaliação. No nível da engenharia, o desenvolvimento foi dividido em planejamento, análise de requisitos, diagramas, design, codificação, testes e *deploy*, executados de forma incremental, sem reproduzir neste capítulo os artefatos intermediários de cada etapa. No nível da solução, a arquitetura cliente–servidor, a *stack* da Tabela 7 e o fluxo de reconhecimento com IA e TACO materializam os objetivos específicos de reconhecimento, gamificação e interação social.

O Capítulo 5 apresenta o artefato em funcionamento e os resultados obtidos com os participantes. A discussão do Capítulo 6 interpreta esses resultados à luz das questões de pesquisa formuladas na Seção 1.3.

---

## Referências a incluir no capítulo de referências

HEVNER, A. R. et al. Design science in information systems research. *MIS Quarterly*, v. 28, n. 1, p. 75–105, 2004.

LACERDA, D. P.; DRESCH, A.; PROENÇA, A.; ANTUNES JÚNIOR, J. A. V. Design Science Research: método de pesquisa para a engenharia de produção. *Gestão & Produção*, v. 20, n. 4, p. 741–761, 2013. Disponível em: https://doi.org/10.1590/S0104-530X2013005000014. Acesso em: 24 ago. 2026.

NEPA – NÚCLEO DE ESTUDOS E PESQUISAS EM ALIMENTAÇÃO. *Tabela brasileira de composição de alimentos – TACO*. 4. ed. rev. e ampl. Campinas: NEPA/UNICAMP, 2011.

PEFFERS, K. et al. A design science research methodology for information systems research. *Journal of Management Information Systems*, v. 24, n. 3, p. 45–77, 2007.

SCHACHT, S.; MORANA, S.; MAEDCHE, A. The evolution of design principles enabling knowledge reuse for projects: an Action Design Research project. *Journal of Information Technology Theory and Application*, v. 16, n. 3, article 2, 2015.

SEIN, M. K. et al. Action design research. *MIS Quarterly*, v. 35, n. 1, p. 37–56, 2011.
