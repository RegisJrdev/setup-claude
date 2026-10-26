---
name: criar-permissao
description: Cria permissão nova na API e libera na Web (PermissionSeeder, JSON de cada role, rota com can:, $can na Web). Use ao adicionar rota, tela ou ação que precisa de permissão própria.
---

# Criar permissão

Nome: `<recurso>.<acaoCamelCase>`, ex.: `colaboradores.pontos.ajustar`. Detalhes em `docs/backend-laravel.md`.

1. API `database/seeders/PermissionSeeder.php`: adicione a permissão (idempotente, `updateOrInsert`/`firstOrCreate`).
2. API `public/permissions/permissions<ROLE>.json`: adicione em **cada** role que deve tê-la. Pergunte quais roles se não estiver claro. O `RoleSeeder` recria os vínculos a partir desses JSON a cada deploy: permissão fora do JSON some.
3. API rota: `->middleware('can:<recurso>.<acao>,<recurso>.*')`.
4. Web: guard `can()` na rota e `$can(["<recurso>.<acao>", "<recurso>.*"])` em menu/botão, com o mesmo nome.
5. Teste Pest: `Sanctum::actingAs($user, ['<recurso>.<acao>'])` passa; sem a permissão, 403.

Não conceda permissão por migration com `role_id` fixo. Avise o usuário: a permissão só aparece após relogar.
