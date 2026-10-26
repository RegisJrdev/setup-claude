#!/usr/bin/env bash
# Hook Stop do Claude Code: se a sessão alterou arquivos que definem padrões nos repos de app
# (../*-api, ../*-web) e não tocou em AGENTS.md/docs/municipios do toolkit, pede ao agente
# que avalie atualizar a documentação. Avisa uma vez por conjunto de mudanças (hash em .git/).

command -v jq >/dev/null || exit 0
input=$(cat)
echo "$input" | grep -q '"stop_hook_active": *true' && exit 0

toolkit="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$toolkit" || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0

api_watched=(app/Http/Middleware app/Http/Kernel.php app/Http/Controllers/Controller.php app/Exceptions app/Providers app/Helpers app/Models/MyModel.php database/seeders/DatabaseSeeder.php database/seeders/RoleSeeder.php config composer.json phpunit.xml tests/Pest.php tests/TestCase.php deploy.sh .github)
web_watched=(src/plugins src/router/index.js src/router/guards src/store/index.js src/Services/index.js src/main.js package.json vue.config.js babel.config.js jest.config.js tests/unit/setup.js src/.eslintrc.js .github)

changed=""
diffs=""
for repo in "$toolkit"/../*-api "$toolkit"/../*-web; do
  [ -d "$repo/.git" ] || continue
  case "$repo" in *-api) watched=("${api_watched[@]}") ;; *) watched=("${web_watched[@]}") ;; esac
  name=$(basename "$repo")
  files=$(cd "$repo" && { git diff --name-only HEAD -- "${watched[@]}"; git ls-files --others --exclude-standard -- "${watched[@]}"; } | sort -u | sed "s|^|$name/|")
  [ -z "$files" ] && continue
  changed+="$files"$'\n'
  diffs+=$(cd "$repo" && git diff HEAD -- "${watched[@]}")
done
[ -z "$changed" ] && exit 0

docs=$( { git diff --name-only HEAD -- AGENTS.md docs municipios 2>/dev/null; git ls-files --others --exclude-standard -- AGENTS.md docs municipios; } )
[ -n "$docs" ] && exit 0

state="$(git rev-parse --git-dir)/claude-docs-check.sha"
hash=$(printf '%s\n%s' "$diffs" "$changed" | sha1sum | cut -d' ' -f1)
[ -f "$state" ] && [ "$(cat "$state")" = "$hash" ] && exit 0
echo "$hash" > "$state"

files=$(echo "$changed" | sed '/^$/d' | head -15 | tr '\n' ' ')
reason="Arquivos que definem padrões foram alterados sem atualização do agent-toolkit (AGENTS.md, docs/, municipios/): $files. Avalie se a mudança cria ou altera um padrão, comando, armadilha ou decisão. Se sim, atualize o toolkit (regra comum em AGENTS.md/docs/, particularidade em municipios/<municipio>/). Se não, apenas encerre."
jq -n --arg r "$reason" '{decision: "block", reason: $r}'
