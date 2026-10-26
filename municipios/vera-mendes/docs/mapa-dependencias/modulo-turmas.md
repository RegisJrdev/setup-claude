# Documentação Técnica — Mapa de Dependências do Módulo Turmas
**Sistema:** Integra Digital — Vera Mendes
**Versão:** 1.0
**Data:** 2026-05-19
**Escopo:** Mapeamento completo de todos os módulos e submódulos que possuem vínculo direto ou indireto com o módulo Turmas

---

## Sumário

- [1. Visão Geral](#1-visão-geral)
- [2. Mapa de Relacionamentos](#2-mapa-de-relacionamentos)
- [3. Módulo: Matrículas](#3-módulo-matrículas)
- [4. Módulo: Gestão de Aulas](#4-módulo-gestão-de-aulas)
- [5. Módulo: Aulas e Frequência](#5-módulo-aulas-e-frequência)
- [6. Módulo: Notas e Avaliações](#6-módulo-notas-e-avaliações)
- [7. Módulo: Circuito de Notas / Etapas](#7-módulo-circuito-de-notas--etapas)
- [8. Módulo: Agenda](#8-módulo-agenda)
- [9. Módulo: Avisos](#9-módulo-avisos)
- [10. Módulo: Bolsa Família](#10-módulo-bolsa-família)
- [11. Módulo: Relatórios](#11-módulo-relatórios)
- [12. Módulo: BNCC](#12-módulo-bncc)
- [13. Módulo: Horários](#13-módulo-horários)
- [14. Módulo: Notifiq (App Mobile)](#14-módulo-notifiq-app-mobile)
- [15. Módulo: Franquias / Configuração](#15-módulo-franquias--configuração)
- [16. Módulo: Anos Letivos](#16-módulo-anos-letivos)
- [17. Módulo: Séries / Cursos / Turnos](#17-módulo-séries--cursos--turnos)
- [18. Módulo: Professores](#18-módulo-professores)
- [19. Módulo: Alunos](#19-módulo-alunos)
- [20. Módulo: Pendências](#20-módulo-pendências)
- [21. Módulo: Usabilidade do Sistema](#21-módulo-usabilidade-do-sistema)
- [22. Módulo: Hikvision (Controle de Acesso)](#22-módulo-hikvision-controle-de-acesso)
- [23. Módulo: Educação Inclusiva](#23-módulo-educação-inclusiva)
- [24. Módulo: Importação de Dados](#24-módulo-importação-de-dados)
- [25. Tabela de Migrations com turma_id](#25-tabela-de-migrations-com-turma_id)
- [26. Inventário de Rotas API Dependentes](#26-inventário-de-rotas-api-dependentes)
- [27. Inventário de Rotas Frontend (Vue Router)](#27-inventário-de-rotas-frontend-vue-router)
- [28. Impacto em Cascata — Regras de Negócio Críticas](#28-impacto-em-cascata--regras-de-negócio-críticas)

---

## 1. Visão Geral

O módulo Turmas é o **núcleo central de relacionamentos** do sistema Integra Digital. Praticamente todos os módulos operacionais dependem de uma `turma_id` válida para funcionar corretamente. A exclusão ou alteração de uma turma gera impacto direto em pelo menos **14 módulos** e **40+ tabelas relacionadas** no banco de dados.

### Premissas de contexto

Toda turma existe sempre dentro de dois contextos obrigatórios:
- `configuracao_id` — identifica a franquia (escola) proprietária da turma
- `ano_id` — identifica o ano letivo ao qual a turma pertence

Esses dois campos atuam como filtros de multi-tenancy em **todos** os módulos que consomem dados de turma. Nenhuma operação entre módulos ocorre fora desse escopo.

### Categorias de vínculo

Os módulos vinculados ao módulo Turmas se dividem em três categorias:

**Dependência direta (FK turma_id):** O módulo possui uma chave estrangeira `turma_id` na sua tabela principal. A exclusão de uma turma impacta diretamente esses registros.

**Dependência indireta:** O módulo acessa dados de turma por meio de outro módulo intermediário (ex: acessa via matrícula ou via gestão de aula).

**Dependência de configuração:** O módulo usa dados da turma (como `curso_id`, `sistema_bncc_id`, `notifiq`, `fechada`) para determinar seu comportamento, mas não armazena `turma_id` em sua tabela.

---

## 2. Mapa de Relacionamentos

O diagrama abaixo representa o grafo de dependências do módulo Turmas. Cada seta indica direção do vínculo (quem depende de quem):

```
Ano ─────────────────────┐
Franquia (Configuracao) ──┤
Turno ────────────────────┤
Serie ─────────────────── TURMA ────── Matricula ─── Aluno
Curso ────────────────────┤                  │
CircuitoNota ─────────────┘                  ├── NotaCircuito
                                             ├── Acompanhamento
                          ├── GestaoDeAula ──┼── Aula ─── Presença
                          │                  │       └── PlanoDeAula
                          │                  └── GestaoAuxiliar
                          │
                          ├── Nota / Avaliacao
                          ├── NotaGlobal
                          ├── Agenda
                          ├── Aviso
                          ├── MotivoFalta (Bolsa Família)
                          ├── Horario
                          ├── BNCC / SistemaBNCC
                          ├── EducacaoInclusiva
                          └── Hikvision
```

### Totais

- Modelos Eloquent com FK turma_id: **14**
- Controllers que recebem turma_id: **18**
- Rotas API com parâmetro turma_id: **40+**
- Migrations com coluna turma_id: **15**
- Services backend vinculados: **28+**
- Services frontend vinculados: **12**
- Páginas Vue com turma_id: **16+**
- Componentes Vue com turma_id: **15+**

---

## 3. Módulo: Matrículas

### Tipo de vínculo
Dependência direta. A tabela `matriculas` possui FK `turma_id` referenciando `turmas.id`.

### Relacionamento Eloquent (backend)
O modelo `Matricula` declara `belongsTo(Turma::class)` com chave `turma_id`. O modelo `Turma` declara `hasMany(Matricula::class)`.

### Arquivos backend
- `app/Models/Matricula.php` — modelo com relacionamento `turma()`
- `app/Http/Controllers/MatriculasController.php` — operações de CRUD de matrícula recebendo `turma_id`
- `database/migrations/2023_05_17_153748_create_matriculas_table.php` — campo `turma_id` FK

### Arquivos frontend
- `src/Services/MatriculasService.js` — métodos que passam `turma_id` nas requisições
- `src/Pages/Matriculas/NewEditMatriculaPage.vue` — formulário de criação/edição de matrícula com seleção de turma
- `src/components/Matriculas/ESnippetMatricula.vue` — exibe matrícula com referência à turma
- `src/components/Matriculas/EModalTransferirMatricula.vue` — permite transferência de aluno entre turmas; recebe `turma_id` de origem e de destino
- `src/components/Alunos/EDrawerListarMatriculas.vue` — lista matrículas de um aluno com respectiva turma

### Campos trafegados
`turma_id`, `aluno_id`, `ano_id`, `configuracao_id`, `situacao` (CURSANDO, TRANSFERIDO, CANCELADO, FORMADO)

### Impacto em cascata
A turma só pode ser fechada se todas as matrículas tiverem situação final definida. Matrículas em situação CURSANDO bloqueiam o fechamento da turma quando o circuito de notas exige resultado final.

---

## 4. Módulo: Gestão de Aulas

### Tipo de vínculo
Dependência direta. A tabela `gestao_de_aulas` (ou equivalente) possui FK `turma_id`.

### Descrição
Gestão de Aula representa o vínculo entre um professor, uma disciplina e uma turma. É o registro que autoriza o professor a lançar aulas e notas para aquela turma. Toda aula registrada obrigatoriamente passa por uma gestão de aula.

### Submodulos

**GestaoDeAula principal:**
- `app/Models/GestaoDeAula.php` — modelo com `turma_id`, `professor_id`, `disciplina_id`; relacionamento `turma()` via `belongsTo`
- `app/Http/Controllers/GestoesDeAulasController.php` — métodos `listarGestaoDeAulasDaTurma()`, `visualizarTurma()`, `visualizarTurmaGestao()`
- `src/Services/GestoesDeAulasService.js` — chamadas à API passando `turma_id`
- `src/Pages/GestaoDeAulas/NewEditGestaoDeAulaPage.vue` — formulário de criação com campo `turma_id`

**GestaoDeAulaAuxiliar (professor auxiliar/polivalente):**
- `app/Models/GestaoDeAulaAuxiliar.php` — modelo com FK `turma_id`; tabela `instrutor_auxiliar_disciplina_turma`
- `app/Http/Controllers/GestoesDeAulasAuxiliaresController.php` — métodos `listarGestaoDeAulasDaTurma()`, `visualizarTurma()`
- `src/Services/GestoesDeAulasAuxiliaresService.js`
- `src/Pages/GestaoDeAulasAuxiliares/NewCreateGestaoDeAuxiliares.vue`

**InstrutorDisciplinaTurma:**
- `app/Models/InstrutorDisciplinaTurma.php` — tabela pivot `instrutor_disciplina_turma` com FK `turma_id`

### Arquivos de migrations
- `database/migrations/2023_05_18_161746_create_instrutor_disciplina_turma_table.php`
- `database/migrations/2023_05_18_162659_create_instrutor_turma_table.php`
- `database/migrations/2024_01_18_143355_create_instrutor_auxiliar_disciplina_turma_table.php`

### Impacto em cascata
Ao deletar uma turma, as gestões de aulas vinculadas perdem a referência. As aulas já registradas por essas gestões também ficam órfãs. O sistema usa soft delete na turma justamente para evitar esse tipo de ruptura de integridade.

---

## 5. Módulo: Aulas e Frequência

### Tipo de vínculo
Dependência direta via FK `turma_id` e dependência indireta via `gestao_de_aula_id`.

### Descrição
Cada aula registrada pertence a uma gestão de aula (que por sua vez pertence a uma turma). O sistema também permite consultar aulas diretamente por `turma_id` para fins de conflito de horário, planejamento e presença.

### Arquivos backend
- `app/Models/Aula.php` — modelo com `turma_id` fillable, relacionamento `turma()` via `belongsTo`
- `app/Http/Controllers/AulasController.php` — método `pesquisaConflitos()` recebe `turma_id` como parâmetro de rota para verificar se existe outra aula no mesmo horário na mesma turma; também `pesquisaConflitosPolivalencia()`
- `app/Http/Controllers/AulaConflitoController.php` — verificação de conflito de aula com `turma_id`
- `app/Services/AulaService.php` — lógica de negócios de aula com `turma_id`
- `app/Services/AulaConflitoService.php` — verificação de conflito com `turma_id`
- `app/Services/Aulas/RecuperarAulasPorSituacao/RecuperarAulasPorSituacaoService.php` — filtra aulas por turma e situação
- `app/Services/Aulas/PlanejamentoAulas/ListarPlanejamentoAulasService.php` — planejamento de aulas por turma
- `database/migrations/2023_05_18_111120_create_aulas_table.php` — campo `turma_id` com índice FK

### Submodulo: AulaInfantil
- `app/Models/AulaInfantil.php` — modelo com `turma_id` fillable, tabela `aulasinfantis`
- Usado quando `turma.isInfantil = true` (curso_id = 1)

### Arquivos frontend
- `src/Services/AulasService.js` — chamadas à API com `turma_id`
- `src/components/Aulas/EModalDuplicarAula.vue` — duplica aula de uma turma para outra; recebe `turma_id` de origem
- `src/components/Aulas/EModalExportarAula.vue` — exporta aula da turma
- `src/components/Aulas/EModalDuplicarAulaPolivalencia.vue` — duplicação para turmas polivalentes
- `src/components/Aulas/EModalExportarAulaPolivalencia.vue`
- `src/components/Aulas/EModalDuplicarAulaInfantil.vue` — específico para turmas infantis

### Rotas API relevantes
- `GET /verificar-aula-existente/{data}/{horario_id}/{turma_id}/{aula_id?}` — verifica conflito de aula na turma
- `GET /verificar-aula-existente/polivalencia/{data}/{horario_id}/{turma_id}/{aula_id?}` — verifica conflito polivalente

### Regra de negócio crítica
Antes de registrar uma aula, o sistema verifica se já existe outra aula no mesmo `turma_id`, `horario_id` e `data`. Se existir, o registro é bloqueado para evitar conflito de horário.

---

## 6. Módulo: Notas e Avaliações

### Tipo de vínculo
Dependência direta. As tabelas `notas`, `notas_globais` e `avaliacoes` possuem FK `turma_id`.

### Submodulo: Notas do Circuito (NotaCircuito)
- `app/Models/NotaCircuito.php` — modelo com FK `turma_id`; tabela `notas` (ver migration abaixo)
- Campo `turma_id` fillable; relacionamento `turma()` via `belongsTo`
- `app/Http/Controllers/NotasController.php` — operações de CRUD de nota com `turma_id`
- `src/Services/NotasService.js` — chamadas à API com `turma_id`
- Migration: `database/migrations/circuito/2023_05_16_094912_create_notas_table.php`

### Submodulo: Notas Globais (NotaGlobal)
- `app/Models/NotaGlobal.php` — modelo com FK `turma_id`
- Representa a média consolidada do aluno na turma
- Migration: `database/migrations/circuito/2023_06_15_150420_create_notas_globais_table.php`

### Submodulo: Avaliações (Nota/Avaliacoes)
- `app/Models/Nota.php` — modelo com FK `turma_id`; tabela `avaliacoes`
- `database/migrations/2023_05_18_091231_create_avaliacoes_table.php` — campo `turma_id` FK

### Impacto em cascata
O dashboard da turma (`/turmas/:id/metricas`) consome notas da turma para calcular: média geral, melhores alunos, acompanhamentos. A visualização de notas exige `turma_id` válido.

---

## 7. Módulo: Circuito de Notas / Etapas

### Tipo de vínculo
Dependência de configuração e dependência direta. O modelo `CircuitoNota` possui `hasMany(Turma)`. A turma possui FK `circuito_id` (ou relacionamento via `circuito()`).

### Descrição
O Circuito de Notas define a estrutura de avaliação da turma: quais bimestres/etapas existem, quais sub-etapas, e qual é a etapa de RESULTADO FINAL. O fechamento de uma turma depende diretamente de que o circuito vinculado possua uma etapa com `tipo = RESULTADO FINAL` e que o `periodo_inicial` dessa etapa já tenha passado.

### Arquivos backend
- `app/Models/CircuitoNota.php` — modelo com método `turmas()` (hasMany)
- `app/Http/Controllers/EtapasController.php` — método `etapasBimestrais($turma_id)` retorna as etapas vinculadas à turma
- `app/Services/EtapaService.php` — serviço com lógica de etapas por turma
- `app/Services/SubetapaService.php` — subetapas por turma

### Arquivos frontend
- `src/Services/EtapasService.js` — chamadas com `turma_id`
- `src/Pages/Turmas/index.vue` — função `podeFecharTurma()` verifica: (1) turma tem circuito; (2) circuito tem etapa RESULTADO FINAL; (3) `periodo_inicial <= data atual`

### Rota API relevante
- `GET /etapas-bimestrais/{turma_id}` — retorna etapas do circuito da turma

### Regra de negócio crítica
Se uma turma não tiver circuito de notas vinculado, a função `podeFecharTurma()` retorna `false` e o botão de fechar fica desabilitado. Essa é a principal pré-condição para o fluxo de fechamento de turma.

---

## 8. Módulo: Agenda

### Tipo de vínculo
Dependência direta. A tabela `agendas` possui FK `turma_id`.

### Descrição
Agendas são eventos/atividades programadas para uma turma específica. São visualizadas pelo app mobile Notifiq pelos responsáveis dos alunos daquela turma.

### Arquivos backend
- `app/Models/Agenda.php` — modelo com `turma_id` fillable, relacionamento `turma()` via `belongsTo`
- `database/migrations/2023_05_18_110038_create_agendas_table.php` — campo `turma_id` FK

### Arquivos backend (Notifiq)
- `app/Http/Controllers/Notifiq/AgendaController.php` — métodos:
  - `agendasSemana($turma_id)` — retorna agendas da semana para a turma
  - `agendaDoMes($turma_id?, $mes?)` — retorna agendas do mês
  - `indexAgendaTurma()` — lista agendas por turma
  - `buscarAgendaDiariaPorTurma()` — busca agenda do dia por turma

### Arquivos frontend
- `src/Services/AgendaService.js` — chamadas à API com `turma_id`
- `src/Pages/Agenda/newEditAgenda.vue` — formulário com campo `turma_id`

### Rotas API relevantes (Notifiq)
- `GET /agendas-da-semana/{turma_id}`
- `GET /agendas-do-mes/{turma_id?}/{mes?}`
- `GET /turma/{turmaId}`

---

## 9. Módulo: Avisos

### Tipo de vínculo
Dependência direta. A tabela `avisos` possui FK `turma_id`.

### Descrição
Avisos são comunicados enviados pela escola para as turmas. Um aviso pode ser enviado para uma turma específica ou para múltiplas turmas. O campo `turma_id` é usado quando o aviso é direcionado a uma única turma; caso seja para múltiplas, o modelo armazena um array de IDs.

### Arquivos backend
- `app/Models/Aviso.php` — modelo com `turma_id` fillable, relacionamento `turma()` via `belongsTo`; também possui campo array `turmas` para múltiplos destinatários
- `database/migrations/2023_05_18_113456_create_avisos_table.php` — campo `turma_id` FK

### Arquivos backend (Notifiq)
- `app/Http/Controllers/Notifiq/AvisosController.php` — métodos:
  - `avisosMobile($turma_id)` — retorna avisos para o mobile da turma
  - `todosAvisos($turma_id)` — retorna todos os avisos da turma
  - `avisosPorLimite($turma_id)` — retorna avisos com limite

### Arquivos frontend
- `src/Services/AvisosService.js`
- `src/Pages/Avisos/newEditAvisos.vue` — campo `turma_id` no formulário

### Rotas API relevantes (Notifiq)
- `GET /avisos-mobile/{turma_id}`
- `GET /avisos-limit/{turma_id}`
- `GET /todos-avisos/{turma_id}`

---

## 10. Módulo: Bolsa Família

### Tipo de vínculo
Dependência direta. A tabela `motivo_falta` possui FK `turma_id`. O módulo também consome dados calculados por turma via SQL.

### Descrição
O módulo Bolsa Família rastreia a frequência dos alunos para fins de conformidade com o programa social federal. A frequência mínima exigida é definida em `cursos.frequencia_minima`. O sistema calcula bimestralmente: quantidade de aulas, faltas e percentual de frequência por aluno por mês, sempre filtrado por `turma_id`.

### Submodulo: MotivoFalta
- `app/Models/MotivoFalta.php` — modelo com FK `turma_id` e FK `matricula_id`; tabela `motivo_falta`
- `database/migrations/2025_06_09_144006_create_motivo_falta_table.php`

### Arquivos backend
- `app/Services/TurmaService.php` — método estático `bolsaFamilia()` executa SQL para calcular `qtd_aulas`, `qtd_faltas`, `percentual_frequencia` por aluno por mês; filtra alunos fictícios "Aluno 01" e "Aluno 02" para usuários não super-admin
- `app/Http/Controllers/TurmasController.php` — métodos `bolsaFamilia()` e `motivosFaltas($turma_id, $mes_1, $mes_2)` e `motivosFaltasPdf()`

### Arquivos frontend
- `src/Pages/Turmas/TurmasBolsaFamilia.vue` — interface com 5 grupos bimestrais: Fev/Mar, Abr/Mai, Jun/Jul, Ago/Set, Out/Nov; campo de motivo de falta desabilitado quando `percentual_frequencia >= frequencia_minima`
- `src/Services/TurmasService.js` — métodos `pegarMotivosFaltas(turma_id, mes_1, mes_2)`, `salvarMotivosFaltas(data)`, `gerarRelatorioFrequenciaBolsaFamilia(turma_id, mes_1, mes_2)`

### Rotas API relevantes
- `POST /turmas/bolsa-familia` — calcula frequência com `{turma_id, mes_1, mes_2}`
- `GET /turmas/bolsa-familia/motivos-faltas/{turma_id}/{mes_1}/{mes_2}` — lista motivos de falta
- `POST /turmas/bolsa-familia/salvar-motivos-faltas` — salva motivo com `{codigo, turma_id, matricula_id, mes}`
- `GET /turmas/bolsa-familia/motivos-faltas/{turma_id}/{mes_1}/{mes_2}/pdf` — gera PDF do relatório

---

## 11. Módulo: Relatórios

### Tipo de vínculo
Dependência de consulta. O módulo Relatórios não armazena `turma_id`, mas recebe como parâmetro de rota para gerar documentos PDF.

### Relatórios disponíveis por turma
- **Lista da Turma** — PDF com todos os alunos matriculados na turma
- **Boletim Geral** — PDF com notas de todos os alunos da turma por disciplina
- **Resultado por Disciplinas** — PDF analítico de desempenho por disciplina
- **Relatório BNCC Turma** — PDF com avaliação BNCC dos alunos da turma (disponível apenas quando `sistema_bncc_id != 1`)
- **Relatório Semestral BNCC** — versão semestral do relatório BNCC
- **Diário de Classe** — gerado na aba "Diários Relacionados" da view da turma; um diário por gestão de aula
- **Relatório Frequência Bolsa Família** — PDF de frequência para o programa Bolsa Família

### Arquivos backend
- `app/Http/Controllers/RelatoriosController.php` — métodos: `listarTurma($turma)`, `boletimGeral($turma)`, `resultadoPorDisciplinas($turma)`, `relatorioBNCCTurma($turmaId)`, `relatorioSemestralBNCCTurma($turmaId)`
- `app/Services/Relatorios/UsoDoSistema/RelatorioUsoDoSistemaResumido.php` — relatório de uso com `turma_id`
- `app/Services/Boletim/GetBoletinsFranquia/GetBoletinsFranquiaService.php` — boletins por franquia filtrado por turma

### Arquivos frontend
- `src/Services/RelatoriosService.js` — métodos de geração de PDF com `turma_id`
- `src/Pages/Relatorios/ListarTurmaPage.vue` — listagem de relatórios disponíveis por turma
- `src/Pages/Turmas/view.vue` — botões de PDF condicionados por `isHidden = (sistema_bncc_id === 1)`:
  - Se `isHidden = false` (sistema BNCC): exibe botões de relatório BNCC
  - Se `isHidden = true` (sistema padrão): exibe botões de boletim e diário convencional

### Rotas API relevantes
- `GET /listarTurma/{turma}` — gera PDF da lista da turma
- `GET /boletimGeral/{turma}` — gera PDF do boletim geral
- `GET /resultado-por-disciplinas/{turma}` — gera PDF de resultado por disciplinas
- `GET /relatorio-bncc/{turmaId}/turma` — gera PDF de BNCC por turma
- `GET /relatorio-semestral-bncc/{turmaId}/turma` — gera PDF semestral BNCC

---

## 12. Módulo: BNCC

### Tipo de vínculo
Dependência de configuração. O campo `sistema_bncc_id` na tabela `turmas` determina se a turma segue o padrão BNCC ou o padrão convencional de avaliação.

### Descrição
A Base Nacional Comum Curricular (BNCC) é o padrão curricular nacional brasileiro. Quando uma turma tem `sistema_bncc_id` diferente de 1, toda a interface de notas, relatórios e avaliações muda para o formato BNCC com descritores e habilidades específicas.

### Campos relevantes na tabela turmas
- `sistema_bncc_id` — FK para tabela `sistema_bncc`; determina o regime de avaliação
- `curso_id` — determina se BNCC está disponível (verificado via `idsCursosComBNCC` no frontend)

### Arquivos backend
- `app/Http/Controllers/SistemaBNCCController.php` — operações BNCC com `turma_id`
- `app/Http/Controllers/SistemaBNCCSemestralController.php` — versão semestral com `turma_id`

### Arquivos frontend
- `src/Pages/Turmas/NewEditTurmaPage.vue` — campo `sistema_bncc_id` condicional: visível e obrigatório apenas para cursos em `idsCursosComBNCC`; exibido como select com opções de sistemas
- `src/Pages/Turmas/view.vue` — constante `isHidden = (payload.turma.sistema_bncc_id === 1)` controla quais botões de relatório aparecer

### Componentes frontend
- `src/components/Franquias/EModalBnccFranquia.vue` — modal de avaliação BNCC por turma/franquia

---

## 13. Módulo: Horários

### Tipo de vínculo
Dependência de consulta. O módulo Horários recebe `turma_id` para listar horários disponíveis do turno da turma.

### Descrição
Antes de registrar uma aula, o professor seleciona o horário. O sistema filtra os horários disponíveis baseado no turno da turma (`turno_id`). A consulta é feita passando `turma_id`, e o service busca o turno associado.

### Arquivos backend
- `app/Http/Controllers/HorariosController.php` — método `listarHorariosDoTurnoDaTurma($turma_id)`: busca a turma pelo ID, extrai o `turno_id`, retorna os horários daquele turno
- `app/Services/Horarios/ListarHorariosDoTurnoDaTurmaService.php` — service específico para esse fluxo

### Arquivos frontend
- `src/Services/HorariosService.js` — chamada à API com `turma_id`

### Rota API relevante
- `GET /horarios-do-turno-da-turma/{turma_id}` — retorna horários disponíveis para a turma

---

## 14. Módulo: Notifiq (App Mobile)

### Tipo de vínculo
Dependência direta e de configuração. O campo `notifiq` (int) na tabela `turmas` habilita funcionalidades do app Notifiq para a turma. Vários endpoints do Notifiq recebem `turma_id`.

### Descrição
O Notifiq é o aplicativo mobile para pais e responsáveis. Quando `turma.notifiq = 1`, a turma recebe o chip visual "NOTIFIQ" na listagem e habilita: RFID, presenças em tempo real, push notifications, visualização de agenda e avisos pelo app.

### Submodulo: Presenças Mobile
- `app/Http/Controllers/Notifiq/PresencaController.php` — método `frenquenciaPelasGestoes($turma_id?, $mes?, $matricula_id?)` retorna frequência por gestões da turma para o app
- Rota: `GET /frequencia-gestoes/{turma_id?}/{mes?}/{matricula_id?}`

### Submodulo: Gestão Mobile
- `app/Http/Controllers/Notifiq/NotifiqController.php` — operações gerais Notifiq com `turma_id`
- `app/Services/notifiq/gestaoService.php` — service de gestão mobile com `turma_id`
- `app/Services/notifiq/aulasServices.php` — service de aulas mobile com `turma_id`
- `app/Services/notifiq/matriculasService.php` — service de matrículas mobile com `turma_id`

### Submodulo: NotifiqProfessor
- `app/Services/NotifiqProfessor/ListarMatriculasPorArrayDeTurmas.php` — lista matrículas passando array de `turma_id`
- `app/Services/NotifiqProfessor/ListarGestoesService.php` — gestões por turma para o professor no app

### Campo de habilitação
- `turma.notifiq = 1` — habilita RFID, push, presenças mobile
- `turma.notifiq = 0` — desabilita funcionalidades mobile; coluna RFID oculta na view da turma

### Arquivos frontend
- `src/Pages/Turmas/index.vue` — chip visual "NOTIFIQ" exibido quando `turma.notifiq = true`
- `src/Pages/Turmas/view.vue` — coluna RFID visível apenas quando `turma.notifiq = true`

---

## 15. Módulo: Franquias / Configuração

### Tipo de vínculo
Dependência estrutural. O campo `configuracao_id` na tabela `turmas` vincula cada turma a uma franquia. Toda turma pertence obrigatoriamente a uma franquia.

### Arquivos backend
- `app/Models/Configuracao.php` / `app/Models/Franquia.php` — modelos com método `turmas()` (hasMany)
- `app/Http/Controllers/FranquiasController.php` — operações que listam turmas por franquia
- `app/Http/Controllers/TurmasController.php` — método `listAll()` filtra por `configuracao_id` do usuário autenticado via `getFranquia()`

### Arquivos frontend
- `src/Services/TurmasService.js` — métodos `listarTurmasFranquia(franquia)`, `buscarTurmasPorFranquia(franquia_id)`, `listarTurmasFranquiaSelect(form)`, `listarTurmasFundamentalEInfantilFranquia(franquia)`, `listarTurmasInfantisFranquia(franquia)`
- `src/components/Franquias/EModalTurmasFranquia.vue` — modal de seleção de turmas por franquia
- `src/components/Franquias/EFranquiaSnippetCard.vue` — card da franquia com contador de turmas
- `src/components/Franquias/EModalBoletimFranquia.vue` — boletins por turma/franquia
- `src/components/Franquias/EModalBnccFranquia.vue` — BNCC por turma/franquia

### Rotas API relevantes
- `POST /turmas/listar-turmas-franquia` — lista turmas de uma franquia
- `POST /turmas/listar-turmas-franquia-select` — lista para select
- `POST /turmas/listar-turmas-franquia-fundamental-e-infantil` — filtra por tipo de ensino
- `POST /turmas/listar-turmas-infantis-franquia` — apenas turmas infantis
- `GET /turmas/turmas-franquia/{franquia_id}` — busca por ID de franquia
- `GET /turmas/retirarFiltroFranquia` — lista geral sem filtro de franquia (super-admin)

---

## 16. Módulo: Anos Letivos

### Tipo de vínculo
Dependência estrutural. O campo `ano_id` na tabela `turmas` vincula cada turma a um ano letivo.

### Arquivos backend
- `app/Models/Ano.php` — modelo com método `turmas()` (hasMany)
- Toda query de turma sempre filtra por `ano_id` via helper `getAno()`

### Impacto
Ao trocar o ano letivo ativo no perfil do usuário, toda a listagem de turmas muda automaticamente. Turmas de anos anteriores são acessíveis apenas navegando para o contexto do ano correspondente.

---

## 17. Módulo: Séries / Cursos / Turnos

### Tipo de vínculo
Dependência estrutural. A turma possui FK para `serie_id`, `curso_id` e `turno_id`.

### Submodulo: Séries
- `app/Models/SerieTurma.php` — tabela pivot `serie_turma` com FK `turma_id`; suporta turmas multi-série (campo `multi = true` quando `series.count > 1`)
- `database/migrations/2023_05_19_155326_create_serie_turma_table.php`
- `app/Http/Controllers/SeriesController.php` — método `getSerieIdAlunoInformacao($turmaId)` busca série da turma para informações do aluno

### Submodulo: Cursos
- `cursos.frequencia_minima` — campo do curso usado pelo módulo Bolsa Família para calcular se aluno está abaixo da frequência mínima
- `cursos.id` — campo `idsCursosComBNCC` no frontend verifica se o curso da turma suporta BNCC

### Submodulo: Turnos
- `app/Models/Turno.php` — modelo com método `turmas()` (hasMany)
- O `turno_id` da turma é a base para listar horários disponíveis no módulo Horários

---

## 18. Módulo: Professores

### Tipo de vínculo
Dependência indireta. Professores não armazenam `turma_id` diretamente, mas são vinculados a turmas através de `GestaoDeAula`.

### Arquivos backend
- `app/Http/Controllers/ProfessoresController.php` — operações que buscam turmas de um professor via gestões de aula

### Arquivos frontend
- `src/components/Professores/EEvento.vue` — evento do professor com referência à turma

### Submodulo: NotifiqProfessor
- `app/Services/NotifiqProfessor/ListarMatriculasPorArrayDeTurmas.php` — o professor recebe array de `turma_id` das suas gestões e lista matrículas
- `app/Services/NotifiqProfessor/ListarGestoesService.php` — gestões do professor filtradas por turma

---

## 19. Módulo: Alunos

### Tipo de vínculo
Dependência indireta. Alunos são vinculados a turmas através de `Matricula`. O sistema nunca vincula aluno diretamente à turma sem uma matrícula.

### Arquivos backend
- `app/Http/Controllers/TurmasController.php` — métodos `pegarMatriculas($turma_id)` e `listarAlunosPorTurma()` retornam alunos da turma via matrículas

### Arquivos frontend
- `src/Pages/Turmas/view.vue` — tab 0 "Lista da Turma" exibe alunos matriculados; coloração de linhas:
  - `red lighten-4` — aluno em situação adversa (suspenso, etc.)
  - `blue_light` — aluno PcD (Pessoa com Deficiência)
- `src/components/Alunos/EDrawerListarMatriculas.vue` — drawer com matrículas do aluno por turma

### Regra: Alunos Fictícios
Os registros "Aluno 01" e "Aluno 02" são alunos fictícios usados para testes internos. Em todas as queries de melhores alunos e bolsa família, esses registros são filtrados automaticamente para usuários sem perfil super-admin.

---

## 20. Módulo: Pendências

### Tipo de vínculo
Dependência de consulta. O módulo Pendências analisa turmas sem gestões de aula, sem aulas registradas ou com outras condições pendentes.

### Arquivos backend
- `app/Services/Pendencias/OrganizarPendenciasFranquiaService.php` — organiza pendências por turma dentro da franquia
- `app/Services/Pendencias/GetPendenciasDaFranquia/GetPendenciasDaFranquiaService.php` — busca pendências da franquia com `turma_id`

### Arquivos frontend
- `src/Pages/GestaoDeAulas/Pendencias/PendenciasPage.vue` — lista pendências por turma com `turma_id`

---

## 21. Módulo: Usabilidade do Sistema

### Tipo de vínculo
Dependência de consulta. O módulo de Usabilidade rastreia métricas de uso por turma.

### Arquivos backend
- `app/Services/Usabilidade/GetUsabilidadeDaTurma/GetUsabilidadeDaTurmaService.php` — calcula usabilidade da turma
- `app/Services/Usabilidade/Relatorios/PrepararDadosRelatorioUsabilidadeService.php` — prepara dados para relatório com `turma_id`
- Outros services em `app/Services/Usabilidade/*`

### Arquivos frontend
- `src/Pages/AdminPage/Usabilidade/UsabilidadeDoSistemaProfessorPage.vue` — usabilidade do professor por turma
- `src/Pages/AdminPage/Usabilidade/UsabilidadeDoSistemaCoordenadorPage.vue` — usabilidade da coordenação por turma

---

## 22. Módulo: Hikvision (Controle de Acesso)

### Tipo de vínculo
Dependência de configuração. O módulo Hikvision usa dados de turma para configurar controle de acesso por RFID, especialmente quando `turma.notifiq = 1`.

### Arquivos backend
- `app/Http/Controllers/HikController.php` — integração com hardware Hikvision; acessa turmas para configurar permissões de acesso
- `app/Http/Controllers/HikvisionConfigController.php` — configurações do sistema Hikvision por turma

### Arquivos frontend
- `src/Pages/Turmas/view.vue` — coluna RFID visível quando `turma.notifiq = true`

---

## 23. Módulo: Educação Inclusiva

### Tipo de vínculo
Dependência direta. O módulo Educação Inclusiva vincula alunos PcD a turmas especiais.

### Arquivos backend
- `app/Http/Controllers/TurmasController.php` — endpoint `GET /turmas/turmas-especias/inclusiva` lista turmas com `tipo_de_atendimento` específico para educação inclusiva
- `src/Services/TurmasService.js` — método `listTurmasEspecias()` chama esse endpoint

### Arquivos frontend
- `src/Pages/EducacaoInclusiva/NewEditEducacaoInclusivaPage.vue` — formulário vincula aluno PcD a turma com `turma_id`
- `src/Pages/Turmas/view.vue` — alunos PcD destacados com cor `blue_light` na lista da turma

### Campo relevante na turma
- `tipo_de_atendimento` — campo da tabela `turmas` que identifica turmas de educação especial/inclusiva

---

## 24. Módulo: Importação de Dados

### Tipo de vínculo
Dependência de escrita. O módulo de importação cria turmas em massa via planilha.

### Arquivos backend
- `app/Services/ImportServices.php` — service de importação com suporte à entidade `turma`; cria registros em `turmas` a partir de dados externos

### Rota API relevante
- `POST /importar-dados/turma/{ano?}` — importa turmas para um ano letivo

---

## 25. Tabela de Migrations com turma_id

As seguintes migrations criam colunas `turma_id` que referenciam a tabela `turmas`:

- `2023_05_17_153748_create_matriculas_table.php` — tabela `matriculas`
- `2023_05_18_091231_create_avaliacoes_table.php` — tabela `avaliacoes`
- `2023_05_18_105714_create_acompanhamentos_table.php` — tabela `acompanhamentos`
- `2023_05_18_110038_create_agendas_table.php` — tabela `agendas`
- `2023_05_18_111120_create_aulas_table.php` — tabela `aulas`
- `2023_05_18_113456_create_avisos_table.php` — tabela `avisos`
- `2023_05_18_161746_create_instrutor_disciplina_turma_table.php` — tabela `instrutor_disciplina_turma`
- `2023_05_18_162659_create_instrutor_turma_table.php` — tabela `instrutor_turma`
- `2023_05_18_164037_create_leciona_table.php` — tabela `leciona`
- `2023_05_19_155326_create_serie_turma_table.php` — tabela `serie_turma`
- `2023_05_19_164945_create_testeseletivos_table.php` — tabela `testeseletivos`
- `2024_01_18_143355_create_instrutor_auxiliar_disciplina_turma_table.php` — tabela `instrutor_auxiliar_disciplina_turma`
- `2025_06_09_144006_create_motivo_falta_table.php` — tabela `motivo_falta`
- `circuito/2023_05_16_094912_create_notas_table.php` — tabela `notas`
- `circuito/2023_06_15_150420_create_notas_globais_table.php` — tabela `notas_globais`

---

## 26. Inventário de Rotas API Dependentes

### Rotas do próprio módulo Turmas (`routes/turmas.php`)
- `GET /turmas` — lista todas as turmas (middleware: `can:turmas.listar`)
- `GET /turmas/listall/paginate` — lista paginada com busca
- `GET /turmas/retirarFiltroFranquia` — lista sem filtro de franquia
- `POST /turmas` — cria turma (middleware: `can:turmas.criarTurma`)
- `PUT /turmas/{turma_id}` — atualiza turma (middleware: `can:turmas.atualizarTurma`)
- `DELETE /turmas/{turma_id}` — exclui turma (soft delete)
- `GET /turmas/visualizar/{turma_id}` — detalhes da turma (middleware: `can:turmas.visualizarTurma`)
- `GET /turmas/visualizar/{turma_id}/metricas` — dashboard da turma
- `GET /turmas/pegar-matriculas/{turma_id}` — matrículas da turma
- `GET /turmas/turmas-especias/inclusiva` — turmas de educação inclusiva
- `GET /turmas/qtd` — quantidade de turmas da franquia
- `GET /turmas/taxa-ocupacao` — taxa de ocupação
- `POST /turmas/notas/metricas` — métricas de notas
- `POST /turmas/medias/metricas` — métricas de médias
- `POST /turmas/melhores-alunos/metricas` — melhores alunos
- `POST /turmas/melhores-alunos/metricas-gestao` — melhores alunos por gestão
- `POST /turmas/acompanhamentos/metricas` — acompanhamentos
- `POST /turmas/{turma_id}/fechar` — fecha turma
- `POST /turmas/{turma_id}/abrir` — abre turma
- `GET /turmas/{turmaId}/disciplinas` — disciplinas da turma
- `POST /turmas/listar-turmas-franquia` — turmas por franquia
- `POST /turmas/listar-turmas-franquia-select` — turmas para select
- `POST /turmas/listar-turmas-franquia-fundamental-e-infantil` — fundamental e infantil
- `POST /turmas/listar-turmas-infantis-franquia` — apenas infantis
- `GET /turmas/turmas-franquia/{franquia_id}` — turmas por franquia_id
- `POST /turmas/bolsa-familia` — dados de frequência bolsa família
- `GET /turmas/bolsa-familia/motivos-faltas/{turma_id}/{mes_1}/{mes_2}` — motivos de falta
- `POST /turmas/bolsa-familia/salvar-motivos-faltas` — salva motivo de falta
- `GET /turmas/bolsa-familia/motivos-faltas/{turma_id}/{mes_1}/{mes_2}/pdf` — PDF frequência

### Rotas de módulos dependentes (turma_id como parâmetro)
- `GET /etapas-bimestrais/{turma_id}` — módulo Etapas
- `GET /horarios-do-turno-da-turma/{turma_id}` — módulo Horários
- `GET /verificar-aula-existente/{data}/{horario_id}/{turma_id}/{aula_id?}` — módulo Aulas
- `GET /verificar-aula-existente/polivalencia/{data}/{horario_id}/{turma_id}/{aula_id?}` — módulo Aulas
- `POST /listar-gestoes-aulas-turma` — módulo GestaoDeAulas
- `GET /listarTurma/{turma}` — módulo Relatórios
- `GET /boletimGeral/{turma}` — módulo Relatórios
- `GET /resultado-por-disciplinas/{turma}` — módulo Relatórios
- `GET /relatorio-bncc/{turmaId}/turma` — módulo BNCC
- `GET /relatorio-semestral-bncc/{turmaId}/turma` — módulo BNCC

### Rotas Notifiq com turma_id
- `GET /avisos-mobile/{turma_id}` — Notifiq Avisos
- `GET /avisos-limit/{turma_id}` — Notifiq Avisos
- `GET /todos-avisos/{turma_id}` — Notifiq Avisos
- `GET /agendas-da-semana/{turma_id}` — Notifiq Agenda
- `GET /agendas-do-mes/{turma_id?}/{mes?}` — Notifiq Agenda
- `GET /turma/{turmaId}` — Notifiq Agenda
- `GET /frequencia-gestoes/{turma_id?}/{mes?}/{matricula_id?}` — Notifiq Presenças

---

## 27. Inventário de Rotas Frontend (Vue Router)

Arquivo: `src/router/turmas.js`

- `GET /turmas/` — nome: `turmas` — componente: `TurmasIndexPage`
- `GET /turmas/create` — nome: `turmas.create` — componente: `NewEditTurmaPage` (prop editing: false)
- `GET /turmas/edit/:turma_id` — nome: `turmas.edit` — componente: `NewEditTurmaPage` (prop editing: true)
- `GET /turmas/view/:turma_id` — nome: `turmas.view` — componente: `TurmasViewPage`
- `GET /turmas/:id/metricas` — nome: `turmas.dashboard` — componente: `TurmasDashboard`
- `GET /turmas/:id/bolsa-familia` — nome: `turmas.bolsa_familia` — componente: `TurmasBolsaFamilia`

---

## 28. Impacto em Cascata — Regras de Negócio Críticas

Esta seção descreve os cenários em que a alteração de dados de uma turma gera impacto automático em outros módulos.

### Impacto 1: Soft Delete de Turma
Ao deletar uma turma (soft delete), os seguintes dados ficam órfãos mas não são excluídos:
- Matrículas com `turma_id` apontando para a turma deletada
- Gestões de aula com `turma_id` apontando para a turma deletada
- Aulas registradas via essas gestões
- Notas lançadas para alunos dessa turma
- Agendas e avisos direcionados à turma
- Motivos de falta do Bolsa Família

O soft delete é utilizado exatamente para preservar esses dados históricos. A recuperação da turma (via `PUT /turmas/:id` com `deleted_at: null`) restaura o acesso a todos esses dados.

### Impacto 2: Fechamento de Turma
Ao fechar uma turma (`POST /turmas/:id/fechar`), o sistema:
- Marca o campo `fechada = true` na turma
- Bloqueia novos lançamentos de aulas para essa turma
- Bloqueia novas matrículas
- O status de aprovação/reprovação dos alunos **não é revertido** ao abrir a turma novamente (conforme aviso exibido ao usuário no modal de abertura)

### Impacto 3: Alteração de Circuito de Notas
Se o circuito vinculado à turma for removido ou alterado:
- A função `podeFecharTurma()` passa a retornar `false`
- O botão de fechar turma fica desabilitado
- O dashboard de métricas pode retornar dados inconsistentes

### Impacto 4: Alteração do Campo notifiq
Ao alterar `turma.notifiq` de 1 para 0:
- A coluna RFID na view da turma é ocultada imediatamente
- O chip "NOTIFIQ" na listagem desaparece
- Os endpoints do Notifiq para essa turma deixam de retornar dados relevantes
- Presenças já registradas via RFID são preservadas, mas novas não são processadas

### Impacto 5: Alteração do sistema_bncc_id
Ao alterar `sistema_bncc_id` de uma turma já com notas lançadas:
- Os botões de relatório na view da turma mudam (BNCC ↔ Convencional)
- Notas já lançadas no formato anterior podem ficar inacessíveis pela interface padrão

### Impacto 6: Alteração de turno_id
Ao alterar o turno de uma turma:
- Os horários disponíveis no módulo Aulas mudam
- Aulas já registradas com horários do turno anterior ficam com referência potencialmente inválida

### Impacto 7: Turma sem Gestão de Aula
Uma turma sem gestões de aula vinculadas:
- Não pode ter aulas registradas
- Não pode ter notas lançadas
- Aparece no módulo Pendências como turma pendente
- O dashboard retorna dados vazios

---

*Fim do documento. Versão 1.0 — 2026-05-19.*
