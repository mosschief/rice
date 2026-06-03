# Network drives (SMB) in Thunar on Arch + Sway

How to browse and mount the Unraid SMB shares from Thunar (and the GTK file
chooser) on a fresh Arch install. The shares live on an Unraid server named
**DuckServer** (`DuckServer.local`).

The trap: installing `samba`/`smbclient`/`cifs-utils` is **not** enough for
Thunar's GUI. Thunar browses SMB through **gVFS**, which needs the separate
`gvfs-smb` backend. Without it, "Browse Network" is empty and `smb://` URLs do
nothing.

---

## 1. Install the gVFS SMB backend

```sh
sudo pacman -S --needed gvfs gvfs-smb
```

This provides `/usr/lib/gvfsd-smb` and `/usr/lib/gvfsd-smb-browse`, the pieces
Thunar uses to mount and list SMB shares. Restart Thunar so it reloads its
backends:

```sh
thunar -q && thunar &
```

That alone is enough to connect manually (see step 4). Steps 2–3 add automatic
network discovery and `.local` name resolution.

## 2. Network discovery (avahi / mDNS)

```sh
sudo pacman -S --needed nss-mdns avahi
sudo systemctl enable --now avahi-daemon
```

## 3. Resolve `.local` hostnames

Add `mdns_minimal [NOTFOUND=return]` just before `dns` (and before `resolve`)
on the `hosts:` line of `/etc/nsswitch.conf`:

```sh
sudo sed -i 's/ dns$/ mdns_minimal [NOTFOUND=return] dns/' /etc/nsswitch.conf
```

Result:

```
hosts: mymachines resolve [!UNAVAIL=return] files myhostname mdns_minimal [NOTFOUND=return] dns
```

Verify:

```sh
getent hosts DuckServer.local        # -> 10.69.69.201  DuckServer.local
avahi-browse -rt _smb._tcp           # lists SMB advertisers on the LAN
```

## 4. Connect

In Thunar use **Browse Network**, or jump straight there with `Ctrl+L`:

```
smb://DuckServer.local/network-drive     # one share
smb://DuckServer.local/                   # all shares
```

It prompts for credentials on first connect — use guest for public shares, or
your Unraid username/password, and tick **remember forever** to save them.

Current shares: `network-drive`, `Downloads`, `Music`, `domains` (VM instances).

## 5. Bookmarks (persistent sidebar shortcuts)

GTK bookmarks live in `~/.config/gtk-3.0/bookmarks` — one `URI [label]` per
line. This repo ships a copy at [`.config/gtk-3.0/bookmarks`](../.config/gtk-3.0/bookmarks):

```
smb://duckserver.local/network-drive/archive
smb://duckserver.local/network-drive/CNC
smb://duckserver.local/network-drive Network Drive
smb://duckserver.local/Downloads Downloads
smb://duckserver.local/Music Music
smb://duckserver.local/domains VM Domains
```

Copy it into place and relaunch Thunar:

```sh
cp .config/gtk-3.0/bookmarks ~/.config/gtk-3.0/bookmarks
thunar -q && thunar &
```

They appear in the Thunar sidebar; click one to mount.

## Troubleshooting

- **"Browse Network" empty / `smb://` does nothing** → `gvfs-smb` not installed
  (step 1), or Thunar wasn't restarted after installing it.
- **`DuckServer.local` won't resolve** → step 3 (nsswitch) not applied, or
  `avahi-daemon` not running (step 2).
- **No hosts auto-discovered** → modern SMB has NetBIOS/SMB1 browsing disabled;
  rely on avahi (`avahi-browse -rt _smb._tcp`) or connect by IP
  (`smb://10.69.69.201/`).
