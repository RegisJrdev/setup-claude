# agent-toolkit

Instruções compartilhadas pelos sistemas municipais de gestão escolar. Cada município tem dois repos, clonados ao lado deste toolkit:

- API: `../<municipio>-api` (Laravel)
- Web: `../<municipio>-web` (Vue 2)

O município atual e o domínio dele vêm do `CLAUDE.local.md`, gerado por `./setup.sh <municipio>`. Se o arquivo não existir ou não indicar o município, pare e peça para rodar o setup.

## Antes de mexer em cada repo
| Tarefa | Faça |
|---|---|
| Implementar ou corrigir na API | Use o subagente `dev-api`. Se fizer você mesmo, leia antes `docs/api.md` |
| Implementar ou corrigir na Web | Use o subagente `dev-web`. Se fizer você mesmo, leia antes `docs/web.md` |
| Feature que cruza os dois repos | `dev-api` primeiro; passe o retorno dele (endpoints, permissões) para o `dev-web` |
| Pergunta, plano ou revisão sobre um repo | Leia `docs/api.md` ou `docs/web.md` antes de responder |

## Como trabalhar a partir do toolkit
- O agente é aberto nesta pasta. Caminhos em `docs/` sem prefixo são relativos ao repo de app: `app/...`, `routes/...` e `database/...` ficam em `../<municipio>-api/`; `src/...` fica em `../<municipio>-web/`.
- Comandos de projeto rodam no repo: `cd ../<repo> && <comando>`. Git: `git -C ../<repo> ...`.
- Não commite nem faça push sem pedido. Aqui no toolkit fica só o que vale para todos os municípios; particularidade vai em `municipios/<municipio>/`.
- Se o arquivo do município contradiz uma regra comum, o do município vence.

## Integração API ↔ Web
- Feature que cruza os dois repos: API primeiro, Web depois. Mesmo ticket na branch dos dois repos.
- Mudou formato de resposta, erro, paginação ou auth: atualize `docs/api-contract.md`. Endpoint que a Web consome e não está documentado: avise.
- Nome de permissão é o mesmo no `can:` da API e no `$can` da Web.
- Toda informação escolar é por franquia + ano, resolvidos pela API a partir do usuário logado: endpoint novo não recebe `configuracao_id` da Web, exceto telas de rede que escolhem a escola.
- Mensagens ao usuário em pt-BR no campo `message`.

## Bibliotecas externas
- Use a versão instalada (como ver: `docs/api.md`, `docs/web.md`), não a faixa do `composer.json`/`package.json` (lockfiles não são versionados).
- Antes de usar API de biblioteca, consulte a doc dessa versão no MCP Context7 (`.mcp.json`). Sem Context7 ou sem a lib: avise que responde de memória.

## Git
- Branch `<prefixo>-<ticket>-<slug>` (prefixo em `municipios/<municipio>/contexto.md`, já carregado). PR para `homologacao` (deploy em homologação), depois `main` (produção).
- Commit: `tipo(escopo) #ticket descrição em pt-BR` (tipo minúsculo: feat|fix|refactor|chore|test|docs), ex.: `fix(usuarios) #7567 Validar no servidor ...`.

## Docs comuns
- Regra de negócio e glossário: `municipios/<municipio>/contexto.md` (já carregado)
- Contrato API ↔ Web: `docs/api-contract.md`
- Ao tomar decisão arquitetural: registre ADR em `municipios/<municipio>/docs/decisions/` (modelo: `municipios/vera-mendes/docs/decisions/0001-modulo-diario-atendimentos-autonomo.md`)

## Manter esta doc viva
Se sua mudança cria ou altera um padrão, comando, armadilha ou decisão, atualize o toolkit **na mesma tarefa**: regra comum aqui; regra da API em `docs/api.md`; da Web em `docs/web.md`; particularidade em `municipios/<municipio>/`. Se a doc contradiz o código, corrija a doc e avise.
