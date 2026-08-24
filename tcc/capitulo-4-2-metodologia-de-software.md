# 4.2 Metodologia de software

A metodologia de software descreve como o artefato deste trabalho — a aplicação JacalorIA — foi concebido, projetado, implementado, testado e implantado. Enquanto a Seção 4.1 define os procedimentos de avaliação com participantes, esta seção trata da construção da solução computacional. A abordagem combina *Design Science Research* (DSR) e *Action Design Research* (ADR) com um processo de engenharia de software iterativo, percorrendo planejamento, análise de requisitos, diagramas, design, codificação, testes e *deploy*.

O nome JacalorIA identifica o protótipo funcional desenvolvido: um cliente multiplataforma em Flutter, uma API REST em NestJS, persistência em PostgreSQL, armazenamento de mídias no Supabase Storage e reconhecimento de alimentos por modelos multimodais da família Gemini, com valores nutricionais ancorados na Tabela Brasileira de Composição de Alimentos (TACO).

## 4.2.1 Abordagem de pesquisa para o desenvolvimento: Design Science Research e Action Design Research

O desenvolvimento da aplicação adota a *Design Science Research* como paradigma de construção do artefato e a *Action Design Research* como forma de conduzir essa construção de maneira iterativa, em contato com o problema real de uso.

Hevner et al. (2004) caracterizam a DSR como a pesquisa em sistemas de informação voltada à criação de artefatos — modelos, métodos ou instâncias de sistemas — capazes de resolver classes de problemas organizacionais e sociais. O conhecimento científico emerge tanto do artefato quanto da avaliação de sua utilidade. Peffers et al. (2007) operacionalizam essa lógica em um processo com identificação do problema, definição dos objetivos da solução, projeto e desenvolvimento, demonstração, avaliação e comunicação. No presente trabalho, o problema corresponde ao atrito do registro alimentar digital, discutido no Capítulo 2; o artefato é o JacalorIA; a demonstração ocorre pelo protótipo em produção; e a avaliação segue o estudo descrito na Seção 4.1.

A ADR, proposta por Sein et al. (2011), complementa a DSR ao reconhecer que artefatos de TI são moldados no contexto de intervenção, e não apenas em laboratório. O ciclo central da ADR é o BIE (*Building, Intervention and Evaluation*): constrói-se o artefato, coloca-se em uso e avalia-se o resultado para alimentar o próximo ciclo. No JacalorIA, cada incremento (autenticação e metas, reconhecimento alimentar, gamificação, interação social e infraestrutura de produção) constituiu um ciclo BIE. A intervenção prevista com 20 participantes durante 30 dias, com coleta de logs e questionário anônimo, corresponde à etapa de avaliação situada da ADR e se articula com a metodologia de pesquisa da Seção 4.1.

A Tabela 7 relaciona as etapas da DSR segundo Peffers et al. (2007) às atividades realizadas neste trabalho.

**Tabela 7 — Correspondência entre as etapas da DSR e as atividades deste trabalho**

| Etapa da DSR (Peffers et al., 2007) | Atividade neste trabalho |
| --- | --- |
| Identificação do problema e motivação | Síntese das barreiras de registro manual e abandono em aplicativos alimentares (Capítulos 1 e 2) e mapeamento sistemático (Capítulo 3) |
| Definição dos objetivos da solução | Objetivos geral e específicos: reconhecimento por imagem, gamificação, interação social e análise de engajamento |
| Projeto e desenvolvimento | Arquitetura cliente–servidor, módulos da API, fluxo IA + TACO, economia de missões e funcionalidades sociais |
| Demonstração | Protótipo implantado em jacaloria.online, com versões web e móveis |
| Avaliação | Estudo de 30 dias com 20 participantes, métricas de uso persistidas no banco e questionário no Microsoft Forms |
| Comunicação | Presente TCC, que documenta o artefato, as decisões de projeto e os resultados |

Fonte: Elaboração própria (2026), com base em Peffers et al. (2007).

A Figura 1 sintetiza essa integração: o ciclo DSR organiza o trabalho no nível da pesquisa, enquanto os ciclos BIE da ADR organizam a evolução incremental do software.

**Figura 1 — Integração entre Design Science Research e Action Design Research no desenvolvimento do JacalorIA**

Fonte: Elaboração própria (2026), com base em Peffers et al. (2007) e Sein et al. (2011).

## 4.2.2 Processo e etapas de desenvolvimento

Embora a DSR e a ADR definam o enquadramento da pesquisa, a construção do software exigiu um processo de engenharia. Sommerville (2018) observa que processos iterativos e incrementais são adequados quando os requisitos se esclarecem à medida que o artefato é usado. Foi essa a condução adotada: as etapas clássicas — planejamento, análise de requisitos, diagramas, design, codificação, testes e *deploy* — ocorreram em cada incremento, e não em uma única passagem sequencial do tipo cascata.

A Figura 2 apresenta as etapas e os incrementos principais. O Incremento 1 estabeleceu contas, perfil e metas calóricas. O Incremento 2 implementou o registro de refeições e o reconhecimento por IA com a TACO. O Incremento 3 introduziu missões, loja, ofensiva (*streak*) e interação social. O Incremento 4 consolidou a esteira de integração contínua, o ambiente de produção e refinamentos de experiência.

**Figura 2 — Etapas do desenvolvimento do JacalorIA em execução iterativa**

Fonte: Elaboração própria (2026).

### 4.2.2.1 Planejamento

O planejamento partiu dos objetivos específicos e da delimitação do estudo. Decidiu-se construir um protótipo funcional, e não um modelo clínico de nutrição, o que orientou três escolhas estruturais.

A primeira foi a adoção de um cliente multiplataforma em Flutter, de modo a atender web, Android e iOS a partir de uma única base de interface. A segunda foi concentrar regras de negócio em uma API REST modular em NestJS, evitando duplicar lógica sensível — autenticação, cálculo nutricional, correspondência com a TACO, missões e social — em cada cliente. A terceira foi apoiar-se em serviços gerenciados para persistência e mídia (Supabase) e para implantação (Amazon Web Services), compatível com o caráter de protótipo acadêmico e com a necessidade de disponibilizar a aplicação aos participantes do estudo.

O escopo funcional foi organizado em domínios: autenticação e onboarding; registro e acompanhamento de refeições; reconhecimento alimentar; desempenho e peso; missões e loja; interação social; notificações; e observabilidade (saúde da API e eventos de *analytics*). Essa divisão antecipou a modularização posterior do *backend* e a organização por *features* no *frontend*.

### 4.2.2.2 Análise de requisitos

Os requisitos foram extraídos dos objetivos do Capítulo 1, das barreiras identificadas no Capítulo 2 e das lacunas do mapeamento sistemático. Privilegiou-se reduzir o esforço de registro, manter o usuário no controle da confirmação nutricional e sustentar o uso por gamificação e interação social. A Tabela 8 consolida os requisitos funcionais implementados no protótipo.

**Tabela 8 — Requisitos funcionais do JacalorIA**

| ID | Requisito | Origem |
| --- | --- | --- |
| RF01 | Cadastrar, autenticar e recuperar conta (e-mail e senha, Google e verificação por código) | Objetivo geral; segurança de acesso |
| RF02 | Coletar dados de onboarding (sexo, peso, altura, idade, objetivo e nível de atividade) e calcular metas diárias | Fundamentação: Mifflin-St Jeor e GET |
| RF03 | Registrar refeição por foto (câmera ou galeria), texto livre/rótulo ou refeição salva | Objetivo específico de reduzir inserção manual |
| RF04 | Identificar alimentos na imagem ou no texto e estimar porção, calorias e macronutrientes | Reconhecimento por IA |
| RF05 | Ancorar calorias e macros na TACO sempre que houver correspondência confiável | Referência nutricional brasileira |
| RF06 | Permitir revisão, edição e recálculo antes de persistir a refeição | Controle do usuário; mitigação de erro da IA |
| RF07 | Exibir ingestão do dia contra a meta (calorias e macros) e histórico de desempenho/peso | Controle da ingestão calórica |
| RF08 | Oferecer missões diárias, semanais, mensais e de fim de semana, com ouro, XP, ofensiva e loja (molduras, fundos, emojis e protetores de ofensiva) | Objetivo específico de gamificação |
| RF09 | Permitir amizades, grupos, chat, reações, ranking de XP e visualização controlada de refeições | Objetivo específico de interação social |
| RF10 | Enviar lembretes de refeição, mensagens in-app e canal de suporte | Redução de abandono; operação do estudo |

Fonte: Elaboração própria (2026).

Os requisitos não funcionais (Tabela 9) orientaram decisões de arquitetura e de operação. Destacam-se autenticidade das sessões, tempo de resposta aceitável na análise de imagem, observabilidade do serviço de IA e capacidade de republicar o sistema a cada incremento.

**Tabela 9 — Requisitos não funcionais do JacalorIA**

| ID | Requisito | Como foi tratado |
| --- | --- | --- |
| RNF01 | Multiplataforma (web, Android e iOS) | Flutter com a mesma base de interface |
| RNF02 | Autenticação e autorização nas rotas sensíveis | JWT (Passport), guarda nas rotas `/api` protegidas |
| RNF03 | Validação de entrada na API | DTOs com `class-validator` e `ValidationPipe` (whitelist) |
| RNF04 | Tempo de análise de refeição previsível | Timeout total de 55 s no provedor, fallback de modelos, cache por hash da imagem e até duas tentativas no cliente |
| RNF05 | Volume de imagem compatível com a API | Redimensionamento até 1920 px e JPEG a 90% no cliente; limite de corpo de 10 MB |
| RNF06 | Disponibilidade e diagnóstico | Endpoint `/api/health`, métricas de infraestrutura e *deploy* automatizado |
| RNF07 | HTTPS e mesma origem entre front e API | CloudFront em jacaloria.online, com `/api/*` em proxy para o *backend* |
| RNF08 | Rastreabilidade de uso para o estudo | Eventos de *analytics* no cliente e no servidor |

Fonte: Elaboração própria (2026).

O ator principal é o usuário autenticado. Atores externos incluem o serviço de visão Gemini, a base TACO persistida no PostgreSQL e os serviços de nuvem (armazenamento, e-mail e entrega de conteúdo). A Figura 3 apresenta a visão consolidada dos casos de uso.

**Figura 3 — Diagrama de casos de uso do JacalorIA**

Fonte: Elaboração própria (2026).

### 4.2.2.3 Diagramas

Os diagramas cumpriram duas funções: comunicar o desenho da solução entre os autores e documentar o artefato neste TCC. Foram elaborados: (i) casos de uso (Figura 3); (ii) arquitetura lógica em camadas (Figura 4); (iii) arquitetura de implantação (Figura 5); e (iv) fluxo de reconhecimento alimentar com IA e TACO (Figura 6).

No nível de dados, o modelo relacional concentra-se nas entidades `users`, `meals`, `food_image_analyses`, missões e transações de moeda, amizades, grupos, mensagens, reações, lembretes e eventos de *analytics*. A tabela TACO permanece como base de consulta nutricional, distinta das refeições do usuário. O registro de refeição armazena totais, tipo (`breakfast`, `lunch`, `dinner` ou `free`), itens da análise em JSON e a URL da foto quando houver.

### 4.2.2.4 Design

O design privilegiou baixo acoplamento entre interface, regras de negócio e provedores externos.

No cliente, a organização é por funcionalidade (*feature-first*): `auth`, `onboarding`, `home`, `food_analysis`, `missions`, `performance`, `social`, `profile`, `reminders` e `support`, com widgets e tema compartilhados em `shared`. A navegação principal reúne Desempenho, Início, Missões e Social, com a captura de refeição no centro. O fluxo de análise foi desenhado com revisão humana obrigatória: a IA sugere, o usuário confirma.

No servidor, cada domínio é um módulo NestJS (controlador, serviço, DTOs e modelos Sequelize). O reconhecimento alimentar usa o padrão *Provider*: a interface `FoodAnalysisProvider` isola a chamada ao Gemini, o que permite trocar o modelo sem alterar o restante da API. Depois da inferência, o serviço `FoodNutritionRagService` reescreve calorias e macros com a TACO. O recálculo após edição do usuário reexecuta apenas o enriquecimento nutricional, sem nova chamada de visão.

As metas calóricas aplicam a equação de Mifflin-St Jeor (Capítulo 2) no cliente e no servidor, com fator de atividade e ajuste por objetivo (perda de peso, manutenção ou ganho de massa). A gamificação foi desenhada como economia de ouro e XP, com missões de cadências distintas para hábito diário, compromisso semanal e clímax mensal. A persistência de fotos de refeição, avatares e imagens de chat ocorre no Storage, enquanto a API guarda apenas as URLs.

### 4.2.2.5 Codificação

A implementação utilizou TypeScript no *backend* e Dart no *frontend*, com Git como controle de versão. No servidor, o prefixo global `/api`, o CORS configurável, o limite de corpo para imagens e a validação sistemática de DTOs reduzem superfícies de erro. Senhas são armazenadas com *hash* (bcrypt). A sessão usa JWT. E-mails de verificação e recuperação passam pelo Nodemailer.

No cliente, a captura usa a câmera nativa ou a galeria; o texto manual cobre rótulos nutricionais; refeições salvas evitam reanalisar pratos recorrentes. A imagem é otimizada em *isolate* (`compute`) antes do envio. Mensagens de erro da análise são traduzidas para linguagem de usuário (sobrecarga, *timeout*, rede), sem expor detalhes técnicos.

Alterações de esquema foram versionadas em arquivos SQL em `backend/migrations`, cobrindo, entre outros, análises de imagem, tipos de refeição, economia da loja, lembretes, privacidade do perfil público e reações no chat. Essa disciplina permitiu evoluir o banco entre os ciclos BIE sem recriar o ambiente a cada incremento.

### 4.2.2.6 Testes

Os testes acompanharam os requisitos de maior risco: cálculo de metas, correspondência com a TACO, revisão da refeição, captura e as telas sociais e de missões.

No *frontend*, a suíte Flutter cobre widgets, páginas e ajudantes — autenticação, onboarding, início, análise de alimentos, desempenho, missões, social, perfil, lembretes e o calculador nutricional. Casos de aceite incluem a exibição da etiqueta TACO quando `source` é `taco_db` e o recálculo após edição de itens. No *backend*, testes unitários exercitam o casamento textual de alimentos (`food-match.util`), incluindo preparo (cru versus cozido) e cortes, além de utilitários sociais.

Não se pretendeu cobertura exaustiva de ponta a ponta em dispositivos reais neste capítulo; a avaliação de uso contínuo pertence ao estudo da Seção 4.1. Os testes automatizados cumprem o papel de regressão a cada incremento, em linha com a diretriz da DSR de avaliar o artefato também internamente, antes da intervenção com participantes (HEVNER et al., 2004).

### 4.2.2.7 Deploy

A implantação é contínua. Um fluxo do GitHub Actions dispara no envio à ramificação principal. A autenticação na AWS ocorre por OIDC, sem chaves de acesso estáticas.

O *backend* é empacotado em imagem Docker de dois estágios (Node.js 22), enviada ao Amazon ECR e publicada no Elastic Beanstalk (ambiente de instância única, porta 3000). O *frontend* web é gerado com `flutter build web --release` e sincronizado em um *bucket* S3 privado, com invalidação do CloudFront. O mesmo distribuidor serve o site em `/*` e encaminha `/api/*` ao Elastic Beanstalk, de modo que interface e API compartilhem HTTPS e origem em jacaloria.online. O *timeout* da origem da API foi elevado para acomodar a análise de alimentos, que pode exceder os 30 segundos padrão do CloudFront.

O endpoint `/api/health` verifica o PostgreSQL e expõe sinais de processo, subsidiando o acompanhamento do ambiente durante o estudo. Aplicativos nativos reutilizam a mesma API; *deep links* (Android App Links e Apple Universal Links) são publicados em `/.well-known`.

## 4.2.3 Arquitetura do sistema

A arquitetura é cliente–servidor em três camadas lógicas: apresentação (Flutter), aplicação (NestJS) e dados/serviços externos (PostgreSQL, Storage, Gemini e e-mail). A Figura 4 apresenta essa organização.

**Figura 4 — Arquitetura lógica do JacalorIA**

Fonte: Elaboração própria (2026).

Na apresentação, o aplicativo consome a API JSON com token Bearer. A captura de refeição, a home com meta do dia, o calendário de desempenho, as missões e o social são clientes da mesma API, o que mantém coerência de estado entre as superfícies — requisito importante para o estudo de engajamento.

Na aplicação, a Tabela 10 resume os módulos e as responsabilidades. O estilo é o de um monólito modular: um único processo HTTP, com fronteiras internas claras. Essa escolha reduz custo operacional do protótipo e simplifica transações que cruzam refeição, ofensiva e missões, sem impedir a extração futura de serviços.

**Tabela 10 — Módulos da API NestJS e responsabilidades**

| Módulo | Responsabilidade |
| --- | --- |
| `auth` | Cadastro, login, Google, JWT, perfil, verificação de e-mail, recuperação de senha e cálculo de metas |
| `ai` | Análise de imagem/texto, cache de análises, cadeia Gemini e enriquecimento TACO |
| `meals` | Criação, listagem por período, atualização e exclusão lógica de refeições |
| `meal-templates` | Refeições salvas para reuso |
| `missions` | Missões, check-in, carteira, loja e transações de ouro/XP |
| `social` | Amizades, convites, grupos, chat, reações e ranking |
| `performance` | Histórico de peso e desempenho mensal |
| `notifications` | Lembretes de refeição e comunicados in-app |
| `analytics` | Eventos de uso e painel interno |
| `support` | Mensagens de suporte |
| `health` | Verificação de disponibilidade e métricas da instância |
| `mail` | Envio de e-mails transacionais |

Fonte: Elaboração própria (2026).

A Figura 5 descreve a implantação. O usuário acessa jacaloria.online (CloudFront). Conteúdo estático vem do S3; a API, do Elastic Beanstalk. O PostgreSQL e o Storage permanecem no Supabase. A visão de alimentos é invocação HTTPS ao Gemini. O GitHub Actions atualiza *front* e *back* a cada integração na ramificação principal.

**Figura 5 — Arquitetura de implantação do JacalorIA**

Fonte: Elaboração própria (2026).

Essa topologia atende aos RNF de HTTPS, mesma origem e republicação frequente. O desacoplamento entre mídia (Storage) e metadados (PostgreSQL) evita inflar o banco com binários e permite cache de imagens no cliente.

## 4.2.4 Stack tecnológica

A Tabela 11 consolida as ferramentas e tecnologias adotadas, a função de cada componente e a justificativa de uso, conforme implementado no repositório do JacalorIA.

**Tabela 11 — Stack tecnológica do JacalorIA: componentes, função e justificativa**

| Componente | Função | Justificativa de uso |
| --- | --- | --- |
| Flutter / Dart | Interface do usuário em Android, iOS e Web | Uma base de UI para o estudo multiplataforma; *widgets* e testes de interface maduros |
| NestJS / TypeScript | API REST modular (`/api`) | Organização por módulos, injeção de dependências e validação de DTOs alinhadas a um protótipo que cresce por incrementos |
| PostgreSQL (Supabase) | Persistência relacional (usuários, refeições, TACO, social, missões, *analytics*) | Integridade referencial, JSONB para itens da análise e adequação à TACO tabular |
| Sequelize + migrações SQL | Mapeamento objeto–relacional e evolução do esquema | Modelos tipados no NestJS com histórico explícito de alterações de banco |
| Supabase Storage | Arquivos públicos de avatar, foto de refeição e chat | Persistência de mídia desacoplada da API, com URL estável no registro da refeição |
| Google Gemini (visão), família Flash | Identificação de alimentos e estimativa visual de porção | Modelo multimodal capaz de descrever pratos a partir de foto, sem treinar rede própria (delimitação do estudo) |
| Tabela TACO (4ª edição) | Referência de kcal e macros por 100 g | Fonte brasileira consolidada; reduz dependência da estimativa “livre” da IA |
| JWT + Passport + bcrypt | Sessão e proteção de senha | Padrão de API stateless, compatível com web e aplicativos |
| Google Sign-In | Autenticação alternativa | Reduz atrito no onboarding dos participantes |
| Nodemailer | Verificação de e-mail e recuperação de senha | Fluxo de conta completo sem provedor de identidade exclusivo |
| Equação de Mifflin-St Jeor (cliente e API) | Meta calórica e macros diários | Consistência com a fundamentação teórica do Capítulo 2 |
| GitHub Actions | CI/CD de *frontend* e *backend* | Republicação automática a cada incremento, necessária aos ciclos BIE |
| Docker (Node.js 22, build em dois estágios) | Empacotamento reproduzível da API | Mesmo artefato em desenvolvimento e produção |
| Amazon ECR | Registro das imagens da API | Alimenta o Elastic Beanstalk a cada *deploy* |
| AWS Elastic Beanstalk | Execução da API em container | Operação simplificada para protótipo (instância única) |
| Amazon S3 | Hospedagem do Flutter Web | Estáticos com custo baixo e integração nativa ao CloudFront |
| Amazon CloudFront + certificado TLS | CDN, HTTPS e proxy `/api/*` | Mesma origem, HTTP/2-3 e *timeout* compatível com a análise de IA |
| OIDC (GitHub → AWS) | Autenticação do *pipeline* de *deploy* | Evita chaves de acesso de longa duração |
| Câmera / *image_picker* / pacote `image` | Captura e otimização da foto | Entrada principal do reconhecimento; reduz *payload* e tempo de inferência |
| Flutter test + testes Node (`node:test`) | Regressão de UI, metas e casamento TACO | Protege regras críticas entre ciclos |
| Eventos de *analytics* | Medição de uso (pedido, sucesso e falha da IA, telas) | Instrumentação exigida pela avaliação da Seção 4.1 |

Fonte: Elaboração própria (2026).

A stack reflete restrições do TCC: não treinar um classificador próprio de larga escala; fundamentar calorias em referência nacional; e manter o sistema no ar durante o período de uso. Tecnologias de propósito geral (Flutter, NestJS, PostgreSQL) foram preferidas a *frameworks* experimentais, para reduzir risco de entrega do artefato.

## 4.2.5 Fluxo de reconhecimento alimentar com Inteligência Artificial e tabela TACO

O reconhecimento alimentar é o mecanismo que materializa o primeiro objetivo específico: reduzir a dependência de inserções manuais. O desenho separa duas preocupações. A visão computacional identifica o que está no prato e estima gramas. A TACO, quando há correspondência, define energia e macronutrientes por 100 g. Essa separação evita que o modelo generativo seja, ao mesmo tempo, único juiz da composição nutricional — ponto alinhado à delimitação de não substituir acompanhamento profissional e à recomendação, extraída do Capítulo 3, de ancorar informações em referências reconhecidas.

A TACO utilizada é a 4ª edição da Tabela Brasileira de Composição de Alimentos (NEPA/UNICAMP, 2011), carregada no PostgreSQL (tabela `taco_4a_edicao` ou equivalente configurável). Cada linha oferece descrição, categoria, `energia_kcal`, `proteina_g`, `carboidrato_g` e `lipideos_g`. O serviço mantém cache em memória por dez minutos para não reler a tabela a cada requisição.

A Figura 6 e a descrição a seguir detalham o fluxo implementado.

**Figura 6 — Fluxo de reconhecimento alimentar com IA e tabela TACO**

Fonte: Elaboração própria (2026).

O usuário inicia a captura por câmera, galeria, texto (incluindo rótulo nutricional) ou refeição previamente salva. No caso de foto, o cliente redimensiona o maior lado para no máximo 1920 pixels e recodifica em JPEG a 90%, em segundo plano, para equilibrar fidelidade visual e custo de envio. Em seguida, autentica a chamada `POST /api/ai/food/analyze` com JWT. O corpo contém `imageBase64` e `mimeType`, ou `manualText`, ou ainda a lista de itens já revisados para recálculo.

No servidor, análises apenas de imagem geram um hash SHA-256 do binário. Se o mesmo usuário já analisou o mesmo conteúdo, o resultado em cache é reenriquecido com a TACO atual — o nome cru eventualmente devolvido pela IA em versões anteriores do *matching* é então substituído pela descrição correspondente. Requisições idênticas em andamento são deduplicadas. Cache miss dispara o provedor Gemini.

O provedor envia a imagem (ou o texto) com um *prompt* de sistema que instrui o modelo a atuar como analista de refeições brasileiras: nomear alimento com preparo e corte quando visíveis (por exemplo, “Arroz branco cozido”, “Frango peito grelhado”), estimar gramas e, na presença de rótulo, extrair a porção de referência sem calcular a proporção — o sistema o fará. A cadeia padrão percorre modelos Flash leves (`gemini-3.5-flash-lite`, com *fallbacks* `gemini-3.1-flash-lite`, `gemini-2.5-flash-lite` e `gemini-3-flash`), com 12 segundos por modelo, orçamento total de 55 segundos e recuo temporário após 429 ou *timeout*. O objetivo é degradar com graça sob cota, e não bloquear o registro.

A resposta da IA é um JSON com `items` (nome, gramas, calorias, proteína, carboidrato, gordura e, se houver, `nutritionLabel`), `totals` e `justification`. O enriquecimento nutricional percorre cada item nesta ordem:

1. **Rótulo informado (`nutrition_label`).** Se o usuário forneceu tabela nutricional, aplica-se a proporção (consumido / referência) × valores do rótulo. Essa fonte tem prioridade máxima.
2. **Correspondência TACO (`taco_db`).** Normaliza-se o nome (sem acentos, sem palavras vazias) e busca-se o melhor registro da TACO acima do limiar 0,58. O algoritmo pontua cobertura de tokens, favorece preparos compatíveis (grelhado, assado, cozido) e cortes usuais (peito, filé) e rejeita conflito cru versus cozido. Feijão sem variedade tende a carioca ou preto; nomes genéricos de arroz no prato são associados à forma cozida. Com o match, kcal e macros vêm de (valor por 100 g × gramas) / 100. O campo `matchedFood` guarda a descrição original da TACO, exibida na interface como etiqueta “TACO”.
3. **Decomposição de receita (`recipe_decomposition`).** Pratos compostos sem linha direta na TACO (bolo, pizza, lasanha) são aproximados por receitas-padrão cujos ingredientes, uma vez casados na tabela, são ponderados.
4. **Estimativa da IA (`ai_estimate`).** Se nenhuma âncora se aplica, preservam-se os valores do modelo, explicitamente marcados como estimativa.

Os totais da refeição são a soma dos itens já enriquecidos. A justificativa devolvida ao usuário acrescenta um resumo das fontes (“*n* por correspondência TACO”, “*n* por estimativa da IA” etc.).

Na tela de revisão, o usuário altera nome, porção e tipo de refeição (café, almoço, jantar ou livre). Ao confirmar, o cliente chama novamente a API só com os itens editados; o servidor reaplica a TACO sem nova inferência visual. A foto, se existir, sobe ao *bucket* `meals` do Storage; a API persiste título, totais, tipo, horário, URL e o JSON dos itens. Só então a refeição entra no saldo do dia, na ofensiva e nas missões.

Três propriedades desse fluxo merecem registro metodológico. Primeiro, o humano permanece no ciclo: a automação reduz o esforço de partida, mas a persistência é deliberada, o que mitiga erros de visão e de porção. Segundo, a TACO funciona como camada de fundamentação nutricional, e não como classificador visual — coerente com a delimitação de não treinar base própria de larga escala. Terceiro, cache, *fallback* de modelos e recálculo sem visão tornam o recurso utilizável no cotidiano de 30 dias, condição necessária para avaliar engajamento, e não apenas a acurácia pontual de um modelo.

## 4.2.6 Síntese da metodologia de software

A metodologia de software deste trabalho articula três camadas. No nível da pesquisa, a DSR justifica a construção de um artefato para uma classe de problema (registro alimentar com alto atrito), e a ADR explica a evolução desse artefato em ciclos de construção, uso e avaliação. No nível da engenharia, as etapas de planejamento, requisitos, diagramas, design, codificação, testes e *deploy* foram executadas de forma incremental. No nível da solução, a arquitetura cliente–servidor, a *stack* da Tabela 11 e o fluxo IA + TACO materializam os objetivos específicos de reconhecimento, gamificação e interação social.

O Capítulo 5 apresenta o artefato em funcionamento e os resultados obtidos com os participantes. A discussão do Capítulo 6 interpreta esses resultados à luz das questões de pesquisa formuladas na Seção 1.3.

---

## Referências a incluir no capítulo de referências

HEVNER, A. R. et al. Design science in information systems research. *MIS Quarterly*, v. 28, n. 1, p. 75–105, 2004.

NEPA – NÚCLEO DE ESTUDOS E PESQUISAS EM ALIMENTAÇÃO. *Tabela brasileira de composição de alimentos – TACO*. 4. ed. rev. e ampl. Campinas: NEPA/UNICAMP, 2011.

PEFFERS, K. et al. A design science research methodology for information systems research. *Journal of Management Information Systems*, v. 24, n. 3, p. 45–77, 2007.

SEIN, M. K. et al. Action design research. *MIS Quarterly*, v. 35, n. 1, p. 37–56, 2011.

SOMMERVILLE, I. *Engenharia de software*. 10. ed. São Paulo: Pearson, 2018.
