# guida avvio progetto con cursor + mcp

Questa guida spiega passo passo come inizializzare un nuovo progetto in **Cursor** usando il template GitHub con wizard MCP.

---

## 📋 prerequisiti (solo la prima volta)

1. **Node.js ≥ 18**

```bash
node -v
npm -v
```

2. **Git**

```bash
git --version
```

3. **Cursor** installato → [https://cursor.com](https://cursor.com)
4. **Token GitHub (PAT Classic)** con scope `repo` → [https://github.com/settings/tokens](https://github.com/settings/tokens)

---

## 🚀 flusso inizializzazione nuovo progetto

1. **Crea cartella vuota sul PC**

```bash
mkdir ~/Downloads/NOME-PROGETTO
cd ~/Downloads/NOME-PROGETTO
```

2. **Apri Cursor** e da `File → Open Project` seleziona la cartella appena creata.

3. **Crea repository GitHub dal template**

   * Vai su: [https://github.com/Rone-18/cursor-project-template](https://github.com/Rone-18/cursor-project-template)
   * `Use this template` → `Create a new repository`
   * Copia URL HTTPS del nuovo repo (scheda HTTPS → Copy)

4. **Clona il repository in Cursor**

```bash
git clone https://github.com/TUO-UTENTE/NOME-PROGETTO.git .
```

> Se privato: inserisci username GitHub e token PAT come password.

5. **Avvia il wizard**

```bash
npm run init
```

* **Seleziona MCP** → `1` (filesystem)
* **Percorso root** → `Invio` (usa default `.`)
* **Crea PRD** → `s`
* **Crea tasks** → `s`
* **Crea file base** → `s`
* Attendi **reload** di Cursor

6. **Verifica MCP attivi**
   In chat di Cursor:

```bash
/mcp
```

Dovresti vedere MCP globali + `filesystem`.

7. **Salva su GitHub**

```bash
git add .
git commit -m "chore: init project with wizard"
git push origin main
```

---

## 🔍 comandi utili di verifica

```bash
git status
git remote -v
git branch
node -v
npm -v
```

---

## 🛠 troubleshooting

* **Cartella non vuota**

```bash
rm -rf NOME-PROGETTO && mkdir NOME-PROGETTO && cd NOME-PROGETTO && git clone URL-REPO .
```

* **Auth failed** → rigenera PAT o `gh auth login`
* **Reload non va** → `Cmd+Shift+P` → Reload Window
