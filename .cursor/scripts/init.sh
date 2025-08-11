#!/usr/bin/env bash
# ------------------------------------------------------------
# Wizard iniziale per progetto (Cursor)
# - Check prerequisiti (node/npm/npx/git, versioni minime)
# - Configura MCP per-progetto (filesystem con path scelto)
# - Crea PRD, tasks e file base (opzionali)
# - Tenta il reload automatico della finestra di Cursor/VS Code
# ------------------------------------------------------------
set -euo pipefail

# ===== stile output (colori) ===============================================
if [[ -t 1 ]]; then
  BOLD="\e[1m"; DIM="\e[2m"; RESET="\e[0m"
  GREEN="\e[32m"; YELLOW="\e[33m"; RED="\e[31m"; BLUE="\e[34m"
else
  BOLD=""; DIM=""; RESET=""; GREEN=""; YELLOW=""; RED=""; BLUE=""
fi

ok()    { echo -e "${GREEN}✅${RESET} $*"; }
warn()  { echo -e "${YELLOW}⚠️ ${RESET} $*"; }
err()   { echo -e "${RED}❌${RESET} $*"; }
info()  { echo -e "${BLUE}ℹ️ ${RESET} $*"; }
step()  { echo -e "\n${BOLD}==> $*${RESET}"; }

# ===== utility ==============================================================
vernum() {  # converte "v18.17.0" -> "18.17.0" e in numero confrontabile "18 17 0"
  local v="${1#v}"; IFS='.' read -r a b c <<<"$v"; echo "$a ${b:-0} ${c:-0}"
}
ver_ge() {  # >=
  local A B C D E F; read -r A B C <<<"$(vernum "$1")"; read -r D E F <<<"$(vernum "$2")"
  (( A>D || (A==D && (B>E || (B==E && C>=F))) ))
}

# ===== prerequisiti =========================================================
step "check prerequisiti"

need_cmds=(node npm npx git)
missing=()
for c in "${need_cmds[@]}"; do command -v "$c" >/dev/null 2>&1 || missing+=("$c"); done
if ((${#missing[@]})); then
  err "Comandi mancanti: ${missing[*]}"
  echo "Installa/aggiorna prima di continuare."
  exit 1
fi
ok "Comandi base presenti: node, npm, npx, git"

NODE_VER="$(node -v)"
if ! ver_ge "$NODE_VER" "18.0.0"; then
  err "Node $NODE_VER troppo vecchio. Richiesto >= 18.0.0"
  exit 1
fi
ok "Node $NODE_VER"

# Trova CLI per reload (Cursor o VS Code)
CLI=""
if command -v cursor >/dev/null 2>&1; then
  CLI="cursor"
elif command -v code >/dev/null 2>&1; then
  CLI="code"
fi
if [[ -n "${CLI}" ]]; then
  ok "CLI editor rilevata: ${CLI}"
else
  warn "CLI editor non rilevata (né 'cursor' né 'code'). Il reload sarà manuale."
  info "Suggerimento: in Cursor → Command Palette digita 'Shell Command: Install 'cursor' command in PATH'."
fi

# ===== wizard ===============================================================
step "wizard iniziale progetto"

ask_yn () { read -r -p "$1 [s/N]: " a; [[ "$a" =~ ^([sSyY]|yes)$ ]]; }

echo "Seleziona MCP per questo progetto:"
echo "  1) filesystem (consigliato)   0) nessuno"
read -r -p "Scelta [1/0] (default 1): " CHOICE
CHOICE=${CHOICE:-1}

if [[ "$CHOICE" == "1" ]]; then
  read -r -p "Percorso root da esporre (default: .): " ROOT
  ROOT=${ROOT:-.}
  mkdir -p .cursor
  cat > .cursor/mcp.json <<JSON
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["@modelcontextprotocol/server-filesystem", "${ROOT}"],
      "disabled": false
    }
  }
}
JSON
  ok "Creato .cursor/mcp.json (filesystem → ${ROOT})"
else
  warn "Nessun MCP per-progetto creato (userai solo i globali)."
fi

if ask_yn "Vuoi creare il PRD (docs/PRD.md)?"; then
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
fi

if ask_yn "Vuoi creare i task (.cursor/tasks.json)?"; then
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
fi

if ask_yn "Vuoi creare file base (.editorconfig, .gitignore, README)?"; then
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
fi

# ===== reload automatico =====================================================
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
