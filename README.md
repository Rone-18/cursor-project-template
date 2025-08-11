# guida avvio progetto con cursor + mcp

Questa guida spiega come iniziare un nuovo progetto in **Cursor** usando il template con **wizard** per configurare MCP, creare file base e documentazione, e collegare il progetto a GitHub.

---

## 📋 prerequisiti (da fare una sola volta sul Mac)

1. **Installa Node.js ≥ 18**

   * Scarica da [https://nodejs.org](https://nodejs.org)
   * Verifica:

     ```bash
     node -v
     npm -v
     ```

2. **Installa Git**

   * Su macOS è già incluso, verifica:

     ```bash
     git --version
     ```

3. **Installa Cursor** (ultima versione)

   * [https://cursor.com](https://cursor.com)

4. **Configura MCP globali in Cursor**

   * `sequential-thinking`
   * `refactor-mcp`

5. **(Opzionale ma consigliato)** installa CLI di Cursor

   * In Cursor → `Cmd+Shift+P` → “Shell Command: Install 'cursor' command in PATH”
   * Verifica:

     ```bash
     cursor --version
     ```

6. **Crea un token GitHub (PAT Classic)** con scope `repo`

   * [https://github.com/settings/tokens](https://github.com/settings/tokens)

---

## 🚀 avvio di un nuovo progetto

### 1) crea repo GitHub dal template

1. Vai su: [https://github.com/Rone-18/cursor-project-template](https://github.com/Rone-18/cursor-project-template)
2. Clicca **Use this template** → **Create a new repository**
3. Scegli nome, visibilità (Private o Public), conferma
4. Copia l’URL **HTTPS** del repo:
   GitHub → **Code** → scheda **HTTPS** → copia

---

### 2) prepara la cartella locale e clona

```bash
# crea cartella del progetto
mkdir -p ~/Projects/NOME-PROGETTO
cd ~/Projects/NOME-PROGETTO

# clona il repo dentro la cartella
git clone https://github.com/TUO-UTENTE/NOME-PROGETTO.git .
```

> **Nota:** se il repo è privato, Git chiederà:
>
> * **Username**: il tuo utente GitHub
> * **Password**: il PAT (token) creato prima

---

### 3) apri in Cursor

```bash
cursor .
```

Oppure: **File → Open Folder…** → seleziona la cartella del progetto.

---

### 4) avvia il wizard di configurazione

```bash
npm run init
```

Oppure:

* `Cmd+Shift+P` → **Run Task** → **Wizard: init project**

Il wizard ti guiderà in:

* Attivazione MCP per-progetto (`filesystem`)
* Creazione **PRD** (`docs/PRD.md`)
* Creazione **tasks** (`.cursor/tasks.json`)
* Creazione file base (`.editorconfig`, `.gitignore`, `README.md`)
* Tentativo di **reload automatico** di Cursor

---

### 5) verifica MCP attivi

In chat di Cursor:

```
/mcp
```

Devi vedere:

* MCP globali: `sequential-thinking`, `refactor-mcp`
* MCP per-progetto: `filesystem` (se attivato)

---

### 6) salva su GitHub

```bash
git status
git add .
git commit -m "chore: init project with wizard"
git push origin main
```

---

## 🔍 comandi di verifica rapida

* **Verifica MCP globali**

  * In Cursor: `Cmd+,` → **Tools & Integrations → MCP Tools**
* **Verifica repo collegato**

  ```bash
  git remote -v
  ```
* **Verifica branch**

  ```bash
  git branch
  ```
* **Verifica modifiche locali**

  ```bash
  git status
  ```
* **Verifica Node/NPM**

  ```bash
  node -v
  npm -v
  ```

---

## 🔐 autenticazione github (token)

Per cloni/push su repository **privati** via HTTPS serve un **Personal Access Token (PAT)**.

* Consigliato: **Classic token** con scope **repo** (funziona per tutti i tuoi progetti).
* Crea/gestisci il token: [https://github.com/settings/tokens](https://github.com/settings/tokens)
* Quando `git` chiede le credenziali:

  * **Username** → il tuo utente GitHub
  * **Password** → incolla il token

In alternativa usa GitHub CLI:

```bash
brew install gh
gh auth login
```

---

## ⚡️ setup rapido (copia‑incolla)

Sostituisci `UTENTE` e `NOME-PROGETTO` e incolla tutto in un terminale **nuovo** nella cartella in cui vuoi creare il progetto:

```bash
# crea cartella e posizionati
mkdir -p ~/Projects/NOME-PROGETTO && cd ~/Projects/NOME-PROGETTO

# clona dentro la cartella corrente (se private: user = utente GitHub, password = PAT)
git clone https://github.com/UTENTE/NOME-PROGETTO.git .

# (opzionale) apri direttamente in Cursor se hai la CLI installata
cursor . || true

# avvia il wizard di setup
npm run init
```

Se il repository è **privato** e l’autenticazione fallisce:

```bash
gh auth login
```

poi ripeti il `git clone`.

---

## 🛠 troubleshooting

* **Cartella non vuota**

  ```bash
  rm -rf NOME-PROGETTO
  mkdir NOME-PROGETTO
  cd NOME-PROGETTO
  git clone URL-REPO .
  ```

* **Authentication failed**

  * Rigenera PAT: [https://github.com/settings/tokens](https://github.com/settings/tokens)
  * Oppure:

    ```bash
    gh auth login
    ```

* **cursor: command not found**

  * Installa CLI da Cursor → `Cmd+Shift+P` → “Shell Command: Install 'cursor' command in PATH”

* **Reload non funziona**

  * `Cmd+Shift+P` → **Reload Window**

---

## 📄 licenza

MIT
