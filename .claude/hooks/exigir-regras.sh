#!/usr/bin/env bash
# Hook PreToolUse do Claude Code: bloqueia Edit/Write em ../<municipio>-api ou ../<municipio>-web
# enquanto o agente (principal ou subagente) não leu docs/api.md ou docs/web.md nesta sessão.
# A leitura é marcada por agente: o que o dev-api leu não libera o agente principal, e vice-versa.
# Não cobre edição via Bash (sed, redirecionamento).

command -v jq >/dev/null || exit 0
input=$(cat)
tool=$(jq -r '.tool_name' <<<"$input")
file=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")
[ -z "$file" ] && exit 0
file=$(realpath -m -- "$file")
session=$(jq -r '.session_id' <<<"$input")
agent=$(jq -r '.agent_id // "main"' <<<"$input")

toolkit="$(cd "$(dirname "$0")/../.." && pwd)"
parent="$(dirname "$toolkit")"
state="${TMPDIR:-/tmp}/agent-toolkit-regras/$session"

if [ "$tool" = "Read" ]; then
  case "$file" in
    "$toolkit/docs/api.md") lado=api ;;
    "$toolkit/docs/web.md") lado=web ;;
    *) exit 0 ;;
  esac
  mkdir -p "$state" && touch "$state/$agent-$lado"
  exit 0
fi

rel="${file#"$parent"/}"
[ "$rel" = "$file" ] && exit 0
case "${rel%%/*}" in
  *-api) lado=api; sub=dev-api ;;
  *-web) lado=web; sub=dev-web ;;
  *) exit 0 ;;
esac
[ -f "$state/$agent-$lado" ] && exit 0

reason="Antes de editar o repo da $lado, leia docs/$lado.md (regras do produto) e municipios/<municipio>/$lado.md, ou delegue a tarefa ao subagente $sub."
jq -n --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
