# API: regras do produto

Leia antes de qualquer mudança em `../<municipio>-api`. Depois, leia `municipios/<municipio>/api.md` (particularidades do município).

API Laravel 12 (PHP 8.3, Sanctum), estrutura ainda no estilo Laravel 10.

## Comandos
- Testes: `vendor/bin/pest` (ou `php artisan test`). Filtrar: `vendor/bin/pest --filter=Feriado`.
- Formatar: `vendor/bin/pint --dirty` (só nos arquivos alterados).
- CI não roda testes: rode antes de abrir PR.

## Regras inegociáveis (código novo)
- Controller por recurso, fino: cada método valida com FormRequest, chama **uma Action** e devolve `response()->json($dados, $status)`. Modelo: `docs/arquitetura.md`.
- Action = uma operação de negócio (`app/Actions/<Dominio>/<Verbo><Entidade>Action.php`). Service só para fluxo que orquestra várias Actions/integrações.
- Sem API Resource. Sucesso: model/array cru, 201 ao criar, 204 (`null`) ao excluir. `{success, message}` só no Mobile V1.
- Toda query de dado escolar filtra `configuracao_id` (franquia) e, quando aplicável, `ano_id`. Não existe global scope de tenant.
- Toda rota nova tem `can:<recurso>.<acao>,<recurso>.*`. Não use Policies (não existem no projeto).
- Testes novos em Pest. Enum novo é enum nativo do PHP.
- Não refatore controllers legados (ex.: `RelatoriosController`, `MatriculasController`): só a mudança pedida.

## Armadilhas
- **Permissão nova vai em 3 lugares**: `database/seeders/PermissionSeeder.php`, `public/permissions/permissions<ROLE>.json` de cada role e a rota. O deploy roda `migrate --force --seed` e o `RoleSeeder` apaga e recria os vínculos role↔permissão a partir dos JSON: o que não estiver no JSON some. Skill: `criar-permissao`.
- Permissões são copiadas para o token no login: o usuário só vê permissão nova após relogar.
- `getFranquia()`/`getAno()` (`app/Helpers/customHelpers.php`) leem o usuário logado: retornam `null` em job, command e rota pública. Nesses casos passe os ids por parâmetro.
- Com `APP_DEBUG=false`, `app/Exceptions/Handler.php` converte `ValidationException` em 500. Não envolva FormRequest/validação em `try/catch(\Exception)`.
- Migrations em subpastas de `database/migrations` não são carregadas. Crie sempre na raiz.
- Testes rodam em sqlite em memória: SQL específico de MySQL em migration precisa de guarda `DB::getDriverName() === 'sqlite'`.
- `preventLazyLoading` ativo fora de produção: use `with()` para relações.
- `routes/api.php` não tem `auth:sanctum` no grupo. Rota nova vai no arquivo do domínio, registrado no `RouteServiceProvider`.
- Laravel 12 com estrutura do 10, mantida de propósito: middleware/alias em `app/Http/Kernel.php`, erros em `app/Exceptions/Handler.php`, rotas no `RouteServiceProvider`. Não use `withMiddleware`/`withExceptions`/`bootstrap/providers.php`.

## Docs sob demanda
- Ao criar controller, Action, Service ou FormRequest: `docs/arquitetura.md`
- Ao criar rota, permissão, migration, seeder, model ou enum: `docs/backend-laravel.md`
- Ao escrever ou rodar testes: `docs/testes.md` (seção API)
- Ao mexer em formato de resposta, erro, paginação ou autenticação: `docs/api-contract.md`
- Versão instalada de pacote: `cd ../<municipio>-api && composer show <pacote>`
