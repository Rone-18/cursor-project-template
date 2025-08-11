#!/usr/bin/env bash
# ------------------------------------------------------------
# Wizard iniziale per progetto (da eseguire in Cursor)
# - Chiede quali componenti attivare
# - Configura MCP per-progetto (filesystem con path scelto)
# - Crea PRD, tasks e file base se richiesto
# ------------------------------------------------------------
set -euo pipefail

echo "==> Wizard iniziale progetto"

ask_yn () { read -r -p "$1 [s/N]: " a; [[ "$a" =~ ^([sSyY]|yes)$ ]]; }

# === 1) MCP per-progetto ======================================================
echo ""
echo "Seleziona MCP per questo progetto:"
echo "  1) filesystem (consigliato)  0) nessuno"
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
  echo "✅ MCP configurato: filesystem → ${ROOT}"
else
  echo "ℹ️  Nessun MCP per-progetto creato (userai solo i globali)."
fi

# === 2) PRD ===================================================================
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
    echo "✅ PRD creato"
  else
    echo "ℹ️  PRD esistente: skip"
  fi
fi

# === 3) Tasks =================================================================
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
    echo "✅ Tasks creati"
  else
    echo "ℹ️  Tasks esistenti: skip"
  fi
fi

# === 4) File base =============================================================
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
    echo "✅ .editorconfig creato"
  else
    echo "ℹ️  .editorconfig esistente: skip"
  fi

  if [[ ! -f .gitignore ]]; then
    cat > .gitignore <<'GI'
node_modules/
dist/
.env
.DS_Store
GI
    echo "✅ .gitignore creato"
  else
    echo "ℹ️  .gitignore esistente: skip"
  fi

  if [[ ! -f README.md ]]; then
    cat > README.md <<'MD'
# progetto (inizializzato dal wizard)

- MCP globali (in Cursor): sequential-thinking, refactor-mcp
- MCP per-progetto: filesystem in `.cursor/mcp.json` (se attivato)
- Documentazione: `docs/PRD.md`
- Pianificazione: `.cursor/tasks.json`

## avvio rapido
1) Terminale di Cursor → `npm run init` (puoi rilanciarlo quando vuoi)  
2) Dopo il wizard → `Cmd+Shift+P` → **Reload Window**  
3) In chat → `/mcp` per vedere i tool attivi
MD
    echo "✅ README creato"
  else
    echo "ℹ️  README esistente: skip"
  fi
fi

echo ""
echo "🎉 Fine wizard. In Cursor esegui: Cmd+Shift+P → Reload Window → /mcp"
