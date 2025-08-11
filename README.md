# cursor project template

Template per inizializzare progetti Cursor con wizard guidato (MCP per-progetto, PRD, tasks, file base).

## come si usa
1. In GitHub: **Use this template** → crea nuovo repository.
2. Clona e apri in Cursor.
3. Avvia il wizard:
   - Terminale: `npm run init`, **oppure**
   - Cmd+Shift+P → **Run Task → "Wizard: init project"**
4. Rispondi alle domande (filesystem, PRD, tasks, file base).
5. **Reload Window** in Cursor (Cmd+Shift+P) → in chat digita `/mcp`.

## cosa fa il wizard
- Crea `.cursor/mcp.json` con **filesystem** e **path** scelto.
- (Opzionale) `docs/PRD.md`
- (Opzionale) `.cursor/tasks.json`
- (Opzionale) `.editorconfig`, `.gitignore`, `README.md` di progetto

## prerequisiti
- In Cursor, MCP globali consigliati: `sequential-thinking`, `refactor-mcp`.
