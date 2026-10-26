#!/usr/bin/env bash
# Uso: ./setup.sh <municipio>   (ex.: ./setup.sh vera-mendes)
# Gera, para este clone, CLAUDE.local.md (carrega o domínio do município; api.md/web.md
# do município são lidos sob demanda junto com docs/api.md e docs/web.md) e
# .claude/settings.local.json (libera acesso a ../<municipio>-api e ../<municipio>-web).
# Os dois arquivos são gitignored.
set -euo pipefail

m="${1:?Uso: ./setup.sh <municipio>}"
cd "$(dirname "$0")"

# Atualiza o toolkit e reexecuta, porque o próprio setup.sh pode ter mudado no pull.
# Sem remoto ou com mudança local que impeça fast-forward: avisa e segue com a versão local.
if [ -z "${TOOLKIT_ATUALIZADO:-}" ]; then
  git pull --ff-only || echo "aviso: git pull falhou; seguindo com a versão local" >&2
  TOOLKIT_ATUALIZADO=1 exec ./setup.sh "$@"
fi

[ -d "municipios/$m" ] || { echo "municipios/$m não existe" >&2; exit 1; }

parent="$(cd .. && pwd)"
for r in "$m-api" "$m-web"; do
  [ -d "$parent/$r" ] || echo "aviso: $parent/$r não encontrado" >&2
done

cat > CLAUDE.local.md <<EOF
# Município atual: $m

@municipios/$m/contexto.md
EOF

dirs=$(printf '["%s", "%s"]' "$parent/$m-api" "$parent/$m-web")
if [ -f .claude/settings.local.json ] && command -v jq >/dev/null; then
  jq --argjson d "$dirs" '.permissions.additionalDirectories = $d' .claude/settings.local.json > .claude/settings.local.json.tmp
  mv .claude/settings.local.json.tmp .claude/settings.local.json
else
  printf '{\n  "permissions": {\n    "additionalDirectories": %s\n  }\n}\n' "$dirs" > .claude/settings.local.json
fi

echo "ok: município $m configurado"
