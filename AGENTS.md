# AGENTS.md — Contexto do delta-sql-database

Este arquivo orienta agentes de IA e pessoas desenvolvedoras que atuam neste repositório. As instruções abaixo devem ser lidas antes de qualquer alteração e aplicadas em conjunto com a tarefa local.

## 1. Visão geral do Projeto Delta

O Projeto Delta é uma plataforma acadêmica de monitoramento inteligente do consumo residencial de água. Sensores conectados a hidrômetros enviam dados de consumo para uma arquitetura que consolida medições, apoia a detecção de vazamentos, permite estimativas de gastos e disponibiliza informações para aplicações web, mobile e chatbot.

A arquitetura de dados é distribuída por responsabilidade:

- PostgreSQL: dados cadastrais, relacionais e transacionais;
- MongoDB: telemetria IoT e dados de aplicação de alto volume;
- Redis e Neo4j: componentes planejados na documentação de arquitetura, sem código neste repositório.

Este repositório trata somente da camada PostgreSQL. Não presuma que aplicações, serviços ou scripts pertencentes a outros repositórios estejam disponíveis aqui.

## 2. Contexto deste repositório

O `delta-sql-database` mantém os scripts SQL do banco relacional do Projeto Delta. Seu conteúdo atual é composto por:

- `tables/`: definições individuais das tabelas de negócio;
- `functions/`: funções PL/pgSQL usadas por regras de negócio;
- `procedures/`: procedures PL/pgSQL para operações do domínio;
- `audit-tables/`: tabelas que armazenam o histórico de auditoria;
- `audit-functions/`: funções acionadas pelos mecanismos de auditoria;
- `triggers/`: triggers que registram operações nas tabelas auditadas;
- `script-schema.sql`: criação das tabelas de negócio na ordem de dependência;
- `script-optimization.sql`: agregação das funções e procedures de negócio;
- `script-audit.sql`: criação das estruturas e rotinas de auditoria;
- `script-roles.sql`: criação de roles, usuários e privilégios do PostgreSQL;
- `script-dataload.sql`: carga de dados de teste;
- `.github/workflows/trigger_actions.yml`: chamada do workflow organizacional de validação de Pull Requests.

Ao preparar um banco do zero, preserve a seguinte ordem de execução:

1. `script-schema.sql`;
2. `script-optimization.sql`;
3. `script-audit.sql`;
4. `script-roles.sql`;
5. `script-dataload.sql`, quando a tarefa exigir dados de teste.

Não invente tabelas, integrações, frameworks de teste, contêineres ou dependências. Antes de descrever ou alterar qualquer objeto, confira os arquivos existentes e as referências correspondentes no `delta-handbook`.

### Convenções de banco de dados

Conforme as regras de negócio documentadas no handbook:

- armazene dados em maiúsculas quando aplicável;
- nomeie objetos de banco em inglês e sem acentos;
- use `tb_` para tabelas;
- use `fk_<origem>_<destino>` para chaves estrangeiras;
- use `chk_` para constraints de validação;
- use `uq_` para constraints de unicidade;
- use `sys_` para roles do sistema.

## 3. Leitura obrigatória do TASK.md

Antes de executar qualquer tarefa, leia integralmente o arquivo `TASK.md` localizado na raiz deste repositório e confirme o escopo, as restrições e os critérios de conclusão ali definidos.

Se o `TASK.md` não existir, não o crie por iniciativa própria. Informe explicitamente a ausência e obtenha uma instrução de tarefa válida antes de modificar o repositório. Uma solicitação específica não autoriza mudanças fora do escopo descrito nela.

## 4. Padrão de branches e commits

Crie cada branch dentro deste repositório Git, sempre a partir da `main` atualizada. A pasta que agrupa os repositórios do Delta não é um repositório Git e não deve ser inicializada como um.

O padrão de branches é:

```text
<tipo>/<descricao-da-alteracao>
```

Tipos permitidos:

- `feat`: nova funcionalidade;
- `fix`: correção de bug;
- `refactor`: reorganização sem mudança de comportamento;
- `docs`: alteração de documentação;
- `test`: criação ou manutenção de testes;
- `style`: alteração exclusivamente de estilo.

Use uma descrição curta, objetiva, em minúsculas e separada por hífens, como `docs/agents-md` ou `test/validacao-functions`.

Fluxo de criação:

```text
git checkout main
git pull origin main
git checkout -b <tipo>/<descricao-da-alteracao>
```

Os commits seguem Conventional Commits no formato `<tipo>: descrição`, usando os mesmos tipos permitidos para branches. Evite misturar alterações sem relação no mesmo commit e mantenha cada mudança restrita ao repositório responsável.

## 5. Padrão de documentação

Documentos novos ou atualizados devem seguir o padrão observado no `delta-handbook`:

- usar Markdown com extensão `.md`;
- apresentar título e objetivo claros;
- explicar contexto, motivação e justificativas relevantes;
- organizar o conteúdo com hierarquia coerente de títulos e subtítulos;
- usar listas, tabelas, blocos de código e diagramas somente quando melhorarem a compreensão;
- nomear arquivos em minúsculas, com palavras separadas por hífen, como `modelo-relacional.md`;
- verificar se já existe conteúdo equivalente antes de criar outro documento;
- registrar decisões e manter o histórico de atualizações relevantes quando aplicável;
- solicitar revisão das mudanças relevantes antes do merge.

Ao documentar comportamento técnico, diferencie o que foi confirmado nos arquivos ou por execução do que é apenas planejamento. Não apresente funcionalidades futuras como implementadas.

## 6. Limite de complexidade e nível técnico

As soluções devem ser compatíveis com o conhecimento de estudantes do Ensino Médio Técnico em Análise e Desenvolvimento de Sistemas.

- Priorize código simples, legível e dividido em pequenas responsabilidades.
- Utilize primeiro os recursos já presentes no repositório e conhecidos pela equipe.
- Não adicione frameworks, bibliotecas, padrões arquiteturais ou infraestrutura sem necessidade comprovada.
- Evite abstrações prematuras, metaprogramação, arquiteturas distribuídas e padrões avançados quando uma solução direta atender ao requisito.
- Não reestruture grandes partes do projeto para resolver uma tarefa localizada.
- Explique decisões técnicas e trechos não óbvios com linguagem didática.
- Quando a solução exigir conhecimento acima do limite registrado abaixo, apresente primeiro uma alternativa mais simples e solicite aprovação antes de prosseguir.
- Não implemente automaticamente uma solução avançada sem justificativa e autorização explícita.

### Stack e nível de aprofundamento da equipe

| Tecnologia ou assunto | Nível atual | Limite esperado |
| --- | --- | --- |
| Lógica de programação | Intermediário | Avançado |
| Git e GitHub | Intermediário | Avançado |
| HTML e CSS | Básico | Intermediário |
| JavaScript | Básico | Intermediário |
| Java | Intermediário | Avançado |
| Spring Boot | Básico | Avançado |
| Python | Intermediário | Avançado |
| FastAPI | Básico | Intermediário |
| SQL e PostgreSQL | Avançado | Avançado |
| MongoDB | Básico | Intermediário |
| APIs REST | Intermediário | Intermediário |
| Testes automatizados | Básico | Intermediário |
| Docker e CI/CD | Básico | Intermediário |
| Arquitetura e padrões de projeto | Básico | Intermediário |
| IoT e comunicação com hardware | Básico | Básico |

O **nível atual** representa o conhecimento que a equipe já possui e consegue aplicar com alguma autonomia. O **limite esperado** representa o nível máximo de complexidade que a IA pode utilizar.

Quando o limite esperado for superior ao nível atual, a IA deve explicar os novos conceitos de forma simples e didática, relacionando-os ao código produzido. Qualquer solução que ultrapasse o limite esperado exige aprovação explícita antes da implementação.

## 7. Aviso de manutenção

A seção **Estrutura atual do repositório** deve ser revisada periodicamente nesta conversa e atualizada depois
de commits oficiais que adicionem, removam ou reorganizem arquivos. Antes de cada atualização, compare esta
descrição com a árvore real da `main`; o conteúdo deste arquivo não substitui a inspeção do estado atual.
