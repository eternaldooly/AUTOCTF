## AUTOCTF

AUTOCTF is a personal CTF hunting environment that combines a React/Vite frontend, a Node.js backend, and Codex + MCP (IDA, Volatility) integration, primarily intended to run inside WSL2 with a bridged Windows host.

There is no separate external AI backend required: as long as Codex is installed and logged in locally, the in-app terminal and MCP integrations will work.

Before running the project on a new machine, copy and adapt your `.env` file (Google OAuth IDs, DB path, IDA MCP paths/host/port, and category prompts) to match the local environment.

> 📝 **Interested in the development journey?** Read the full story on my blog: [Building an AI CTF Solver Platform](https://dooly.life/post/building-ai-ctf-solver-platform/)

## Demo

https://github.com/user-attachments/assets/468ad1f6-2852-4d1d-be7c-72e5ebe5e258

## Installation

```bash
cd /AUTOCTF
npm install
npx prisma migrate deploy   # Initialize database
npm run build
```

## AUTOCTF Environment Notes

### WSL2 Networking Setup (Windows side)

#### Option A: Mirrored Mode (Simple, but currently broken)

Add the following to `%UserProfile%\.wslconfig` (for example, `C:\Users\eternaldooly\.wslconfig`):

```ini
[wsl2]
networkingMode=mirrored

[experimental]
hostAddressLoopback=true
```

> **Warning (as of 2026.02.14):** A Windows security update has introduced a bug that prevents mirrored mode from functioning correctly. If you experience network instability or connection failures, use the Bridge method below instead.

#### Option B: Hyper-V Bridge (Recommended workaround)

Since mirrored mode is currently unreliable, the Hyper-V Bridge approach is the recommended alternative.

**1. Enable Hyper-V:**

```powershell
dism.exe /Online /Enable-Feature:Microsoft-Hyper-V /All
```

**2. Create an internal virtual switch:**

```powershell
New-VMSwitch -Name "WSLBridge" -SwitchType Internal
```

**3. Verify the new adapter was created:**

```powershell
Get-NetAdapter
```

You should see a new `vEthernet (WSLBridge)` adapter.

**4. Assign a static IP to the bridge adapter:**

```powershell
New-NetIPAddress -InterfaceAlias "vEthernet (WSLBridge)" -IPAddress 192.168.200.1 -PrefixLength 24
```

**5. Bridge to your physical network adapter:**

```powershell
Get-VMSwitch
Remove-VMSwitch -Name "WSLBridge" -Force
New-VMSwitch -Name "WSLBridge" -NetAdapterName "Ethernet" -AllowManagementOS $true
```

**6. Configure networking inside WSL2:**

```bash
sudo ip addr add 192.168.200.2/24 dev eth0
sudo ip link set eth0 up
sudo ip route add default via 192.168.200.1
```

> **Important:** The IP addresses (`192.168.200.x`), adapter name (`"Ethernet"`), and other network values above are examples. Adjust them to match your environment. Additionally, since mirrored mode uses `127.0.0.1` but Bridge assigns a different IP, you must also update the IP addresses in your `.env` file (`IDA_MCP_HOST`), Codex `config.toml` (MCP server URLs), and any other config that references the host address.

### AUTOCTF script execution permissions

Make the helper scripts executable once in WSL:

```bash
cd /AUTOCTF
chmod +x run-preview-and-server.sh
chmod +x run-mcp-proxy.sh
```

### Create a `poc` directory for local exploits/PoCs

The application itself does not require a `poc` directory, but prompts and workflows assume you will keep your exploit/solver code there.  
Create it once on each new machine:

```bash
mkdir -p /AUTOCTF/poc
```
### mcp-proxy download 
```
cd mcp-proxy
python3 -m venv .venv
./.venv/bin/pip install -e .
```

### idalib-mcp download 
https://github.com/mrexodia/ida-pro-mcp

### Codex `config.toml` example

The following is a minimal Codex configuration including Volatility MCP integration.  
Avoid hard-coding your username in paths; prefer `$HOME` or `/home/<username>` and adjust paths to your environment.

```toml
# AI Model Configuration
model = "gpt-5.2"
model_reasoning_effort = "xhigh"

# Project Security: Trusted paths for seamless AI access
[projects]
"$HOME" = { trust_level = "trusted" }
"$HOME/.codex" = { trust_level = "trusted" }
"/AUTOCTF" = { trust_level = "trusted" }

# MCP Servers: Volatility memory forensics integration
[mcp_servers.volatility-mcp]
command = "/usr/bin/python3"
args = [
    "/mnt/c/Volatility-MCP-Server-main/volatility_mcp_server.py",
    "--transport", "stdio"
]

# MCP Servers: ida mcp server
[mcp_servers.ida-mcp]
command = "/AUTOCTF/run-mcp-proxy.sh"
args = ["--debug", "http://127.0.0.1:13337/sse"] # Adjust IP/port as needed

# Startup/Tool Execution timeouts
startup_timeout_sec = 120.0
tool_timeout_sec = 60.0

[mcp_servers.volatility-mcp.env]
PYTHONUNBUFFERED = "1"
PROGRAMFILES = "C:\\Program Files"
SystemRoot = "C:\\Windows"

# Network & Access: Removing restrictions for tools
[network]
allow_all_outbound = true          # Allows MCP servers to access external networks
disable_tls_verification = false   # Consider true only when using internal self-signed proxies

# Notifications: Suppress unnecessary UI alerts
[notice]
hide_full_access_warning = true
hide_rate_limit_model_nudge = true
hide_gpt5_1_migration_prompt = true
"hide_gpt-5.1-codex-max_migration_prompt" = true
```

> Update all paths (`$HOME`, `/home/<username>`, Volatility MCP script path, etc.) to match your actual setup.

## References

- [mcp-proxy](https://github.com/sparfenyuk/mcp-proxy) - A bridge between Streamable HTTP and stdio MCP transports
