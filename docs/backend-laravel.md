# Backend Laravel: rotas, permissões e banco

Vale para funcionalidades novas. Código legado não é refatorado: altere só o necessário e mantenha o estilo do arquivo.

## Rotas e permissões

- Rota nova vai no arquivo do domínio em `routes/`; arquivo novo precisa de bloco `Route::prefix` em `app/Providers/RouteServiceProvider.php` (com `api` + `auth:sanctum`). Prefixo em kebab-case.
- Toda rota: `->middleware('can:<recurso>.<acao>,<recurso>.*')`. O middleware é `app/Http/Middleware/Can.php` e checa `tokenCan()`.
- Nome de permissão: `<recurso>.<acaoCamelCase>`, ex.: `colaboradores.pontos.ajustar`.
- Rota com `{id}` numérico: use `->whereNumber('id')` para não engolir rotas fixas declaradas depois (ver `routes/turmas.php`, onde `/{retirarFiltroFranquia?}` sombreia rotas abaixo).
- **Permissão nova**:
  1. adicionar em `database/seeders/PermissionSeeder.php`;
  2. adicionar no `public/permissions/permissions<ROLE>.json` de cada role que deve tê-la;
  3. usar na rota.
  Não conceda permissão por migration com `role_id` fixo: o `RoleSeeder` recria tudo a partir dos JSON a cada deploy.

## Models e enums

- Model novo com auditoria e soft delete: estenda `app/Models/MyModel.php`.
- Use `$fillable` e `$casts`.
- Enum novo: enum nativo `enum X: string` em `app/Enums/<Dominio>/` (ex.: `app/Enums/Matricula/SituacaoMatriculaEnum.php`). Enums Spatie (`app/Enums/Caixa/`) são legado.

## Migrations e seeders

- Sempre em `database/migrations/` (raiz), formato `return new class extends Migration`.
- SQL específico de MySQL (ENUM, views, `ALTER ... MODIFY`) com guarda para sqlite: ex. `database/migrations/2026_06_08_000001_update_feriados_tipo_enum.php`.
- O deploy (`deploy.sh`) roda `migrate --force --seed`: todo seeder chamado pelo `DatabaseSeeder` precisa ser idempotente (`updateOrInsert`/`firstOrCreate`).
