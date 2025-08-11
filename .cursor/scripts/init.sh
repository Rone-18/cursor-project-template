#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Wizard iniziale per progetto (Cursor) con prompt chiari e default espliciti
# - Mostra sempre il valore di default e cosa succede se premi INVIO
# - Conferma ogni scelta con riepilogo
# - Crea MCP per-progetto (filesystem), PRD, tasks e file base
# - Tenta il reload automatico di Cursor/VS Code
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

# ===== helpers ===============================================================
vernum() { local v="${1#v}"; IFS='.' read -r a b c <<<"$v"; echo "$a ${b:-0} ${c:-0}"; }
ver_ge() { local A B C D E F; read -r A B C <<<"$(vernum "$1")"; read -r D E F <<<"$(vernum "$2")"; (( A>D || (A==D && (B>E || (B==E && C>=F))) )); }

ask_yes_no_default_no() {
  # Prompt sì/no con default = NO. Invio => NO.
  local q="$1"; local ans
  read -r -p "$q [s/N]: " ans
  [[ "${ans,,}" =~ ^(s|si|y|yes)$ ]] && return 0 || return 1
}

ask_yes_no_default_yes() {
  # Prompt sì/no con default = SÌ. Invio => SÌ.
  local q="$1"; local ans
  read -r -p "$q [S/n]: " ans
  [[ -z "$ans" || "${ans,,}" =~ ^(s|si|y|yes)$ ]] && return 0 || return 1
}

ask_with_default() {
  # Prompt con default esplicito. Invio => default.
  local prompt="$1"; local def="$2"; local out
  read -r -p "$prompt (default: ${def}) → " out
  echo "${out:-$def}"
}

confirm_choice() {
  # Stampa conferma scelta in modo chiaro
  echo -e "${DIM}Scelta:${RESET} $*"
}

# ===== prerequisiti ==========================================================
step "check prerequisiti"
for c in node npm npx git; do
  command -v "$c" >/dev/null 2>&1 || { err "Comando mancante: $c"; exit 1; }
done
ok "Comandi base presenti: node, npm, npx, git"

NODE_VER="$(node -v)"
ver_ge "$NODE_VER" "18.0.0" || { err "Node $NODE_VER troppo vecchio. Richiesto >= 18.0.0"; exit 1; }
ok "Node $NODE_VER"

# ===== (opzionale) verifica accesso GitHub remoto ===========================
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git remote get-url origin >/dev/null 2>&1; then
  if git ls-remote --heads "$(git remote get-url origin)" >/dev/null 2>&1; then
    ok "Accesso a GitHub OK per $(git remote get-url origin)"
  else
    warn "Impossibile verificare l’accesso a GitHub (repo privato o token mancante?). Continua comunque."
  fi
fi

# trova CLI editor per reload
CLI=""
command -v cursor >/dev/null 2>&1 && CLI="cursor"
command -v code   >/dev/null 2>&1 && CLI="${CLI:-code}"
[[ -n "$CLI" ]] && ok "CLI editor rilevata: ${CLI}" || warn "CLI editor non rilevata. Il reload sarà manuale."

# ===== wizard ================================================================
step "wizard iniziale progetto"

# 1) MCP per-progetto
echo "Seleziona MCP per questo progetto:"
echo "  1) filesystem (consigliato)   0) nessuno"
CHOICE="$(ask_with_default 'Scelta' '1')"
confirm_choice "MCP selezionato: ${CHOICE}"

if [[ "$CHOICE" == "1" ]]; then
  ROOT="$(ask_with_default 'Percorso root da esporre al tool filesystem (Invio = cartella corrente)' '.')"
  confirm_choice "Filesystem root → ${ROOT}"
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
  warn "Nessun MCP per-progetto creato (userai solo gli MCP globali)."
fi

# 2) PRD
if ask_yes_no_default_yes "Vuoi creare il PRD (docs/PRD.md)? Se premi INVIO verrà creato ora"; then
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
  confirm_choice "PRD: non creato (scelta utente)"
fi

# 3) tasks
if ask_yes_no_default_yes "Vuoi creare i task (.cursor/tasks.json)? Se premi INVIO verranno creati ora"; then
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
  confirm_choice "Tasks: non creati (scelta utente)"
fi

# 4) file base
if ask_yes_no_default_yes "Vuoi creare i file base (.editorconfig, .gitignore, README)? Se premi INVIO verranno creati ora"; then
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
  confirm_choice "File base: non creati (scelta utente)"
fi

# ===== riepilogo =============================================================
step "riepilogo"
echo -e "${DIM}- MCP per-progetto:${RESET} $([[ -f .cursor/mcp.json ]] && echo 'filesystem' || echo 'nessuno')"
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
