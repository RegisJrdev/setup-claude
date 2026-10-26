# Domínio Vera Mendes (rascunho)

Gestão escolar da rede municipal: escolas, turmas, matrículas, diário de classe, notas, educação inclusiva, ponto de colaboradores e app para famílias (Notifiq). `TODO:` = a validar com o time.

Prefixo de branch: `veramendes-` (`veramendes-<ticket>-<slug>`, mesmo ticket na API e na Web).

## Glossário

| Termo | Significado | No código |
|---|---|---|
| Franquia | Escola/unidade da rede. Todo dado escolar pertence a uma. | tabela de configuração, coluna `configuracao_id`, `getFranquia()` |
| Ano | Ano letivo. Usuário trabalha em um ano selecionado no perfil. | `ano_id`, `getAno()` |
| Série | Ano/etapa de ensino (ex.: 5º ano). | `Serie` |
| Turma | Grupo de alunos de uma série, turno e ano em uma franquia. | `Turma` |
| Matrícula | Vínculo aluno ↔ turma no ano. Situações: CURSANDO, TRANSFERIDO, CANCELADO... | `Matricula`, `app/Enums/Matricula/SituacaoMatriculaEnum.php` |
| Instrutor / Colaborador | Profissional da escola (professor e outros); renomeado de instrutor para colaborador em 2026. | `Instrutor`, `Colaborador*` |
| Gestão de Aula | Liga professor + turma + disciplina, com horários. Base do Diário Online. | `GestaoDeAula`, `gestoes-de-aulas` |
| Aula | Registro de uma aula de uma gestão, com frequência (faltas). | `Aula`, `Falta` |
| Diário Online | Registro de aulas e frequência pelo professor. | `gestoesDeAulas.*`, `aulas.*` |
| Polivalência | TODO: turma em que um professor leciona várias disciplinas (anos iniciais)? | `../vera-mendes-web/src/Pages/Aulas/NewEditAulaPagePolivalencia.vue` |
| Componente complementar | TODO: componente curricular extra que pode coexistir no mesmo horário (#7485). | |
| Circuito de notas | Estrutura de avaliação: etapas (bimestres) e subetapas. | `CircuitoNota`, `Etapa`, `SubEtapa` |
| BNCC | Base Nacional Comum Curricular; habilidades avaliadas nos planos e avaliações. | `AvaliacaoBNCC`, `CodigoHabilidade*` |
| Educação Inclusiva / AEE | Atendimento Educacional Especializado a alunos PcD. | `AvaliacoesEducacaoInclusiva` |
| CAEE | TODO: Centro de AEE; turmas e gestões de atendimento próprias (Diário de CAEE). | `gestoes-de-atendimentos-caee`, `is_caee` |
| PAEE | Plano de AEE, registrado por bimestre no Diário de CAEE (#7508). | |
| PcD | Aluno com deficiência (`aluno.especial`). | |
| Diário de Atendimentos | Módulo autônomo de atendimentos, cursos, biblioteca e feedback, sem vínculo com turma. | ADR `municipios/vera-mendes/docs/decisions/0001-modulo-diario-atendimentos-autonomo.md` |
| Notifiq | App para famílias/alunos e professores (agenda, boletim, presenças, push). | `routes/notifiq`, `routes/notifiqProfessor` |
| Epublic | TODO: integração/app externo com API v1 própria. | `routes/epublic.php`, `Mobile/V1/Epublic` |
| Hikvision | Reconhecimento facial para presença; webhook público `/hik`. | `municipios/vera-mendes/docs/rota-hik-presencas.md` |
| Ponto de colaboradores | Batidas de ponto, ajustes, faltas justificadas, feriados. | `routes/pontoColaboradores.php` |

## Papéis (roles)

Derivados de `../vera-mendes-api/app/Models/Role.php` e `../vera-mendes-api/public/permissions/`. Acesso é decidido por **permissão**, não por papel: cada papel tem seu JSON de permissões.

admin, super-admin, TI, direção, coordenador, coordenador-semed, secretario, secretario-escolar, supervisor, professor, prof-auxiliar, aluno, formador, gerente-administrativo, coordenador-caee, diretor-caee, psicologo, psicopedagogo, fonoaudiologo, terapeuta-ocupacional, coordenador-orientador, professor-orientador.

TODO: descrever em uma linha o que cada papel faz e quais são de rede (SEMED) x de escola.

## Regras de negócio conhecidas

- Uma mesma pessoa pode ter dois usuários: `professor` (Diário Online) e `professor-orientador` (Diário de Atendimentos). Ver ADR-0001.
- A escola demo "Google" e seus dados são ocultados de todos menos super-admin (`../vera-mendes-api/app/Providers/GoogleRestricaoServiceProvider.php`).
- TODO: regras de fechamento/bloqueio de bimestre e semestre (existem middlewares `BloquearSemestre` e `BloqueioPlanoBimestral`, hoje sem uso em rotas).
- TODO: regras de transferência e remanejamento de matrícula.
- TODO: cálculo de média, recuperação e situação final.
- TODO: quem pode criar quais tipos de usuário (validação no servidor em #7567).
