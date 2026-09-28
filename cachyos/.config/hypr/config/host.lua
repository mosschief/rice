-- Picks the per-machine file in config/hosts/ by DMI vendor, so the same
-- config/*.lua runs on every machine. Hostnames are not used: the work laptop's
-- is a corporate FQDN that can change on re-enrolment.
--
-- Anything unrecognised gets framework.lua, which is what this config was
-- written on, so an unknown machine behaves as before the split.

local hosts = {
    ["Framework"] = "framework",   -- Framework Laptop 13 Pro, CachyOS
    ["HP"]        = "elitebook",   -- HP EliteBook 8 G1i, Ubuntu 24.04 (work)
}

local function readLine(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local line = f:read("*l")
    f:close()
    return line
end

HOST_VENDOR = readLine("/sys/class/dmi/id/sys_vendor") or ""
HOST = hosts[HOST_VENDOR] or "framework"

require("config.hosts." .. HOST)
