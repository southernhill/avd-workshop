# AVD Workshop — Prerequisites

Follow these steps **before** the workshop. You need three things installed: Docker Desktop, VS Code, and the Dev Containers extension.

---

## Step 1: Install WSL 2 (Windows only)

> **Mac users:** Skip this step.

1. Open **PowerShell as Administrator** (right-click > Run as administrator)
1. Run: `wsl --install`
1. Restart your computer when prompted
1. After restart, a terminal will open to set up your Ubuntu username and password — complete this
1. Verify WSL is running: `wsl --list --verbose`

You should see a distribution (e.g., `Ubuntu`) with `VERSION 2`.

---

## Step 2: Install Docker Desktop

1. Download Docker Desktop from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/)
2. Install it and start it
3. **Windows users:** In Docker Desktop, go to **Settings > General** and make sure **Use the WSL 2 based engine** is checked
4. Go to **Settings > Resources** and set **Memory Limit** to at least **16 GB**
5. Open a terminal and verify:

```bash
docker --version
```

You should see something like `Docker version 29.x.x`.

---

## Step 3: Install VS Code

1. Download VS Code from [code.visualstudio.com](https://code.visualstudio.com/)
2. Install it and open it

---

## Step 4: Install the Dev Containers extension

1. In VS Code, open the Extensions panel (`Ctrl+Shift+X` / `Cmd+Shift+X`)
2. Search for **Dev Containers**
3. Install the extension by Microsoft (ID: `ms-vscode-remote.remote-containers`)

---

## Step 5: Clone the workshop repo

Open a terminal and run:

```bash
git clone https://github.com/southernhill/avd-workshop.git
```

---

## Step 6: Open in Dev Container

1. Open VS Code
2. **File > Open Folder** — select the `avd-workshop` folder
3. VS Code will show a notification: _"Reopen in Container"_ — click it
   - Or use the command palette (`Ctrl+Shift+P` / `Cmd+Shift+P`) and search for **Dev Containers: Reopen in Container**
4. Wait for the container to build (first time takes a few minutes — it downloads the container image)
5. Once ready, you'll see a terminal inside VS Code

---

## Step 7: Verify everything works

In the VS Code terminal (inside the dev container), run:

```bash
make setup
```

This will:

- Download and import the cEOS switch image
- Set up the Python environment
- Install AVD and Ansible

Then verify:

```bash
make build
```

You should see `PLAY RECAP` with all `ok` and 4 config files generated.

Finally, start the lab and check it's running:

```bash
make lab
make lab-status
```

You should see 4 nodes (spine-01, spine-02, leaf-01, leaf-02) all in `running` state.

---

## Checklist

- [ ] WSL 2 installed (Windows only)
- [ ] Docker Desktop installed and running
- [ ] VS Code installed
- [ ] Dev Containers extension installed
- [ ] Repo cloned
- [ ] Dev container opens successfully
- [ ] `make setup` completes without errors
- [ ] `make build` generates 4 config files
- [ ] `make lab` starts the lab
- [ ] `make lab-status` shows 4 running nodes

If all boxes are checked, you're ready for the workshop.
