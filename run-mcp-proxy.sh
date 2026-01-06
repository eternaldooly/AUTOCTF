#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${ROOT_DIR}/.env" ]]; then
  set -a
  source "${ROOT_DIR}/.env"
  set +a
fi

export PYTHONPATH="${ROOT_DIR}/mcp-proxy/src:${PYTHONPATH:-}"

PYTHON_BIN="${ROOT_DIR}/mcp-proxy/.venv/bin/python"
if [[ ! -x "${PYTHON_BIN}" ]]; then
  PYTHON_BIN="$(command -v python3 || command -v python)"
fi

if [[ $# -eq 0 ]]; then
  default_url="${MCP_PROXY_DEFAULT_URL:-${IDA_MCP_URL:-${IDA_MCP_SSE_URL:-}}}"
  if [[ -z "${default_url}" ]]; then
    host="${IDA_MCP_HOST:-}"
    port="${IDA_MCP_PORT:-}"
    if [[ -n "${host}" && -n "${port}" ]]; then
      default_url="http://${host}:${port}/sse"
    fi
  fi

  if [[ -z "${default_url}" ]]; then
    echo "run-mcp-proxy.sh: missing arguments." >&2
    echo "Usage: ${0} [mcp-proxy args...] <http://HOST:PORT/sse | command...>" >&2
    echo "Tip: set MCP_PROXY_DEFAULT_URL or (IDA_MCP_HOST and IDA_MCP_PORT) to run with no args." >&2
    exit 2
  fi

  exec "${PYTHON_BIN}" -m mcp_proxy "${default_url}"
fi

exec "${PYTHON_BIN}" -m mcp_proxy "$@"
