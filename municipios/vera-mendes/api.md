# Vera Mendes: API (`../vera-mendes-api`)

- Consumida por `../vera-mendes-web` e pelos apps Notifiq.
- Rodar local: TODO: confirmar (MySQL local + `php artisan serve`?)
- Migrations em subpastas que existem e não são carregadas: `database/migrations/circuito`, `database/migrations/diario-formacao`.
- Exemplo de permissão nova nos 3 lugares: commit `b47f096`.
- Exemplo de guarda sqlite em migration: `database/migrations/2026_06_08_000001_update_feriados_tipo_enum.php`.

## Estado da suíte de testes

TODO: a suíte completa falha em sqlite (107 de 109 testes em 2026-10-23). A migration `database/migrations/2025_07_08_152621_create_vw_relatorio_escolas_turmas_alunos_view.php` cria uma view que referencia a tabela `notas`, que não é criada pelas migrations carregadas; a próxima alteração em `series` quebra o `migrate`. Confirmar com o time como os testes eram rodados e corrigir a migration (guarda para sqlite).

## Docs sob demanda
- Ao alterar Turmas: `municipios/vera-mendes/docs/mapa-dependencias/modulo-turmas.md`
- Presenças no Notifiq: `municipios/vera-mendes/docs/notifiq-presencas.md`
- Webhook Hikvision (`/hik`): `municipios/vera-mendes/docs/rota-hik-presencas.md`
- ADRs: `municipios/vera-mendes/docs/decisions/`
