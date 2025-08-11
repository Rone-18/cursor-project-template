#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Wizard iniziale per progetto (Cursor) - versione chiara e guidata
#
# Cosa fa:
# - Verifica prerequisiti (node, npm, npx, git) e versioni minime
# - (Opzionale) Verifica accesso GitHub al remote origin se presente
# - Configura MCP per-progetto (filesystem) con percorso scelto
# - Crea PRD, tasks e file base (.editorconfig, .gitignore, README) su richiesta
# - Prova il reload automatico della finestra di Cursor/VS Code
#
# Modalità:
# - Interattiva (default) con prompt espliciti e default chiari
# - Non-interattiva con flag --yes (accetta tutti i default consigliati)
#
# Esempi:
#   bash .cursor/scripts/init.sh
#   bash .cursor/scripts/init.sh --yes
#   bash .cursor/scripts/init.sh --mcp filesystem --root . --no-prd
# -----------------------------------------------------------------------------
set -euo pipefail

# ===== stile output ==========================================================
if [[ -t 1 ]]; then
  BOLD="\e[1m"; DIM="\e[2m"; RESET="\e[0m"
  GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; BLUE="\e[34m"
else
  BOLD=""; DIM=""; RESET=""; GREEN=""; YELLOW=""; RED=""; BLUE=""
fi

ok()   { echo -e "${GREEN}✅${RESET} $*"; }
warn() { echo -e "${YELLOW}⚠️ ${RESET} $*"; }
err()  { echo -e "${RED}❌${RESET} $*"; }
info() { echo -e "${BLUE}ℹ️ ${RESET} $*"; }
step() { echo -e "\n${BOLD}==> $*${RESET}"; }

# ===== helper ================================================================
vernum() { local v="${1#v}"; IFS='.' read -r a b c <<<"$v"; echo "$a ${b:-0} ${c:-0}"; }
ver_ge() { local A B C D E F; read -r A B C <<<"$(vernum "$1")"; read -r D E F <<<"$(vernum "$2")"; (( A>D || (A==D && (B>E || (B==E && C>=F))) )); }

ask_yes_no_default_yes() { # Invio => Sì
  local q="$1" a; read -r -p "$q [S/n]: " a
  [[ -z "$a" || "${a,,}" =~ ^(s|si|y|yes)$ ]]
}

ask_yes_no_default_no() { # Invio => No
  local q="$1" a; read -r -p "$q [s/N]: " a
  [[ "${a,,}" =~ ^(s|si|y|yes)$ ]]
}

ask_with_default() {      # Invio => default
  local prompt="$1" def="$2" out
  read -r -p "$prompt (default: ${def}) → " out
  echo "${out:-$def}"
}

# ===== argomenti =============================================================
AUTO_YES=false
MCP_CHOICE=""      # "", "filesystem", "none"
FS_ROOT=""         # percorso per filesystem
CREATE_PRD=true
CREATE_TASKS=true
CREATE_BASE=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes) AUTO_YES=true; shift ;;
    --mcp) MCP_CHOICE="${2:-}"; shift 2 ;;
    --root) FS_ROOT="${2:-}"; shift 2 ;;
    --no-prd) CREATE_PRD=false; shift ;;
    --no-tasks) CREATE_TASKS=false; shift ;;
    --no-base) CREATE_BASE=false; shift ;;
    -h|--help)
      cat <<'HLP'
Uso:
  bash .cursor/scripts/init.sh [opzioni]

Opzioni:
  -y, --yes           Accetta tutti i default consigliati (non-interattivo)
  --mcp <val>         Forza MCP: "filesystem" oppure "none"
  --root <path>       Root esposta per MCP filesystem (default: .)
  --no-prd            Non creare docs/PRD.md
  --no-tasks          Non creare .cursor/tasks.json
  --no-base           Non creare .editorconfig, .gitignore, README
  -h, --help          Mostra aiuto
HLP
      exit 0 ;;
    *) warn "Opzione sconosciuta: $1"; shift ;;
  esac
done

# ===== prerequisiti ==========================================================
step "check prerequisiti"
for c in node npm npx git; do
  command -v "$c" >/dev/null 2>&1 || { err "Comando mancante: $c"; exit 1; }
done
ok "Comandi base presenti: node, npm, npx, git"

NODE_VER="$(node -v)"
ver_ge "$NODE_VER" "18.0.0" || { err "Node $NODE_VER troppo vecchio. Richiesto >= 18.0.0"; exit 1; }
ok "Node $NODE_VER"

# ===== (opzionale) verifica accesso GitHub remote ============================
step "verifica autenticazione GitHub (opzionale)"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if origin_url="$(git remote get-url origin 2>/dev/null)"; then
    if GIT_TERMINAL_PROMPT=0 git ls-remote -h "$origin_url" HEAD >/dev/null 2>&1; then
      ok "Accesso a GitHub OK per ${origin_url}"
    else
      warn "Accesso a GitHub non verificato (repo privato o token mancante/scaduto). Continuiamo comunque."
      info "Suggerimento: usa un PAT Classic con scope 'repo' o 'gh auth login'."
    fi
  else
    info "Nessun 'origin' configurato. Salta verifica."
  fi
else
  info "Questa cartella non è (ancora) un repository git. Salta verifica."
fi

# ===== rileva CLI editor per reload =========================================
CLI=""
command -v cursor >/dev/null 2>&1 && CLI="cursor"
[[ -z "$CLI" && "$(uname -s)" == "Darwin" ]] && command -v code >/dev/null 2>&1 && CLI="code"
[[ -n "$CLI" ]] && ok "CLI editor rilevata: ${CLI}" || warn "CLI editor non rilevata. Il reload sarà manuale."

# ===== wizard ================================================================
step "wizard iniziale progetto"

# 1) Scelta MCP per-progetto
if [[ -z "$MCP_CHOICE" ]]; then
  if "$AUTO_YES"; then
    MCP_CHOICE="filesystem"
    info "Modalità --yes: MCP impostato a 'filesystem' (consigliato)."
  else
    echo "Seleziona MCP per questo progetto:"
    echo "  1) filesystem (consigliato)   0) nessuno"
    read -r -p "Scelta (Invio = 1): " CHOICE
    CHOICE="${CHOICE:-1}"
    MCP_CHOICE=$([[ "$CHOICE" == "1" ]] && echo "filesystem" || echo "none")
  fi
fi
echo -e "${DIM}Scelta MCP:${RESET} ${MCP_CHOICE}"

# Config MCP filesystem
if [[ "$MCP_CHOICE" == "filesystem" ]]; then
  if [[ -z "$FS_ROOT" ]]; then
    if "$AUTO_YES"; then
      FS_ROOT="."
      info "Modalità --yes: root filesystem impostata a '.' (cartella corrente)."
    else
      FS_ROOT="$(ask_with_default 'Percorso root da esporre al tool filesystem (premi INVIO per usare la cartella corrente)' '.')"
    fi
  fi
  mkdir -p .cursor
  cat > .cursor/mcp.json <<JSON
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-filesystem", "${FS_ROOT}"],
      "disabled": false
    }
  }
}
JSON
  ok "Creato .cursor/mcp.json (filesystem → ${FS_ROOT})"
else
  warn "Nessun MCP per-progetto creato (userai solo gli MCP globali configurati in Cursor)."
fi

# 2) PRD
if "$CREATE_PRD"; then
  if "$AUTO_YES" || ask_yes_no_default_yes "Vuoi creare il PRD (docs/PRD.md)? Se premi INVIO verrà creato ora"; then
    mkdir -p docs
    if [[ ! -f docs/PRD.md ]]; then
      cat > docs/PRD.md <<'MD'
# product requirements document (prd)

## 1. contesto e obiettivo
- **Contesto**: TODO
- **Obiettivo v1**: Lighthouse mobile ≥ 90, CLS < 0.1, TTI < 3.5s.

## 2. stakeholder
PO: TODO | UX: TODO | Dev: TODO | SEO: TODO | QA: TODO

## 3. scope
### goal
- TODO
### non-goal
- TODO

## 4. user stories
- Persona A — come…, voglio…, così da…

## 5. requisiti
**Funzionali**: nav ≤ 5 voci, form contatto, FAQ.  
**Non-funzionali**: performance, accessibilità (WCAG AA), SEO.

## 6. metriche
GA4: `cta_click`, `form_submit`, `scroll_75`.

## 7. UAT
Lighthouse mobile ≥ 90; nessun errore console/404.
MD
      ok "Creato docs/PRD.md"
    else
      info "PRD esistente: skip"
    fi
  else
    info "PRD: non creato"
  fi
else
  info "PRD: disattivato via flag"
fi

# 3) tasks
if "$CREATE_TASKS"; then
  if "$AUTO_YES" || ask_yes_no_default_yes "Vuoi creare i task (.cursor/tasks.json)? Se premi INVIO verranno creati ora"; then
    mkdir -p .cursor
    if [[ ! -f .cursor/tasks.json ]]; then
      cat > .cursor/tasks.json <<'JSON'
{
  "version": 1,
  "project": "Progetto",
  "tasks": [
    {
      "id": "SETUP-ENV",
      "title": "Preparare ambiente",
      "description": "Init repo, .editorconfig, .gitignore; definire regole PR.",
      "status": "todo",
      "priority": "high",
      "acceptance": ["Repo pronto", "Regole PR definite"]
    },
    {
      "id": "DS-TYPO",
      "title": "Design system tipografico",
      "description": "Definire CSS variables e mappare in tema/Elementor.",
      "status": "todo",
      "priority": "high",
      "dependencies": ["SETUP-ENV"],
      "acceptance": ["Variables --fs-* e --space-*", "Gerarchie H1–H6 coerenti"]
    }
  ]
}
JSON
      ok "Creato .cursor/tasks.json"
    else
      info "Tasks esistenti: skip"
    fi
  else
    info "Tasks: non creati"
  fi
else
  info "Tasks: disattivati via flag"
fi

# 4) file base
if "$CREATE_BASE"; then
  if "$AUTO_YES" || ask_yes_no_default_yes "Vuoi creare i file base (.editorconfig, .gitignore, README)? Se premi INVIO verranno creati ora"; then
    if [[ ! -f .editorconfig ]]; then
      cat > .editorconfig <<'EC'
root = true
[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true
EC
      ok "Creato .editorconfig"
    else
      info ".editorconfig esistente: skip"
    fi

    if [[ ! -f .gitignore ]]; then
      cat > .gitignore <<'GI'
node_modules/
dist/
.env
.DS_Store
GI
      ok "Creato .gitignore"
    else
      info ".gitignore esistente: skip"
    fi

    if [[ ! -f README.md ]]; then
      cat > README.md <<'MD'
# progetto (inizializzato dal wizard)
- MCP globali (in Cursor): sequential-thinking, refactor-mcp
- MCP per-progetto: filesystem in `.cursor/mcp.json` (se attivato)
- Documentazione: `docs/PRD.md`
- Pianificazione: `.cursor/tasks.json`
MD
      ok "Creato README.md"
    else
      info "README esistente: skip"
    fi
  else
    info "File base: non creati"
  fi
else
  info "File base: disattivati via flag"
fi

# ===== riepilogo =============================================================
step "riepilogo"
echo -e "${DIM}- MCP per-progetto:${RESET} $([[ -f .cursor/mcp.json ]] && echo 'filesystem' || echo 'nessuno')"
echo -e "${DIM}- Root esposta:${RESET} $([[ -f .cursor/mcp.json ]] && jq -r '.mcpServers.filesystem.args[1]' .cursor/mcp.json 2>/dev/null || echo '-')"
echo -e "${DIM}- PRD:${RESET} $([[ -f docs/PRD.md ]] && echo 'creato' || echo 'non creato')"
echo -e "${DIM}- Tasks:${RESET} $([[ -f .cursor/tasks.json ]] && echo 'creati' || echo 'non creati')"
echo -e "${DIM}- File base:${RESET} $([[ -f .editorconfig || -f .gitignore || -f README.md ]] && echo 'creati/aggiornati' || echo 'non creati')"

# ===== reload ================================================================
step "reload della finestra di Cursor"
RELOAD_CMD="workbench.action.reloadWindow"
if [[ -n "${CLI}" ]]; then
  set +e
  "${CLI}" --command "${RELOAD_CMD}" >/dev/null 2>&1
  rc=$?
  set -e
  if [[ $rc -eq 0 ]]; then
    ok "Reload inviato a ${CLI}"
  else
    warn "Impossibile avviare reload via ${CLI}. Fallback manuale:"
    echo -e "  - Premi ${BOLD}Cmd+Shift+P${RESET} → digita ${BOLD}Reload Window${RESET} → Invio."
  fi
else
  warn "Reload automatico non disponibile."
  echo -e "  - Premi ${BOLD}Cmd+Shift+P${RESET} → ${BOLD}Reload Window${RESET}."
fi

echo
ok "Setup completato. In chat digita ${BOLD}/mcp${RESET} per verificare i tool attivi."
