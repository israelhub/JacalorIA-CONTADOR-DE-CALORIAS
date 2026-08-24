# 4.2 Metodologia de software

Com o intuito de contribuir para a redução do atrito no registro alimentar digital, este trabalho adotou, na construção do artefato computacional, uma metodologia inspirada nos modelos de *Action Design Research* (ADR) e *Design Science Research* (DSR) (LACERDA et al., 2013; SCHACHT et al., 2015). As estratégias foram adaptadas para o contexto específico do projeto, visando não apenas a construção de uma aplicação tecnológica, mas também a sua validação em um contexto prático, conforme o estudo descrito na Seção 4.1.

O artefato resultante denomina-se JacalorIA: uma aplicação multiplataforma para reconhecimento de alimentos por imagem, controle da ingestão calórica, gamificação e interação social. A presente seção descreve a abordagem de pesquisa que orientou o desenvolvimento, as etapas de engenharia percorridas, a arquitetura do sistema, a *stack* tecnológica adotada e o fluxo de reconhecimento alimentar com Inteligência Artificial ancorado na Tabela Brasileira de Composição de Alimentos (TACO).

## 4.2.1 Abordagem de pesquisa: Design Science Research e Action Design Research

A *Design Science Research* caracteriza-se como um método voltado à produção de conhecimento científico por meio da concepção, construção e avaliação de artefatos capazes de resolver classes de problemas (HEVNER et al., 2004; LACERDA et al., 2013). Diferentemente de abordagens exclusivamente descritivas, a DSR reconhece que o conhecimento emerge tanto do artefato quanto da evidência de que ele é útil no ambiente para o qual foi projetado. Hevner et al. (2004) situam essa lógica no campo dos sistemas de informação, e Peffers et al. (2007) a operacionalizam em um processo com identificação do problema, definição dos objetivos da solução, projeto e desenvolvimento, demonstração, avaliação e comunicação.

Neste trabalho, a classe de problemas corresponde ao registro alimentar digital de elevado esforço, associado ao abandono precoce das aplicações, conforme discutido nos Capítulos 1 e 2. O artefato é o JacalorIA. A demonstração ocorre pela disponibilização do protótipo em produção. A avaliação segue o protocolo da Seção 4.1, com uso da aplicação por participantes durante 30 dias. A comunicação materializa-se neste TCC.

A *Action Design Research*, por sua vez, complementa a DSR ao reconhecer que artefatos de tecnologia da informação são moldados no contexto de intervenção, e não apenas em laboratório (SEIN et al., 2011; SCHACHT et al., 2015). O ciclo central da ADR é o BIE (*Building, Intervention and Evaluation*): constrói-se o artefato, coloca-se em uso e avalia-se o resultado para alimentar o ciclo seguinte. Sein et al. (2011) argumentam que construir, intervir e avaliar são atividades entrelaçadas, e não fases estanques. Schacht, Morana e Maedche (2015) ilustram essa condução em um projeto de sistemas de informação, evidenciando que princípios de projeto evoluem à medida que o artefato é confrontado com o uso real.

A adaptação dessas abordagens ao JacalorIA ocorreu da seguinte forma. A DSR organizou o trabalho no nível da pesquisa: o problema foi delimitado, os objetivos da solução foram definidos, o artefato foi projetado e desenvolvido, e a avaliação empírica foi planejada para verificar a utilidade da proposta. A ADR organizou a evolução incremental do software: autenticação e metas calóricas, reconhecimento alimentar com a TACO, gamificação, interação social e infraestrutura de produção constituíram ciclos de construção, uso interno e refinamento, antes da intervenção com os participantes. Assim, o desenvolvimento não se restringiu à implementação isolada de funcionalidades; cada incremento foi tratado como uma hipótese de projeto a ser ajustada.

Essa combinação justifica-se pelo caráter aplicado do TCC. Era necessário um enquadramento que legitimasse a construção do software como atividade de pesquisa (DSR) e, ao mesmo tempo, reconhecesse que decisões de interface, de reconhecimento nutricional e de engajamento só se estabilizam quando o artefato é efetivamente utilizado (ADR). A Seção 4.1 descreve a avaliação situada; as subseções seguintes descrevem como o software foi construído para tornar essa avaliação possível.

## 4.2.2 Etapas de desenvolvimento

Embora a DSR e a ADR definam o enquadramento da pesquisa, a construção do software exigiu um processo de engenharia. O desenvolvimento foi conduzido de forma iterativa e incremental: as etapas clássicas de planejamento, análise de requisitos, diagramas, design, codificação, testes e *deploy* ocorreram em cada ciclo, e não em uma única passagem sequencial. Essa condução é coerente com a ADR, na qual o artefato se esclarece à medida que é usado, e com a delimitação do estudo, que prevê um protótipo funcional — e não um sistema clínico de nutrição.

O processo foi organizado nas etapas a seguir. Os artefatos intermediários produzidos em cada uma delas — documentos de requisitos, diagramas e especificações detalhadas — subsidiaram o desenvolvimento internamente, mas não são reproduzidos neste capítulo, cuja finalidade é descrever o método, e não o catálogo completo da solução. O Capítulo 5 apresenta o artefato em funcionamento.

- **Planejamento.** Partiu-se dos objetivos específicos e da delimitação do estudo. Definiu-se construir um cliente multiplataforma, concentrar as regras de negócio em uma API REST e apoiar-se em serviços gerenciados para persistência, mídia e implantação, de modo a disponibilizar a aplicação aos participantes no prazo do estudo. O escopo foi organizado em domínios — autenticação e *onboarding*, registro de refeições, reconhecimento alimentar, desempenho, missões, interação social, notificações e observabilidade — o que antecipou a modularização posterior.

- **Análise de requisitos.** Os requisitos foram extraídos dos objetivos do Capítulo 1, das barreiras identificadas no Capítulo 2 e das lacunas do mapeamento sistemático. Privilegiou-se reduzir o esforço de registro, manter o usuário no controle da confirmação nutricional e sustentar o uso por gamificação e interação social. Requisitos não funcionais — multiplataforma, autenticação, tempo de resposta da análise de imagem, HTTPS e instrumentação de uso — orientaram escolhas de arquitetura e de operação. O elenco detalhado desses requisitos permanece fora deste capítulo.

- **Diagramas.** Foram elaborados diagramas de casos de uso, de arquitetura lógica, de implantação e do fluxo de reconhecimento alimentar, além de um modelo relacional das entidades persistidas. Esses diagramas cumpriram a função de comunicar o desenho da solução entre os autores e de orientar a implementação; sua especificação gráfica e o detalhamento das entidades não são reproduzidos aqui.

- **Design.** O desenho privilegiou baixo acoplamento entre interface, regras de negócio e provedores externos. No cliente, a organização é por funcionalidade. No servidor, cada domínio constitui um módulo da API. O reconhecimento alimentar foi separado em visão computacional e enriquecimento nutricional pela TACO, com revisão humana obrigatória antes da persistência. As metas calóricas aplicam a equação de Mifflin-St Jeor, apresentada no Capítulo 2. A gamificação foi concebida como economia de ouro e experiência, e as mídias (fotos de refeição, avatares e imagens de conversa) foram desacopladas do banco relacional.

- **Codificação.** A implementação utilizou Dart no cliente e TypeScript no servidor, com Git como controle de versão. Senhas são armazenadas com *hash*, sessões utilizam *JSON Web Token* (JWT) e entradas da API são validadas de forma sistemática. Alterações de esquema do banco foram versionadas em migrações SQL, o que permitiu evoluir o modelo de dados entre os ciclos sem recriar o ambiente a cada incremento.

- **Testes.** Os testes automatizados acompanharam as regras de maior risco: cálculo de metas, correspondência com a TACO, revisão da refeição, captura e as superfícies de missões e de interação social. A suíte do cliente cobre páginas, componentes e ajudantes; no servidor, testes unitários exercitam o casamento textual de alimentos, incluindo preparo e cortes. A avaliação de uso contínuo com participantes pertence à Seção 4.1; os testes de regressão cumprem o papel de avaliação interna do artefato, prevista pela DSR (HEVNER et al., 2004).

- **Deploy.** A implantação é contínua. Um fluxo de integração dispara no envio à ramificação principal, empacota a API em imagem de contêiner, publica o cliente web em armazenamento de objetos e invalida a rede de distribuição de conteúdo. Interface e API compartilham o mesmo domínio sob HTTPS, condição necessária para o estudo de 30 dias. Aplicativos nativos reutilizam a mesma API.

## 4.2.3 Arquitetura do sistema

A arquitetura do JacalorIA é cliente–servidor, organizada em três camadas lógicas. A camada de apresentação é o aplicativo Flutter, executado na web, no Android e no iOS a partir de uma única base de interface. A camada de aplicação é uma API REST em NestJS, prefixada em `/api`, responsável pelas regras de autenticação, nutrição, missões, interação social e orquestração do reconhecimento alimentar. A camada de dados e serviços externos reúne o PostgreSQL e o armazenamento de arquivos no Supabase, os modelos multimodais da família Gemini para visão de alimentos e o envio de e-mails transacionais.

Essa organização concentra a lógica sensível no servidor, de modo que web e aplicativos nativos consumam o mesmo contrato JSON autenticado por *token* Bearer. O estilo interno da API é o de um monólito modular: um único processo HTTP, com fronteiras por domínio (autenticação, inteligência artificial, refeições, modelos de refeição, missões, social, desempenho, notificações, *analytics*, suporte, saúde da instância e correio). A escolha reduz o custo operacional do protótipo e simplifica transações que cruzam refeição, ofensiva e missões, sem impedir a extração futura de serviços.

Na implantação, o usuário acessa a aplicação em jacaloria.online. Uma rede de distribuição (Amazon CloudFront) entrega o cliente web a partir de um *bucket* S3 e encaminha as requisições `/api/*` ao *backend* hospedado no AWS Elastic Beanstalk. O PostgreSQL e o *Storage* permanecem no Supabase. A análise de imagens é uma invocação HTTPS ao provedor Gemini. O GitHub Actions atualiza *frontend* e *backend* a cada integração na ramificação principal, autenticando-se na AWS por OIDC, sem chaves de acesso estáticas.

Dois desacoplamentos merecem registro. O primeiro é o das mídias: fotos de refeição, avatares e imagens de conversa são gravados no *Storage*, e a API persiste apenas as URLs, o que evita inflar o banco com binários. O segundo é o do reconhecimento alimentar: a interface de provedor isola a chamada ao Gemini, e o enriquecimento pela TACO ocorre depois da inferência, o que permite trocar o modelo de visão sem alterar o restante da API. Ambos sustentam a evolução incremental prevista pela ADR.

## 4.2.4 Stack tecnológica

A Tabela 7 consolida as ferramentas e tecnologias adotadas, a função de cada componente e a justificativa de uso, conforme implementado no repositório do JacalorIA.

**Tabela 7 — Stack tecnológica do JacalorIA: componentes, função e justificativa**

| Componente | Função | Justificativa de uso |
| --- | --- | --- |
| Flutter / Dart | Interface do usuário em Android, iOS e web | Uma base de interface para o estudo multiplataforma, com componentes e testes de tela maduros |
| NestJS / TypeScript | API REST modular (`/api`) | Organização por módulos, injeção de dependências e validação de entradas alinhadas a um protótipo que cresce por incrementos |
| PostgreSQL (Supabase) | Persistência relacional de usuários, refeições, TACO, missões, social e eventos de uso | Integridade referencial, suporte a dados semiestruturados nos itens da análise e adequação à TACO tabular |
| Sequelize e migrações SQL | Mapeamento objeto–relacional e evolução do esquema | Modelos tipados no servidor com histórico explícito de alterações de banco |
| Supabase Storage | Arquivos públicos de avatar, foto de refeição e conversa | Persistência de mídia desacoplada da API, com URL estável no registro da refeição |
| Google Gemini (visão), família Flash | Identificação de alimentos e estimativa visual de porção | Modelo multimodal capaz de descrever pratos a partir de foto, sem treinar rede própria, em linha com a delimitação do estudo |
| Tabela TACO (4ª edição) | Referência de energia e macronutrientes por 100 g | Fonte brasileira consolidada; reduz a dependência da estimativa livre da IA |
| JWT, Passport e bcrypt | Sessão *stateless* e proteção de senha | Padrão de API compatível com web e aplicativos nativos |
| Google Sign-In | Autenticação alternativa | Reduz o atrito no cadastro dos participantes |
| Nodemailer | Verificação de e-mail e recuperação de senha | Fluxo de conta completo sem provedor de identidade exclusivo |
| Equação de Mifflin-St Jeor | Meta calórica e macronutrientes diários | Consistência com a fundamentação teórica do Capítulo 2 |
| GitHub Actions | Integração e entrega contínuas de *frontend* e *backend* | Republicação automática a cada incremento, necessária aos ciclos da ADR |
| Docker (Node.js 22) | Empacotamento reproduzível da API | Mesmo artefato em desenvolvimento e em produção |
| Amazon ECR | Registro das imagens da API | Alimenta o Elastic Beanstalk a cada publicação |
| AWS Elastic Beanstalk | Execução da API em contêiner | Operação simplificada para o protótipo acadêmico |
| Amazon S3 | Hospedagem do Flutter Web | Conteúdo estático com integração nativa à rede de distribuição |
| Amazon CloudFront e certificado TLS | HTTPS, mesma origem e *proxy* `/api/*` | Evita conteúdo misto e acomoda o tempo da análise de alimentos |
| OIDC (GitHub → AWS) | Autenticação do *pipeline* de publicação | Evita chaves de acesso de longa duração |
| Câmera, seletor de imagens e otimização JPEG | Captura e redução da foto antes do envio | Entrada principal do reconhecimento; reduz o volume transmitido e o tempo de inferência |
| Testes Flutter e testes unitários em Node | Regressão de interface, metas e casamento com a TACO | Protege regras críticas entre ciclos de desenvolvimento |
| Eventos de *analytics* | Medição de uso (pedido, sucesso e falha da IA, telas) | Instrumentação exigida pela avaliação da Seção 4.1 |

Fonte: Elaboração própria (2026).

A *stack* reflete restrições do TCC: não treinar um classificador próprio de larga escala; fundamentar calorias em referência nacional; e manter o sistema disponível durante o período de uso. Tecnologias de propósito geral foram preferidas a *frameworks* experimentais, a fim de reduzir o risco de entrega do artefato.

## 4.2.5 Fluxo de reconhecimento alimentar com Inteligência Artificial e tabela TACO

O reconhecimento alimentar materializa o primeiro objetivo específico: reduzir a dependência de inserções manuais. O desenho separa duas preocupações. A visão computacional identifica o que está no prato e estima a porção em gramas. A TACO, quando há correspondência, define energia e macronutrientes por 100 g. Essa separação evita que o modelo generativo seja, ao mesmo tempo, único juiz da composição nutricional — ponto alinhado à delimitação de não substituir acompanhamento profissional e à recomendação, extraída do Capítulo 3, de ancorar informações em referências reconhecidas pela área da nutrição.

A TACO utilizada é a 4ª edição da Tabela Brasileira de Composição de Alimentos (NEPA/UNICAMP, 2011), carregada no PostgreSQL. Cada registro oferece descrição, categoria, energia (kcal) e macronutrientes (proteína, carboidrato e lipídeos) por 100 g. O serviço mantém a tabela em cache de memória por intervalo curto, de modo a não relê-la a cada requisição.

O usuário inicia o registro por câmera, galeria, texto livre — inclusive rótulo nutricional — ou refeição previamente salva. No caso de foto, o cliente redimensiona a imagem e a recodifica em JPEG antes do envio, equilibrando fidelidade visual e custo de transmissão. Em seguida, autentica a chamada à API de análise com JWT. O corpo da requisição contém a imagem, o texto manual ou, no recálculo, a lista de itens já revisados.

No servidor, análises apenas de imagem geram um identificador do conteúdo. Se o mesmo usuário já analisou a mesma foto, o resultado em cache é reenriquecido com a TACO atual, sem nova inferência visual. Requisições idênticas em andamento são deduplicadas. Na ausência de cache, dispara-se o provedor Gemini.

O provedor envia a imagem ou o texto com instruções para atuar como analista de refeições brasileiras: nomear o alimento com preparo e corte quando visíveis, estimar gramas e, na presença de rótulo, extrair a porção de referência sem calcular a proporção — o sistema o fará. A cadeia percorre modelos da família Flash, com *fallback* em caso de sobrecarga ou esgotamento de tempo, de modo a degradar com graça sob cota e não bloquear o registro.

A resposta da IA descreve itens, totais e uma justificativa breve. O enriquecimento nutricional percorre cada item nesta ordem de prioridade:

1. **Rótulo informado.** Se o usuário forneceu tabela nutricional, aplica-se a proporção entre a quantidade consumida e a porção de referência. Essa fonte tem prioridade máxima.
2. **Correspondência TACO.** Normaliza-se o nome do alimento e busca-se o melhor registro da tabela acima de um limiar de similaridade. O algoritmo favorece preparos e cortes compatíveis e rejeita conflito entre formas crua e cozida. Com o casamento, calorias e macronutrientes vêm de (valor por 100 g × gramas) / 100. A descrição original da TACO é devolvida à interface.
3. **Decomposição de receita.** Pratos compostos sem linha direta na tabela são aproximados por receitas-padrão cujos ingredientes, uma vez casados na TACO, são ponderados.
4. **Estimativa da IA.** Se nenhuma âncora se aplica, preservam-se os valores do modelo, explicitamente marcados como estimativa.

Os totais da refeição são a soma dos itens já enriquecidos. Na tela de revisão, o usuário altera nome, porção e tipo de refeição (café, almoço, jantar ou livre). Ao confirmar, o cliente chama novamente a API apenas com os itens editados; o servidor reaplica a TACO sem nova inferência visual. A foto, se existir, é enviada ao armazenamento; a API persiste título, totais, tipo, horário, URL e os itens. Só então a refeição entra no saldo do dia, na ofensiva e nas missões.

Três propriedades desse fluxo merecem registro metodológico. Primeiro, o humano permanece no ciclo: a automação reduz o esforço de partida, mas a persistência é deliberada, o que mitiga erros de visão e de porção. Segundo, a TACO funciona como camada de fundamentação nutricional, e não como classificador visual — coerente com a delimitação de não treinar base própria de larga escala. Terceiro, cache, *fallback* de modelos e recálculo sem visão tornam o recurso utilizável no cotidiano de 30 dias, condição necessária para avaliar engajamento, e não apenas a acurácia pontual de um modelo.

## 4.2.6 Síntese

A metodologia de software deste trabalho articula três camadas. No nível da pesquisa, a DSR justifica a construção de um artefato para uma classe de problema — o registro alimentar com alto atrito — e a ADR explica a evolução desse artefato em ciclos de construção, uso e avaliação. No nível da engenharia, o desenvolvimento foi dividido em planejamento, análise de requisitos, diagramas, design, codificação, testes e *deploy*, executados de forma incremental. No nível da solução, a arquitetura cliente–servidor, a *stack* da Tabela 7 e o fluxo de reconhecimento com IA e TACO materializam os objetivos específicos de reconhecimento, gamificação e interação social.

O Capítulo 5 apresenta o artefato em funcionamento e os resultados obtidos com os participantes. A discussão do Capítulo 6 interpreta esses resultados à luz das questões de pesquisa formuladas na Seção 1.3.

---

## Referências a incluir no capítulo de referências

HEVNER, A. R. et al. Design science in information systems research. *MIS Quarterly*, v. 28, n. 1, p. 75–105, 2004.

LACERDA, D. P.; DRESCH, A.; PROENÇA, A.; ANTUNES JÚNIOR, J. A. V. Design Science Research: método de pesquisa para a engenharia de produção. *Gestão & Produção*, v. 20, n. 4, p. 741–761, 2013. Disponível em: https://doi.org/10.1590/S0104-530X2013005000014. Acesso em: 24 ago. 2026.

NEPA – NÚCLEO DE ESTUDOS E PESQUISAS EM ALIMENTAÇÃO. *Tabela brasileira de composição de alimentos – TACO*. 4. ed. rev. e ampl. Campinas: NEPA/UNICAMP, 2011.

PEFFERS, K. et al. A design science research methodology for information systems research. *Journal of Management Information Systems*, v. 24, n. 3, p. 45–77, 2007.

SCHACHT, S.; MORANA, S.; MAEDCHE, A. The evolution of design principles enabling knowledge reuse for projects: an Action Design Research project. *Journal of Information Technology Theory and Application*, v. 16, n. 3, article 2, 2015.

SEIN, M. K. et al. Action design research. *MIS Quarterly*, v. 35, n. 1, p. 37–56, 2011.
