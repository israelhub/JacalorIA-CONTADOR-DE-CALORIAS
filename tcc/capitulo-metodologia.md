# Capítulos de Metodologia e Desenvolvimento — JacalorIA

> Texto pronto para colar no TCC. A numeração assume o capítulo de Metodologia
> como **4** e o de Desenvolvimento como **5**, em continuidade ao artigo
> (Introdução, Fundamentação teórica, Mapeamento sistemático). Ajuste os
> números se a estrutura final do trabalho for diferente.
>
> Ao final há uma seção **[A complementar]** com informações que não estavam
> nos arquivos e referências que precisam ser incluídas na lista bibliográfica.

---

## 4 Metodologia

Esta seção descreve o percurso metodológico adotado para conceber, construir e
verificar o JacalorIA, aplicação voltada ao reconhecimento de alimentos por
imagem, ao monitoramento da ingestão calórica e à promoção de engajamento por
meio de gamificação e interação social. A exposição organiza-se em duas partes:
a abordagem de pesquisa e de desenvolvimento do software; e as tecnologias e
ferramentas empregadas na construção do artefato. O detalhamento de *como*
cada funcionalidade foi implementada é apresentado no Capítulo 5.

O problema que orienta o trabalho — o abandono de aplicações de registro
alimentar em razão do esforço manual e da baixa motivação de uso contínuo —
exige, simultaneamente, a construção de um artefato de software e ciclos
iterativos de refinamento. Por isso, combinaram-se a *Design Science Research*
(DSR) e a *Action Design Research* (ADR), complementadas por um processo de
engenharia de software organizado em etapas e por um quadro Kanban para a
gestão das tarefas.

### 4.1 Metodologia de desenvolvimento do software

#### 4.1.1 Design Science Research e Action Design Research

A pesquisa foi conduzida no paradigma da *Design Science Research*, segundo o
qual o conhecimento científico é produzido por meio da construção e da
avaliação de artefatos destinados a resolver um problema classificado como
relevante (Hevner *et al.*, 2004; Peffers *et al.*, 2007). No presente
trabalho, o artefato é o JacalorIA: um sistema cliente-servidor que integra
reconhecimento alimentar por inteligência artificial, cálculo personalizado de
metas energéticas, gamificação e recursos sociais.

A DSR forneceu o encadeamento geral da investigação, alinhado às etapas
propostas por Peffers *et al.* (2007):

1. **identificação do problema e motivação** — delimitada na introdução e no
   mapeamento sistemático da literatura, a partir das barreiras do registro
   manual e do fenômeno de abandono em aplicações dietéticas;
2. **definição dos objetivos da solução** — reduzir o esforço de registro,
   individualizar metas calóricas e aumentar o engajamento por gamificação e
   interação social;
3. **projeto e desenvolvimento** — construção iterativa do aplicativo, da API
   e do modelo de dados;
4. **demonstração** — operação do artefato nas plataformas previstas (Android,
   iOS e web) e verificação das funcionalidades centrais;
5. **avaliação** — conferência funcional do software, por testes automatizados
   e verificação das regras de negócio implementadas;
6. **comunicação** — registro dos resultados neste trabalho e no artigo
   científico associado.

A DSR, por si só, descreve *o que* deve ser construído e avaliado, mas não
detalha *como* o artefato evolui em ciclos sucessivos de intervenção. Para
isso, adotou-se a *Action Design Research* (Sein *et al.*, 2011), que articula
pesquisa-ação e *design science* em um processo no qual o artefato é
construído, colocado em uso e reformulado à luz do que se observa em cada
ciclo. A ADR organiza-se em quatro etapas: formulação do problema; ciclo de
construção–intervenção–avaliação (*Building, Intervention and Evaluation* —
BIE); reflexão e aprendizagem; e formalização do conhecimento.

No JacalorIA, a formulação do problema correspondeu ao diagnóstico das
limitações das soluções existentes (registro tedioso, ausência de
reconhecimento automatizado no contexto brasileiro e pouca ênfase em
mecanismos de retenção). Os ciclos BIE corresponderam ao desenvolvimento
incremental por áreas funcionais — autenticação, análise de refeições,
controle calórico, missões, rede social e desempenho —, cada uma sendo
implementada, integrada ao restante do sistema e verificada antes de se
avançar para a seguinte. A reflexão ocorreu ao longo dos ciclos, quando
decisões de projeto (por exemplo, o encadeamento de modelos de IA com
*fallback*, o refinamento pela tabela TACO ou as faixas de tolerância da meta
calórica) foram revistas à medida que o comportamento do sistema se tornava
observável. A formalização do conhecimento materializa-se neste capítulo e no
Capítulo 5, que documentam as escolhas e a lógica de implementação.

A combinação DSR + ADR é coerente com o objetivo do trabalho: não se trata
apenas de descrever um aplicativo, mas de produzir um artefato que
operacionalize, em software, as estratégias apontadas na fundamentação
teórica — inteligência artificial para aumentar a habilidade do usuário no
registro (Fogg, 2009; Tan *et al.*, 2023), gamificação para fortalecer a
motivação (Deterding *et al.*, 2011; Johnson *et al.*, 2016) e interação
social como gatilho de continuidade (Wang *et al.*, 2024).

#### 4.1.2 Processo de desenvolvimento e organização das tarefas

O desenvolvimento do software foi **iterativo e incremental**. O sistema foi
construído em ciclos sucessivos, de modo que cada incremento entregasse uma
parte utilizável da aplicação sem comprometer a organização geral do projeto.
Essa estratégia permitiu validar precocemente as decisões de arquitetura
(separação cliente-servidor, API REST, persistência relacional) e reduzir o
risco de integrar, apenas ao final, módulos heterogêneos como visão
computacional, economia virtual e competições sociais.

Em cada ciclo, o trabalho foi organizado nas seguintes etapas:

- **planejamento** — definição da fatia funcional a ser atacada e de sua
  relação com os objetivos do artefato;
- **análise de requisitos** — especificação do comportamento esperado
  (cadastro, análise de imagem, cálculo de metas, recompensas, grupos etc.);
- **diagramas e *design*** — prototipação da interface no Figma e
  definição da estrutura de módulos, dados e fluxos de navegação;
- **codificação** — implementação no cliente (Flutter/Dart) e no servidor
  (NestJS/TypeScript);
- **testes** — verificação funcional por testes automatizados no *frontend*
  e por testes pontuais de regras no *backend* (correspondência de alimentos
  e cálculo social);
- **implantação (*deploy*)** — publicação contínua da API e da aplicação web
  por meio de *pipeline* automatizado.

Não se pretendeu esgotar, em cada etapa, um modelo prescritivo rígido: as
etapas serviram como organização do ciclo, e não como fases estanques de um
modelo em cascata. Requisitos, interface e código foram revisitados sempre que
o ciclo BIE da ADR indicava necessidade de ajuste.

Para a gestão cotidiana das tarefas, utilizou-se o **Kanban**. O quadro
visualizou o fluxo de trabalho (a fazer, em andamento e concluído), limitou o
trabalho em paralelo e tornou explícitas as dependências entre *frontend*,
*backend* e infraestrutura. A organização por cartões acompanhou as áreas
funcionais do sistema — autenticação, registro de refeições com IA, perfil,
desempenho, missões e área social —, o que manteve o incremento alinhado aos
módulos do código.

O versionamento foi feito com Git, no repositório GitHub do projeto. Ramos
por funcionalidade e integração contínua na ramificação principal permitiram
revisar alterações de forma incremental e implantar o sistema sem
reconfiguração manual a cada entrega.

### 4.2 Tecnologias e ferramentas utilizadas

O JacalorIA adota arquitetura **cliente-servidor**. O cliente é responsável
pela interface, pela captura de imagens e pela persistência local da sessão; o
servidor processa as requisições, aplica as regras de negócio e coordena
serviços externos (inteligência artificial, correio eletrônico e armazenamento
de arquivos). A comunicação ocorre por uma **API REST**, protegida por
autenticação. Essa separação atende aos objetivos do trabalho porque permite
evoluir o reconhecimento alimentar, as regras de gamificação e os cálculos
nutricionais no servidor — único ponto de verdade — sem duplicar a lógica em
cada plataforma cliente.

O Quadro 1 sintetiza a pilha tecnológica. Nas subseções seguintes, cada
escolha é justificada em função do papel que desempenha no artefato.

**Quadro 1.** Tecnologias e ferramentas utilizadas no JacalorIA.

| Categoria | Tecnologia | Função no sistema |
| --- | --- | --- |
| Prototipação de interface | Figma | Layout, tipografia, cores e fluxo de navegação antes da implementação |
| Cliente (aplicativo) | Flutter / Dart | Interface multiplataforma (Android, iOS e web), câmera e consumo da API |
| Servidor (API) | NestJS / TypeScript | Regras de negócio, autenticação, orquestração da IA e persistência |
| Banco de dados | PostgreSQL (Supabase) | Dados relacionais de usuários, refeições, missões e grupos |
| Mapeamento objeto-relacional | Sequelize | Acesso ao banco a partir do TypeScript |
| Armazenamento de arquivos | Supabase Storage | Fotos de perfil e imagens associadas ao usuário |
| Inteligência artificial | Google Gemini | Identificação de alimentos em imagem ou texto e estimativa nutricional |
| Base nutricional | TACO (4ª edição) | Refinamento das estimativas com composição oficial brasileira |
| Autenticação | JWT, Passport, bcrypt e Google Sign-In | Sessão segura e entrada com e-mail/senha ou conta Google |
| Correio eletrônico | Nodemailer (SMTP) | Verificação de conta e recuperação de senha |
| Infraestrutura de publicação | AWS (Elastic Beanstalk, ECR, S3, CloudFront) e GitHub Actions | Implantação da API e da aplicação web |
| Versionamento | Git / GitHub | Histórico de código, ramificações e integração contínua |
| Contêineres | Docker / Node.js 22 | Empacotamento reproduzível do *backend* |

#### 4.2.1 Prototipação e cliente

O **Figma** foi utilizado na etapa de *design* para prototipar telas, definir
identidade visual e validar o fluxo de navegação antes da codificação. A
ferramenta permitiu iterar o *layout* em conjunto com os requisitos de
engajamento (mascote, missões, área social) sem o custo de reescrever código a
cada ajuste estético. Essa antecipação é coerente com a ADR: a intervenção
sobre a interface ocorre cedo, ainda no ciclo de construção.

O cliente foi desenvolvido em **Flutter**, com a linguagem **Dart**. A escolha
deve-se à necessidade de um único código-fonte para Android, iOS e navegador,
reduzindo o esforço de manutenção em comparação com o desenvolvimento nativo
separado — restrição típica de um trabalho de conclusão com equipe reduzida.
O Flutter também oferece acesso à câmera e à galeria (`camera`,
`image_picker`), requisito direto do reconhecimento alimentar por imagem, e
permite executar a mesma aplicação na *web*, o que facilitou demonstrações e
testes sem depender exclusivamente de um dispositivo físico.

A organização do cliente segue uma estrutura **por funcionalidade**
(`features`): autenticação, *onboarding*, *home*, análise de alimentos,
missões, desempenho, social, perfil, lembretes e suporte. Cada *feature*
reúne páginas, *widgets*, serviços e modelos daquela área. Componentes
reutilizáveis (botões, campos, tema, navegação) ficam em uma camada
compartilhada (`shared`), e configurações transversais (URL da API, analytics,
notificações) em `core`. Essa modularização evita que a alteração de uma tela
— por exemplo, a de missões — propague efeitos colaterais para o registro de
refeições.

A persistência local da sessão utiliza **Shared Preferences**, de modo que o
token JWT e os dados básicos do usuário sobrevivam ao fechamento do
aplicativo. O cliente comunica-se com o servidor via HTTP (`http`), enviando o
token no cabeçalho `Authorization`.

#### 4.2.2 Servidor, dados e segurança

O servidor foi implementado em **NestJS**, *framework* Node.js escrito em
**TypeScript**. O NestJS organiza a API em módulos de domínio
(`AuthModule`, `AiModule`, `MealsModule`, `MissionsModule`, `SocialModule`,
`PerformanceModule`, entre outros), com controladores, serviços e modelos
separados. Essa estrutura é mais prescritiva do que um servidor Express
“plano” e favorece a evolução incremental exigida pela ADR: cada ciclo BIE
pôde concentrar-se em um módulo sem reabrir a arquitetura inteira. O
TypeScript acrescenta tipagem estática, reduzindo erros na manipulação de
DTOs, tokens e payloads da IA.

A API REST expõe recursos como `/auth`, `/ai/food/analyze`, `/meals`,
`/missions` e `/social`. A validação de entrada é feita com
`class-validator` e `class-transformer`. Pontos que alteram dados do usuário
exigem o guarda JWT (`JwtAuthGuard`).

Os dados persistentes residem em **PostgreSQL**, banco relacional adequado ao
modelo do projeto, que envolve usuários, refeições, transações de moeda,
missões, amizades e grupos com membros, mensagens e *ranking*. O banco é
hospedado no **Supabase**, que reduz a carga operacional de administrar
PostgreSQL e oferece **Storage** para arquivos (avatares). O acesso a partir
do NestJS é feito pelo **Sequelize** (`sequelize-typescript`), que mapeia
classes TypeScript às tabelas e evita a escrita sistemática de SQL, sem
impedir consultas nativas quando o desempenho ou a agregação exigem (como no
*ranking* de XP).

A autenticação combina **bcrypt** (12 *rounds*) para o armazenamento de
senhas, **Passport** com estratégia JWT para as requisições autenticadas e
**JSON Web Token** para a sessão. O login com Google utiliza **Google
Sign-In** no cliente e validação do *idToken* (ou, em *fallback*, do
*accessToken*) no servidor junto à API OAuth da Google. Essa combinação
mantém o controle da sessão no próprio *backend* — adequado a uma API REST
consumida por aplicativo móvel — e, ao mesmo tempo, reduz o atrito inicial de
cadastro, alinhado ao objetivo de diminuir o abandono no primeiro acesso.

A verificação de e-mail e a recuperação de senha utilizam **Nodemailer** com
SMTP. Códigos de seis dígitos expiram em quinze minutos. Quando o envio de
correio está desabilitado em ambiente de desenvolvimento, o código é apenas
registrado no *log*, o que preserva o fluxo sem exigir infraestrutura de
e-mail em toda máquina local.

#### 4.2.3 Inteligência artificial e base nutricional

O reconhecimento de alimentos recorre à API **Google Gemini**
(*Generative Language API*), e não a um modelo de visão treinado pelos
autores. A decisão decorre do escopo do TCC: treinar um classificador
próprio exigiria um conjunto rotulado de pratos brasileiros, infraestrutura
de treino e validação clínica que extrapolam o tempo e os recursos
disponíveis. O Gemini aceita imagem e texto, devolve JSON estruturado
(alimentos, gramas, calorias e macronutrientes) e pode ser encadeado a um
pós-processamento local. O *prompt* de sistema instrui o modelo a privilegiar
o contexto alimentar brasileiro (por exemplo, normalizar “arroz” para “arroz
branco cozido”) e a extrair tabela nutricional quando o usuário a informa
manualmente.

As estimativas da IA são refinadas com a **Tabela Brasileira de Composição
de Alimentos (TACO), 4ª edição**, armazenada no PostgreSQL. Um serviço de
enriquecimento compara o nome identificado a descrições da TACO e recalcula
kcal e macros por 100 g. Essa camada existe porque o objetivo do trabalho não
é apenas “detectar comida”, e sim produzir um registro calórico
minimamente confiável para o público brasileiro — lacuna evidenciada no
mapeamento da literatura.

#### 4.2.4 Publicação, versionamento e verificação

Em produção, o *backend* é empacotado em **Docker** (Node.js 22, compilação
em estágio separado) e publicado no **Amazon Elastic Beanstalk**, com a
imagem versionada no **Amazon ECR**. A aplicação web Flutter é gerada em modo
*release* e enviada a um *bucket* **Amazon S3**, distribuído pelo
**CloudFront**. O *pipeline* **GitHub Actions**, autenticado na AWS por OIDC
(sem chaves estáticas no repositório), dispara o *deploy* a cada integração
na ramificação principal. Essa automação trata a implantação como etapa
recorrente do ciclo de desenvolvimento, e não como evento artesanal ao final
do projeto.

A verificação do artefato apoia-se em testes de *widget* e de regras no
cliente (autenticação, *home*, análise de alimentos, missões, social,
desempenho, calculadora nutricional) e em testes de funções puras no
servidor (casamento de nomes com a TACO e cálculo da competição por média de
meta). Não se realizou, neste trabalho, um estudo empírico amplo com usuários
finais; a avaliação permanece no nível de demonstração e verificação
funcional do artefato, o que deve ser lido como limitação da pesquisa e não
como validação de adesão em campo.

> **Nota sobre hospedagem.** O artigo científico associado menciona o
> **Render** como hospedagem do *backend*. No repositório atual, a
> publicação está configurada na **Amazon Web Services**. Unifique essa
> informação no texto final: se o Render foi usado apenas no início,
> registre-o como etapa transitória; se ambas as nuvens coexistiram, deixe
> explícito o recorte temporal.

---

## 5 Desenvolvimento e implementação

Este capítulo descreve como o artefato foi efetivamente construído. Para cada
núcleo funcional, apresentam-se a lógica adotada, as tecnologias envolvidas,
a integração entre cliente e servidor e as decisões que relacionam a
implementação aos objetivos do trabalho. A ordem segue o percurso do usuário
no sistema: entrar na aplicação, registrar a refeição, acompanhar calorias,
engajar-se por gamificação, interagir socialmente e revisar o desempenho.

### 5.1 Desenvolvimento da autenticação (Google e e-mail/senha)

A autenticação foi tratada como pré-condição de todos os demais módulos:
refeições, missões e grupos são dados pessoais e só podem ser lidos ou
alterados pelo titular da sessão. Implementaram-se dois caminhos de entrada,
com o mesmo resultado — um JWT de sessão e um perfil persistido.

**Cadastro com e-mail e senha.** O cliente envia nome, e-mail e senha para
`POST /auth/register`. O servidor recusa e-mails já cadastrados, gera o
*hash* da senha com bcrypt e cria o usuário com `emailVerified = false`. Um
código numérico de seis dígitos, válido por quinze minutos, é enviado por
e-mail (Nodemailer). Somente após `POST /auth/email/verify` o login
(`POST /auth/login`) é autorizado. Há reenvio de código e fluxo de
esqueci-minha-senha (`forgot` → validação do código → `reset`), o que evita
que um e-mail inacessível se transforme em abandono definitivo da conta.

**Entrada com Google.** No cliente, o pacote `google_sign_in` obtém
`idToken` e, quando necessário, `accessToken`. O servidor valida o *idToken*
em `https://oauth2.googleapis.com/tokeninfo` (conferindo *audience* e e-mail
verificado). Se essa validação falha por incompatibilidade de *client id*
entre Android, iOS e web — situação comum em aplicativos multiplataforma —,
usa-se o *accessToken* contra `https://www.googleapis.com/oauth2/v3/userinfo`.
Usuários novos são criados já com e-mail verificado; usuários existentes têm
a verificação marcada como concluída. Uma senha de *fallback* (derivada por
SHA-256 do token) é gravada apenas para satisfazer a restrição de
`password_hash` NOT NULL, sem ser conhecida pelo usuário.

**Sessão e *onboarding*.** O JWT é armazenado no dispositivo. `POST /auth/refresh`
renova a sessão. Após o primeiro acesso, o usuário que ainda não informou
sexo, data de nascimento, peso, altura, nível de atividade e objetivo
nutricional é conduzido ao *onboarding*. Esses campos alimentam o cálculo de
metas (Seção 5.3). Enquanto o perfil estiver incompleto, o sistema sinaliza
`needsOnboarding`, impedindo que o acompanhamento calórico comece com valores
genéricos silenciosos.

A decisão de oferecer Google *e* e-mail/senha relaciona-se diretamente ao
objetivo de reduzir atrito: o OAuth encurta o primeiro acesso, enquanto o
fluxo tradicional atende quem não deseja vincular a conta Google. A
verificação de e-mail e a recuperação de senha protegem a identidade em um
sistema que guarda histórico alimentar, peso e dados sociais.

### 5.2 Implementação do reconhecimento de alimentos por IA

O reconhecimento alimentar é o mecanismo pelo qual o trabalho ataca a barreira
do registro manual (Cordeiro *et al.*, 2015; Wang *et al.*, 2024). O fluxo foi
dividido em captura, análise, refinamento, revisão humana e persistência.

**Captura.** Na *home*, o usuário dispara a câmera ou a galeria
(`FoodCapturePage`). A imagem é otimizada no dispositivo e convertida para
Base64, formato adequado ao corpo JSON da API. Também é possível descrever a
refeição em texto (incluindo dados de rótulo nutricional) ou reenviar itens já
corrigidos para recálculo, sem nova foto.

**Análise no servidor.** `POST /ai/food/analyze`, protegido por JWT, recebe
imagem, texto manual ou lista de itens. O provedor Gemini é chamado com
`responseMimeType: application/json` e temperatura 0,2, de modo a favorecer
saídas estáveis e estruturadas. O *prompt* de sistema define o modelo como
especialista em porções e composição, prioriza tabela nutricional informada
pelo usuário, exige tipo/corte/preparo no nome do alimento e desencoraja
pratos compostos sem evidência visual.

Para lidar com cotas, latência e indisponibilidade — riscos reais de um
serviço externo no caminho crítico do registro —, implementou-se uma **cadeia
de modelos com *fallback***. O modelo primário padrão é o
`gemini-3.5-flash-lite`; em falha, *timeout* (12 s por modelo; 55 s no total)
ou HTTP 429, o servidor tenta `gemini-3.1-flash-lite`, `gemini-2.5-flash-lite`
e `gemini-3-flash`. Modelos recém-falhos entram em *cooldown* de 30 s. Se
todos falham, a API responde 503 com mensagem compreensível ao usuário
(“Estamos enfrentando uma sobrecarga na IA…”), e o cliente oferece nova
tentativa. Essa decisão privilegia a continuidade de uso em detrimento de uma
única chamada “ótima” que, ao falhar, abortaria o registro.

**Cache.** Para a mesma imagem do mesmo usuário, o *hash* SHA-256 do conteúdo
é consultado na tabela `food_image_analyses`. Um acerto de cache evita nova
chamada ao Gemini, mas o refinamento TACO é reaplicado, para que melhorias no
casamento de nomes não fiquem presas a um resultado antigo. Análises em
andamento para o mesmo *hash* são deduplicadas em memória.

**Refinamento TACO (pós-processamento).** O serviço
`FoodNutritionRagService` carrega a tabela TACO (`tco_4a_edicao` /
`taco_4a_edicao`) e, para cada item:

1. se houver *nutritionLabel* (rótulo informado), calcula a proporção
   consumido/referência e ignora a estimativa da IA para aquele item;
2. senão, busca a melhor correspondência textual acima de um limiar (0,58),
   com penalidades para conflito cru/cozido e para preparos de alto impacto
   calórico (frito, milanesa, calda) não mencionados na consulta;
3. se o nome indica receita composta (bolo, pizza, lasanha) e não há match
   direto, decompõe o prato em ingredientes-template e agrega os valores da
   TACO;
4. se nada se aplica, preserva a estimativa da IA, marcada como
   `ai_estimate`.

Os totais da refeição são a soma dos itens já refinados. A justificativa
devolvida ao usuário indica quantos itens vieram de rótulo, de TACO, de
receita ou da IA. Essa cascata materializa o compromisso do trabalho com a
referência nacional de composição, sem tornar a TACO um ponto único de
falha: na ausência de correspondência, o registro ainda é possível.

**Revisão e gravação.** O cliente exibe os itens em `FoodReviewPage`. O
usuário pode corrigir nome, gramas e tipo de refeição (café, almoço, jantar
ou livre) e solicitar recálculo (`recalculate`), que reenvia apenas os itens
ajustados. A confirmação persiste a refeição em `POST /meals`, com calorias,
macros, itens da análise e, quando houver, URL da imagem. Refeições admitem
edição e *soft delete* (`status = deleted`), de modo que o histórico e as
missões não sejam distorcidos por exclusões acidentais.

O registro também pode partir de **modelos de refeição** previamente
salvos, o que reduz ainda mais o esforço em pratos recorrentes — outro
mecanismo alinhado à redução de atrito.

### 5.3 Implementação do controle de calorias

O controle calórico traduz a fundamentação nutricional (Mifflin *et al.*,
1990; Trumbo *et al.*, 2002) em regras executáveis. Há três camadas: cálculo
da meta, acumulação do consumo e critério de “meta batida”.

**Cálculo da meta.** A função `calculateNutritionGoalsFromProfile`,
replicada no servidor e no cliente para manter a pré-visualização do
*onboarding* coerente com o que será gravado, aplica a equação de
Mifflin-St Jeor:

- homem: \(TMB = 10P + 6{,}25A - 5I + 5\)
- mulher: \(TMB = 10P + 6{,}25A - 5I - 161\)
- sexo não informado: fator intermediário (−78)

em que \(P\) é o peso em kg, \(A\) a altura em cm e \(I\) a idade. Unidades
alternativas (lb, ft, in) são convertidas. O gasto energético total (GET) é
a TMB multiplicada pelo fator de atividade (1,2 sedentário a 1,9 extremo).
O GET é então ajustado pelo objetivo:

- **perder peso:** déficit percentual crescente com o IMC (cerca de 18% a
  30%), com piso calórico de 1.200 kcal (feminino) ou 1.500 kcal (masculino);
  em IMC ≥ 30, o peso metabólico é suavizado em direção ao peso correspondente
  a IMC 24,9, evitando metas irrealisticamente baixas;
- **manter peso:** GET sem ajuste;
- **ganhar massa:** superávit percentual (cerca de 8% a 22%), maior em IMC
  baixo.

Os macronutrientes combinam distribuição percentual (proteína/gordura/carboidrato)
com pisos em g/kg (por exemplo, 2,2 g/kg de proteína na perda de peso). O
resultado (`dailyCalorieGoal`, `dailyProteinGoal`, `dailyCarbsGoal`,
`dailyFatGoal`) é persistido no perfil e recalculado quando peso, altura,
objetivo ou atividade são editados.

**Acumulação do dia.** A *home* soma as refeições ativas da data selecionada
e exibe meta, consumido, saldo e barras de proteína, carboidrato e gordura.
A data pode ser alterada, permitindo registrar refeições em dias anteriores
(sem contar para a sequência se o dia não for o atual). Um “congelamento”
da meta do dia (`home_daily_goal_day_lock`) evita que uma edição de perfil
à noite altere retroativamente o critério daquele dia.

**Critério de meta atingida.** A função `hasReachedCalorieGoal` não trata a
meta como um número único a ser igualado. A regra depende do objetivo, porque
“bater a meta” tem significados distintos na perda, na manutenção e no ganho:

- perder peso: consumido entre (meta − 200 kcal) e a meta, **sem ultrapassar**;
- manter peso: faixa de ±100 kcal;
- ganhar massa: consumido **acima** da meta.

Essas tolerâncias alimentam a *home* (saldo e mascote), as missões (“bata a
meta N vezes”), o calendário de desempenho e os *rankings* sociais do tipo
`daily_goal` e `goal_average`. Centralizar a regra em um utilitário compartilhado
evita que cada módulo inventasse um critério próprio — inconsistência que
quebraria a confiança do usuário no *feedback*.

O mascote **Jaca** reage a esse estado: triste na ausência de registros,
assustado quando a meta é ultrapassada de modo indesejado (perda ou
manutenção), feliz quando a meta é atingida, e em estado padrão enquanto o
usuário ainda está no caminho. O mascote opera, portanto, como *feedback*
imediato no sentido de Johnson *et al.* (2016), e não como ornamento
desconectado das regras nutricionais.

### 5.4 Desenvolvimento da gamificação

A gamificação foi implementada como um **sistema de economia e hábitos**, e
não como um conjunto isolado de *badges*. O desenho segue a definição de
Deterding *et al.* (2011) — elementos de jogo em contexto não lúdico — e a
observação de Hamari *et al.* (2014) de que o efeito depende de como os
mecanismos se integram ao restante do produto. No JacalorIA, as missões leem
as mesmas refeições e as mesmas regras de meta do módulo nutricional; o ouro
e o XP obtidos ali abastecem a loja, o perfil e os grupos de XP.

**Missões.** O catálogo é semeado na inicialização do módulo
(`DEFAULT_MISSIONS`) e classificado por horizonte temporal:

- **diárias** — registrar café, almoço e jantar; atingir a meta de proteína
  (recompensa menor, alta frequência);
- **semanais** — variedade de 15 alimentos, meta calórica em 4 dias,
  sequência de 5 dias, atualização de peso;
- **mensais** — registro em 20 dias, objetivo diário em 20 dias, macros
  completos em 10 dias (recompensa maior, *goal gradient*);
- **fim de semana** — meta na sexta, sábado e domingo, como evento contra a
  queda típica de uso no sábado e no domingo.

O progresso é calculado a partir das refeições ativas, do peso lançado e da
sequência de dias, sempre no fuso `America/Sao_Paulo`. Ao completar uma
missão, o servidor registra transações de **ouro** e **XP**
(`user_currency_transactions`). A relação XP = 2 × ouro separa progressão
social (XP, visível em *rankings*) de poder de compra (ouro, gasto na loja),
evitando que o *status* seja “vendido”.

**Loja e personalização.** Com o ouro, o usuário adquire molduras de avatar,
fundos, emojis do Jaca e **bloqueadores de sequência**. Itens equipados
alteram o perfil visível para amigos e grupos, o que fecha o ciclo
recompensa → expressão social. O catálogo é semeado no banco
(`StoreCatalogService`).

**Sequência (*streak*) e bloqueador.** `StreakService` considera um dia
válido quando há refeição ativa daquele dia civil (no fuso da aplicação). A
sequência atual conta dias consecutivos até o presente; a maior sequência é
retida para o perfil. O bloqueador, comprado na loja ou obtido em
*check-in*, pode ser aplicado a um dia perdido, preservando a ofensiva —
mecanismo clássico de *loss aversion* para não transformar um dia falho em
abandono da aplicação.

**Check-in.** Campanhas datadas (por exemplo, agosto de 2026) oferecem
recompensa diária por acesso (ouro, bloqueador, moldura, fundo), reforçando
o hábito de abrir o aplicativo mesmo quando o usuário ainda não registrou a
refeição.

**Mascote.** Além da reação emocional na *home*, o Jaca aparece no
*onboarding*, nos emojis do chat de grupo e no *widget* de lembrete. A
personagem unifica a identidade do produto e materializa o *feedback* da
gamificação em um agente reconhecível.

### 5.5 Desenvolvimento da interação social

A área social operacionaliza o “gatilho” do modelo de Fogg (2009) e o papel
da interação na retenção (Wang *et al.*, 2024). O módulo `SocialModule`
concentra amizades, grupos, chat, *ranking* e perfil público.

**Amizades.** Cada usuário possui um código de convite. Amigos podem ser
adicionados por e-mail, código, *link* profundo ou QR Code (`qr_flutter` e
`mobile_scanner`). Solicitações pendentes são aceitas ou recusadas. O perfil
do amigo exibe sequência, XP e, conforme a privacidade
(`hidePublicProfileMeals`), as refeições. Essa visibilidade controlada busca
o incentivo social sem expor o histórico alimentar de forma irrestrita.

**Grupos de competição.** Um grupo tem nome, ícone, visibilidade
(público/privado), código de convite, duração e um **tipo de competição**,
que determina a métrica do *ranking*:

| Tipo | Regra | Critério de vitória |
| --- | --- | --- |
| `offensive` | Sequência individual de registros no período do grupo | Maior ofensiva |
| `group_streak` | Todos devem registrar no dia; um atraso encerra o desafio coletivo | Sustentar a sequência conjunta |
| `daily_goal` | Dias em que a meta calórica (Seção 5.3) foi atingida | Mais acertos |
| `goal_average` | Média de calorias no período ÷ dias civis decorridos | Menor desvio em relação à meta pessoal |
| `xp` | Soma de XP obtido nas missões no intervalo do grupo | Maior XP |

A diversidade de modos evita reduzir o social a um único *leaderboard* de
calorias — o que seria inadequado, pois as metas são individuais. Em
`goal_average`, por exemplo, ganha quem se aproxima da *própria* meta, e não
quem come menos. Em `group_streak`, a cooperação substitui a competição
pura. Os modos reutilizam `StreakService` e `hasReachedCalorieGoal`, de forma
que o social não inventa uma nutrição paralela.

Grupos públicos são listados e podem ser filtrados. Membros entram por
convite, *link* ou código. Há histórico de competições encerradas (posição,
participantes, duração), chat com mensagens, reações e emojis do Jaca
(alguns pagos na loja), e *feed* de atividades. Um *ranking* global de XP
(diário, semanal, mensal ou geral) complementa os grupos.

A implementação privilegiou persistência relacional (membros, mensagens,
solicitações) em vez de um serviço social externo, para manter as regras de
competição no mesmo servidor que calcula metas e missões.

### 5.6 Desenvolvimento da tela de desempenho

A tela de desempenho (`PerformancePage` / `GET /performance/monthly`)
consolida o acompanhamento de médio prazo, fechando o ciclo registro →
*feedback* diário → reflexão mensal. Sem essa visão, missões e metas
diárias permaneceriam episódicas, e o usuário não veria a evolução que a
fundamentação associa à conscientização alimentar (Wansink, 2010).

Para o mês solicitado, o servidor agrega as refeições ativas no fuso da
aplicação e classifica cada dia civil em um de quatro estados:

- `goal_achieved` — houve registro e a meta do objetivo foi atingida;
- `meal_registered` — houve registro, mas a meta não foi atingida;
- `streak_blocker_applied` — não houve registro, porém um bloqueador foi
  usado naquele dia;
- `no_record` — ausência de registro.

Desses estados derivam os indicadores do relatório: dias com meta batida,
dias com algum registro, percentual de consistência (registros / dias
decorridos), médias diárias de kcal e macros, sequência atual e variação de
peso. O peso vem da tabela `user_weight_entries` (lançamentos pontuais) e do
peso atual do perfil; o gráfico mensal interpola a série para exibir a
trajetória. Meses anteriores permanecem consultáveis, o que transforma o
calendário em histórico e não apenas em um recorte do mês vigente.

A tela reutiliza as mesmas regras da *home* e das missões. Essa
consistência é uma decisão de projeto: se “meta batida” significasse uma
coisa no calendário e outra nas missões, o *feedback* perderia credibilidade
e a gamificação se descolaria do controle calórico — exatamente o risco
apontado por Hamari *et al.* (2014) quando a gamificação é acoplada de forma
superficial.

---

## Referências a incluir na lista bibliográfica

As seguintes obras fundamentam a Seção 4.1 e **ainda não constam** da lista
do artigo. As demais citações (Cordeiro, Deterding, Fogg, Hamari, Johnson,
Mifflin, Tan, Trumbo, Wang, Wansink, WHO, TACO) já estão referenciadas no
texto do artigo.

Hevner, A. R.; March, S. T.; Park, J.; Ram, S. Design science in information
systems research. *MIS Quarterly*, v. 28, n. 1, p. 75–105, 2004.

Peffers, K.; Tuunanen, T.; Rothenberger, M. A.; Chatterjee, S. A design
science research methodology for information systems research. *Journal of
Management Information Systems*, v. 24, n. 3, p. 45–77, 2007.

Sein, M. K.; Henfridsson, O.; Purao, S.; Rossi, M.; Lindgren, R. Action
design research. *MIS Quarterly*, v. 35, n. 1, p. 37–56, 2011.

---

## [A complementar]

Os arquivos do software e o artigo **não** permitiram afirmar, com segurança,
os pontos abaixo. Preencha-os antes da versão final da banca:

1. **Ferramenta Kanban.** O texto afirma o uso de Kanban, conforme
   orientação da equipe, mas o repositório não indica se o quadro era GitHub
   Projects, Trello, Jira ou outro. Inclua o nome da ferramenta.
2. **IDE.** Não há registro de Android Studio, VS Code ou IntelliJ. Informe
   o ambiente de desenvolvimento de fato utilizado (é comum Flutter no VS
   Code e/ou Android Studio).
3. **Diagramas produzidos.** A metodologia cita a etapa de diagramas, mas
   não há UML/casos de uso versionados no repositório. Se foram feitos
   (casos de uso, classes, sequência, DER), anexe-os e mencione-os na
   Seção 4.1.2.
4. **Render × AWS.** O artigo cita Render; o código de produção aponta AWS
   (Elastic Beanstalk, ECR, S3, CloudFront). Esclareça se houve migração.
5. **Avaliação com usuários.** O artigo declara ausência de estudo empírico
   amplo. Se houver piloto informal, teste de usabilidade ou aplicação da
   escala MARS, descreva-o; caso contrário, mantenha a limitação.
6. **Número de ciclos ADR / duração.** Não há datas de *sprint* nem contagem
   formal de ciclos BIE. Se quiser tornar a ADR mais “visível” para a banca,
   acrescente um parágrafo com a quantidade aproximada de iterações ou o
   recorte temporal do desenvolvimento.
7. **Treinamento próprio de IA.** Confirmado no código que *não* houve
   treino de modelo: usa-se Gemini via API. Se a banca perguntar, essa é a
   resposta correta.
8. **Ambiente de homologação.** O `DatabaseModule` prevê `NODE_ENV=homologation`.
   Se existir um ambiente HML distinto de produção, vale uma frase na
   Seção 4.2.4.
