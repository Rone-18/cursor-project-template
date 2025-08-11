#!/usr/bin/env bash
# ------------------------------------------------------------
# Scopo: wizard iniziale per progetto usato in Cursor.
# Cosa fa (domande sì/no):
# 1) Configura MCP "filesystem" per *questo progetto* con root scelta.
# 2) Crea PRD (docs/PRD.md).
# 3) Crea task (.cursor/tasks.json) con accettazione chiara.
# 4) Genera file base (.editorconfig, .gitignore, README).
# Note: idempotente, non sovrascrive file già presenti.
# ------------------------------------------------------------

set -e

echo "==> Wizard iniziale progetto"

ask_yn () { read -r -p "$1 [s/N]: " a; [[ "$a" =~ ^([sSyY]|yes)$ ]]; }

# 1) MCP filesystem per-progetto
if ask_yn "Vuoi configurare MCP 'filesystem' per questo progetto?"; then
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
  echo "✅ Creato .cursor/mcp.json (filesystem → ${ROOT})"
fi

# 2) PRD
if ask_yn "Vuoi creare il PRD (docs/PRD.md)?"; then
  mkdir -p docs
  if [ ! -f docs/PRD.md ]; then
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
**Non-funzionali**: performance, accessibilità (WCAG AA), SEO base.

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

# 3) tasks
if ask_yn "Vuoi creare i task (.cursor/tasks.json)?"; then
  mkdir -p .cursor
  if [ ! -f .cursor/tasks.json ]; then
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

# 4) file base
if ask_yn "Vuoi creare file base (.editorconfig, .gitignore, README)?"; then
  if [ ! -f .editorconfig ]; then
    cat > .editorconfig <<'EC'
# Scopo: stile coerente tra editor
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

  if [ ! -f .gitignore ]; then
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

  if [ ! -f README.md ]; then
    cat > README.md <<'MD'
# progetto (inizializzato dal wizard)

- MCP globali (già in Cursor): sequential-thinking, refactor-mcp
- MCP per-progetto: filesystem in `.cursor/mcp.json` (se abilitato)
- Documentazione: `docs/PRD.md`
- Pianificazione: `.cursor/tasks.json`

## avvio rapido
1) Apri il progetto in Cursor.  
2) Terminale → `chmod +x scripts/init.sh && bash scripts/init.sh`  
3) Reload Window in Cursor → `/mcp`
MD
    echo "✅ README creato"
  else
    echo "ℹ️  README esistente: skip"
  fi
fi

echo "🎉 Fine wizard. Esegui Reload Window in Cursor e usa /mcp."
