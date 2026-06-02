# Autodesk Fusion 360 on Arch Linux + Sway

How I got Autodesk Fusion 360 running on Arch Linux (Sway/Wayland, Surface
Laptop 4) via Proton, including every non-obvious fix. There is no native Linux
build of Fusion; it runs under a Fusion-patched Wine/Proton.

- **Runtime:** `GE-Proton10-Fusion` (a Fusion-patched Proton build)
- **Prefix:** `~/.autodesk_fusion/protonprefix`
- **Install:** `~/.autodesk_fusion/protonprefix/pfx/drive_c/Program Files/Autodesk/webdeploy/production/<hash>/Fusion360.exe`
- **Compositor:** Sway (wlroots) + XWayland, HiDPI scale 1.75

The installer that does most of the heavy lifting is the **cryinkfly** project.
The GitHub repo is archived; the **active fork is on Codeberg**:
<https://codeberg.org/cryinkfly/Autodesk-Fusion-360-on-Linux>

---

## 1. Prerequisites

Enable the `multilib` repo in `/etc/pacman.conf`, then install dependencies:

```sh
sudo pacman -S --needed wine wine-mono wine-gecko winetricks \
    p7zip curl wget yad zenity samba lib32-gnutls \
    lib32-mesa vulkan-radeon lib32-vulkan-radeon
# Steam provides the Proton runtime plumbing used to launch outside Steam:
sudo pacman -S --needed steam
```

(AMD Renoir iGPU here → `vulkan-radeon` / RADV. Use the right Vulkan driver for
your GPU.)

## 2. Install Fusion via the cryinkfly installer

Download the installer from the Codeberg repo and run it. It installs 7-Zip,
WebView2, the Fusion client, sets up the prefix, and applies the standard DLL
overrides.

> **Installer bug (v2.0.7-Alpha):** a function definition was missing its
> parentheses (`is_snap_firefox_installed {` → `is_snap_firefox_installed() {`),
> which aborts the script. Fixed upstream/forked. If your installer aborts with
> a bash syntax error near that function, add the `()`.

Choose **Proton** as the runtime when prompted (the system Wine 11.x path
core-dumps for me; Proton works).

## 3. Reliable launching

The launcher bundled with the installer
(`~/.autodesk_fusion/bin/autodesk_fusion_launcher.sh`) is unreliable on Sway:

- It starts the **full Steam client** (unneeded, heavyweight).
- Its `run_autodesk_fusion_proton()` runs `wineserver -k` *immediately after*
  `proton run` returns — but `Fusion360.exe` is a bootstrapper that returns
  fast, so it **kills the prefix while Fusion is still booting**.

Use the direct launcher in this repo instead:
[`scripts/fusion-direct-launch.sh`](../scripts/fusion-direct-launch.sh). Core of it:

```sh
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.local/share/Steam"
export STEAM_COMPAT_DATA_PATH="$HOME/.autodesk_fusion/protonprefix"
PROTON="$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton10-Fusion/proton"
FUSION="$(find "$HOME/.autodesk_fusion/protonprefix/pfx" -name Fusion360.exe -path '*production*' | head -1)"
"$PROTON" run "$FUSION"
```

The script also:
- **Retries** the intermittent `double free or corruption` startup crash (a
  Proton startup race) up to 3×.
- **Sizes the Wine virtual desktop dynamically** (see §6).

Install it to `~/.autodesk_fusion/bin/fusion-direct-launch.sh` and point the
app-menu entry at it.

> The generated desktop entry
> `~/.local/share/applications/wine/Programs/Autodesk/Autodesk Fusion.desktop`
> was **malformed**: the `Exec=` line had been concatenated onto the
> `StartupWMClass=` line (so there was no valid `Exec` key and the menu item did
> nothing), plus a duplicate `Icon` key. Fix it to a proper:
> ```
> StartupWMClass=fusion360.exe
> Exec=/home/<user>/.autodesk_fusion/bin/fusion-direct-launch.sh
> ```

### Launching from wmenu

`wmenu-run` (like `dmenu_run`) lists executables on `$PATH`, **not** `.desktop`
files — so the app-menu entry above won't appear in it. Drop a short `fusion`
command onto your `PATH`:

```sh
ln -sf ~/.autodesk_fusion/bin/fusion-direct-launch.sh ~/.local/bin/fusion
```

Then `Alt+D` → type `fusion` → Enter (or just run `fusion` in a terminal).
`wmenu-run` caches its binary list, so a brand-new entry may take one refresh to
show up.

---

## 4. Startup abort: `bcp47langs.dll.GetUserLanguages`

Under Wine 10 / GE-Proton, Fusion aborts on launch calling an unimplemented
function in `bcp47langs.dll`. Fix with a registry **DLL override that disables
the stub** (empty string), plus the standard Fusion overrides. In the prefix
(`HKCU\Software\Wine\DllOverrides`):

| DLL                    | Value     |
| ---------------------- | --------- |
| `bcp47langs`           | *(empty)* |
| `adpclientservice.exe` | `native`  |
| `AdCefWebBrowser.exe`  | `builtin` |
| `msvcp140`             | `native`  |
| `mfc140u`              | `native`  |

The cryinkfly installer sets most of these; the empty `bcp47langs` is the key
one for the startup abort.

## 5. Login (Autodesk sign-in via browser)

Sign-in opens your real browser for OAuth and calls back via the custom
`adskidmgr://` URL scheme. The handler the installer writes can point at the
wrong Wine/prefix and the app hangs on "Signing in". The handler at
`~/.local/share/applications/wine/Programs/Autodesk/adskidmgr-opener.desktop`
must run `AdskIdentityManager.exe` through the **same Proton runtime + prefix**:

```ini
Exec=sh -c 'export STEAM_COMPAT_CLIENT_INSTALL_PATH="$HOME/.local/share/Steam"; \
export STEAM_COMPAT_DATA_PATH="$HOME/.autodesk_fusion/protonprefix"; \
PROTON="$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton10-Fusion/proton"; \
IDM="$(find "$HOME/.autodesk_fusion/protonprefix/pfx" -name AdskIdentityManager.exe | head -1)"; \
"$PROTON" runinprefix "$IDM" "$1"' _ %u
```

Re-register it:

```sh
update-desktop-database ~/.local/share/applications
xdg-mime default wine-Programs-Autodesk-adskidmgr-opener.desktop x-scheme-handler/adskidmgr
```

After first successful login the session is cached and subsequent launches go
straight to the workspace.

---

## 6. Black export/save dialogs (DXF, etc.) — patch `Qt6WebEngineCore.dll`

**Symptom:** invoking an export/save dialog (e.g. *Save As DXF*) shows a black
window; the dialog never paints; `QtWebEngineProcess.exe` instances constantly
respawn.

**Root cause:** Fusion's export/save dialogs are rendered with Qt WebEngine
(Chromium). Under Wine the renderer hits an `INT3` breakpoint right after a
`VirtualProtect` call: the code checks whether the *previous* page protection
was `PAGE_READWRITE`, but Wine reports a different value, so the check fails and
traps — killing the renderer. (Analysis & background:
[cryinkfly issue #421](https://github.com/cryinkfly/Autodesk-Fusion-360-for-Linux/issues/421).)

**Fix:** NOP that one `INT3` (`0xCC` → `0x90`) in `Qt6WebEngineCore.dll` (in the
`webdeploy/production/<hash>/` directory).

> **Do not use the prebuilt drop-in DLL** from the installer
> (`Qt6WebEngineCore-06-2025.7z`) unless it matches your Fusion's Chromium
> build. Mine is `Chrome/122.0.6261.171` (154 MB); the prebuilt is a different
> build (140 MB) and would mismatch the rest of the Qt6 WebEngine stack
> (`QtWebEngineProcess.exe`, `Qt6WebEngineWidgets.dll`, the `.pak` resources).

The byte offset is **version-specific**. Find it for your build: the trap idiom
`test eax,0xfffffffb ; jz +1 ; int3` is the byte sequence
`a9 fb ff ff ff 74 01 cc`, which is **unique** in the DLL. NOP the trailing
`cc`:

```sh
DLL="$(find ~/.autodesk_fusion/protonprefix/pfx -name Qt6WebEngineCore.dll -path '*production*' | head -1)"
cp -n "$DLL" "$DLL.bak"                              # backup
python3 - "$DLL" <<'PY'
import sys
p=sys.argv[1]; d=bytearray(open(p,'rb').read())
sig=bytes.fromhex('a9fbffffff7401cc')               # test eax,~4 ; jz +1 ; int3
i=d.find(sig); assert i>=0 and d.find(sig,i+1)<0, "signature not unique"
off=i+len(sig)-1; assert d[off]==0xCC
d[off]=0x90; open(p,'wb').write(d)
print("patched INT3->NOP at offset", hex(off))
PY
```

After patching (and relaunching), the crash is gone — `QtWebEngineProcess`
count stays stable and the dialog renders. The export works.

## 7. Browser panel sticky across workspaces + modal shield — Wine virtual desktop

**Symptom:** Fusion's **Browser** panel (model tree of sketches/bodies) and its
modal dialogs appear *on top of every Sway workspace*; the modal "dim" behind a
dialog renders as **opaque black**.

**Root cause:** Fusion draws those panels/dialogs as **override-redirect**
XWayland windows. Sway can't manage them (they're not in `_NET_CLIENT_LIST`), so
it can't assign them to a workspace — they leak everywhere. The modal dim
overlay uses Qt translucency (`WA_TranslucentBackground`), which has no working
ARGB visual under Wine's X11 driver, so it's opaque black. (Not a Chromium-GPU
issue — identical with and without `--disable-gpu`.)

**Fix:** run Fusion in a **Wine virtual desktop**, so Wine renders *all* Fusion
windows as children inside one managed "Wine Desktop" X window. Nothing leaks to
other workspaces; the whole thing is one window Sway can tile / fullscreen
(`Mod1+f`) / move between workspaces. Registry (in the prefix):

```
HKCU\Software\Wine\Explorer\Desktops   Default = <WIDTH>x<HEIGHT>
HKCU\Software\Wine\Explorer            Desktop = Default
```

Set it with:

```sh
WINE="$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton10-Fusion/files/bin/wine"
PFX="$HOME/.autodesk_fusion/protonprefix/pfx"
WINEPREFIX="$PFX" "$WINE" reg add 'HKCU\Software\Wine\Explorer\Desktops' /v Default /t REG_SZ /d 1289x859 /f
WINEPREFIX="$PFX" "$WINE" reg add 'HKCU\Software\Wine\Explorer'          /v Desktop /t REG_SZ /d Default /f
```

The virtual desktop is **WM-resizable** (Sway tiling resizes it; it's not locked
to the initial size). `scripts/fusion-direct-launch.sh` sets the size
**dynamically each launch** to the focused Sway output's logical resolution
(`swaymsg -t get_outputs`), so it also fits an external monitor — just launch
Fusion while focused on that monitor.

**Revert:** delete the `Desktop` value under `HKCU\Software\Wine\Explorer` (and
drop the dynamic-size block from the launcher).

> **Trade-off:** with everything contained, the opaque modal shield (§7 root
> cause) now covers the whole Fusion window when a dialog is open, instead of
> only the main area. The export still works behind it.

---

## 8. Where exported files go (Downloads symlink)

Under Proton the Wine user is **`steamuser`**, so Fusion's `C:\users\steamuser\`
maps to:

```
~/.autodesk_fusion/protonprefix/pfx/drive_c/users/steamuser/
```

A DXF saved to "Downloads" therefore lands in
`…/users/steamuser/Downloads/` — buried in the prefix. Symlink Wine's Downloads
to your real `~/Downloads` so exports land somewhere reachable:

```sh
WD="$HOME/.autodesk_fusion/protonprefix/pfx/drive_c/users/steamuser/Downloads"
mv -n "$WD"/* "$HOME/Downloads/" 2>/dev/null   # rescue anything already there
rmdir "$WD"
ln -s "$HOME/Downloads" "$WD"
```

Now "Save to Downloads" in Fusion writes straight to `~/Downloads`. (The symlink
lives in the prefix — redo it if the prefix is ever rebuilt.) The same trick
works for `Documents`, `Desktop`, etc.

## Summary of what's where

| Thing | Path |
| ----- | ---- |
| Proton runtime | `~/.local/share/Steam/compatibilitytools.d/GE-Proton10-Fusion` |
| Prefix | `~/.autodesk_fusion/protonprefix` |
| Fusion exe | `…/protonprefix/pfx/drive_c/Program Files/Autodesk/webdeploy/production/<hash>/Fusion360.exe` |
| Launcher | `~/.autodesk_fusion/bin/fusion-direct-launch.sh` ([repo copy](../scripts/fusion-direct-launch.sh)) |
| wmenu command | `~/.local/bin/fusion` → symlink to the launcher |
| App-menu entry | `~/.local/share/applications/wine/Programs/Autodesk/Autodesk Fusion.desktop` |
| Login handler | `~/.local/share/applications/wine/Programs/Autodesk/adskidmgr-opener.desktop` |
| Qt patch target | `…/production/<hash>/Qt6WebEngineCore.dll` (backup `.dll.bak`) |
| Downloads | `…/users/steamuser/Downloads` → symlink to `~/Downloads` |
