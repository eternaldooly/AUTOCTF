## AUTOCTF

AUTOCTF is a personal CTF hunting environment that combines a React/Vite frontend, a Node.js backend, and Codex + MCP (IDA, Volatility) integration, primarily intended to run inside WSL2 with a bridged Windows host.

There is no separate external AI backend required: as long as Codex is installed and logged in locally, the in-app terminal and MCP integrations will work.

Before running the project on a new machine, copy and adapt your `.env` file (Google OAuth IDs, DB path, IDA MCP paths/host/port, and category prompts) to match the local environment.

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

### WSL2 mirrored mode (Windows side)
Add the following to `%UserProfile%\.wslconfig` (for example, `C:\Users\eternaldooly\.wslconfig`):

   ```ini
   [wsl2]
   networkingMode=mirrored
   
   [experimental]
   hostAddressLoopback=true
   ```


This example assumes **Windows: 192.168.200.1 / WSL: 192.168.200.2**. Adjust the IP range and adapter names to match your own network.

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
