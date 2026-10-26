# ADR-0001: Criar o "Diário de Atendimentos" como módulo autônomo com perfis orientadores dedicados

- **Status:** Aceito
- **Data:** 2026-07-22
- **Autor(es):** Mateus Sousa
- **Decisores:** mateus@cajutec.com.br

## Contexto

O protocolo **#7035** pede um módulo para registrar e acompanhar atendimentos, cursos
(AVAMEC/EV.GOV), desenvolvimento de biblioteca, recomposição e feedback de
coordenação realizados no município. O sistema não possui hoje uma estrutura para isso.

Havia dois candidatos a reuso, ambos com semântica incompatível:

- **Diário Online** (`gestoes-de-aulas` → `aulas` → `faltas`): todo o fluxo é preso a
  turma + disciplina + professor(instrutor). Os atendimentos do #7035 **não** pertencem a
  uma turma: têm público-alvo variável (alunos/pais/funcionários), "professor orientador"
  como texto livre, e participantes buscados globalmente na franquia.
- **Diário de CAEE / Educação Inclusiva** (`gestoes-de-atendimentos-caee`, turmas com
  `tipo_de_atendimento`): apesar do nome parecido ("Diário de Atendimento"), é preso a
  turmas de educação especial e a gestões de aula CAEE.

Além disso, o protocolo cria dois novos tipos de usuário — **Coordenador Orientador** e
**Professor Orientador** — que devem ver **apenas** o Diário de Atendimentos, nunca o
Diário Online. Restrição de negócio confirmada com o cliente: **uma mesma pessoa física de
professor pode ter 2 usuários** — um com role `professor` (ligado ao `instrutor`, vê o Diário
Online) e outro com role `professor-orientador` (usuário independente, vê só o novo módulo).

## Decisão

Criar o **Diário de Atendimentos como módulo autônomo**, sem estender CAEE nem Aulas:

- **Tabelas próprias** (`tipos_de_atendimento`, `atendimentos`, `atendimento_participantes`,
  `desenvolvimento_biblioteca`, `feedback_coordenacao`), todas escopadas por
  **franquia (`configuracao_id`) + ano (`ano_id`)**, seguindo o multi-tenancy padrão.
- **Alunos por busca global na franquia** (matrículas ativas do ano corrente), referenciados
  por `matricula_id` — sem amarrar registros a turma. PCD via `matricula.aluno.especial`.
- **Controllers/Services/rotas próprios** com prefixos dedicados, reusando apenas os
  *padrões* existentes (frequência estilo `Aula`/`Falta`,
  desenvolvimento estilo BNCC semestral, PDF via `BasePdf` + `footer_nome_data_hora`).
- **Dois novos roles** (`coordenador-orientador`, `professor-orientador`) criados no
  `RoleSeeder`, com permissões próprias em `public/permissions/*.json` = base do role
  convencional **menos** as permissões do Diário Online (`gestoesDeAulas.*`, `aulas.*`)
  **mais** as permissões do novo módulo. Os orientadores são usuários **standalone**,
  criados em "Usuários >> Outros" — não ligados a `instrutor`.
- **Controle de acesso por permissão** (não por FK nem por checagem de role): o menu usa
  `$can(child.permissions)` e as rotas usam o middleware `can:<perm>.*`. Como cada role só
  possui as permissões do seu diário, o usuário só enxerga o diário correspondente.

## Alternativas consideradas

- **Estender o módulo CAEE** — reusaria telas/relatórios, mas o CAEE é preso a turmas de
  educação especial e a `gestoesDeAtendimentosCAEE`; forçaria os atendimentos gerais dentro
  de um modelo turma-específico. *Rejeitada por incompatibilidade de domínio.*
- **Reusar Aulas/Gestão de Aula** — o Diário Online exige turma+disciplina+instrutor, que os
  atendimentos não têm. *Rejeitada.*
- **Um único usuário com múltiplos roles (professor + orientador)** — o sistema liga o
  `instrutor` a **um** `user_id`, e o gating de diário é por permissões do role; acumular os
  dois roles no mesmo usuário mostraria os dois diários simultaneamente, violando o
  Cenário 14. *Rejeitada — modelo de 2 usuários por pessoa física.*
- **Não fazer nada / adaptar relatórios avulsos** — não atende ao CRUD, frequência,
  planos, impressão e RBAC exigidos pelo protocolo. *Insuficiente.*

## Consequências

- ✅ Módulo coeso e isolado; separação clara entre Diário Online e Diário de Atendimentos.
- ✅ Acesso governado por RBAC já existente (permissões + middleware `Can`), sem código de
  gating ad-hoc.
- ✅ Cada fase (atendimentos, biblioteca, feedback, relatório) evolui sem tocar nos
  módulos existentes.
- ⚠️ Duplicação de *padrões* (frequência, planos, desenvolvimento tipo BNCC, PDF) — código
  novo espelha os existentes em vez de compartilhar.
- ⚠️ Uma pessoa física de professor passa a ter 2 usuários; a gestão de credenciais/vínculos
  precisa considerar isso.
- 🔁 Os IDs de role são referenciados de forma fixa em alguns pontos do front
  (`plugins/constants.js`); novos roles dependem de seeding (`PermissionSeeder` +
  `RoleSeeder`) para funcionar. A lista de "Outros" usuários é hierárquica
  (`role_pivot_permission`): admin/super-admin/TI e o coordenador-orientador foram
  configurados como responsáveis por criar os novos perfis.

## Referências

- Protocolo: `protocolos/7035/7035-implantar-módulo-de-diário-de-atendimentos.md` e
  `protocolos/7035/Diário de Atendimentos.pdf`.
- Plano de implementação (fases 1–6) aprovado para o #7035.
- Padrões espelhados: `AulasController`/`Falta` (frequência),
  `SistemaBNCCSemestralController`/`AvaliacaoSemestralBNCC` (desenvolvimento),
  `Services/Pdf/BasePdf` + `resources/views/relatorios/footer_nome_data_hora.blade.php` (PDF).
