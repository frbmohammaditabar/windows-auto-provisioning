#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<EOF
Usage:
  $0 <IP> <role> <playbook-dir>
  OR
  $0 --vmid <vmid> --node <node> <role> <playbook-dir>

Environment (if using Proxmox API mode):
  PM_API_URL       e.g. https://proxmox.example.com:8006/api2/json
  PM_USER          Proxmox user (root@pam or token)
  PM_PASSWORD      Proxmox password or token secret
  VAULT_ADDR       Vault address (for fetching Windows admin password)
  VAULT_TOKEN      Vault token
EOF
  exit 2
}

# parse args
if [ "$1" = "--vmid" ]; then
  VMID="$2"
  shift 2
  if [ "$1" = "--node" ]; then
    NODE="$2"
    shift 2
  else
    echo "Missing --node <node>"
    usage
  fi
  ROLE="$1"; PLAYBOOK_DIR="$2"
  USE_PROXMOX_API=1
else
  VM_IP="$1"; ROLE="$2"; PLAYBOOK_DIR="$3"
  USE_PROXMOX_API=0
fi

if [ "$USE_PROXMOX_API" -eq 1 ]; then
  : "${PM_API_URL:?PM_API_URL must be set when using --vmid}"
  : "${PM_USER:?PM_USER must be set when using --vmid}"
  : "${PM_PASSWORD:?PM_PASSWORD must be set when using --vmid}"

  # login: get ticket & CSRF token, or use API token/pveproxy
  # If PM_USER format user@pve!tokenid then PM_PASSWORD is token secret and we can use header 'Authorization: PVEAPIToken=<user>@<realm>=<tokenid>=<secret>'
  # Simpler: use cookie-based auth
  LOGIN_JSON=$(curl -skS -X POST "${PM_API_URL%/api2/json}/access/ticket" \
    -d "username=${PM_USER}&password=${PM_PASSWORD}")
  TICKET=$(echo "$LOGIN_JSON" | jq -r '.data.ticket')
  CSRF=$(echo "$LOGIN_JSON" | jq -r '.data.CSRFPreventionToken')

  if [ -z "$TICKET" ] || [ "$TICKET" = "null" ]; then
    echo "Proxmox login failed"
    echo "$LOGIN_JSON"
    exit 10
  fi

  # helper to call agent network-get-interfaces
  fetch_ip_from_agent() {
    # call guest agent network-get-interfaces which returns interfaces including ip-addresses
    RES=$(curl -skS -b "PVEAuthCookie=${TICKET}" -H "CSRFPreventionToken: ${CSRF}" \
      "${PM_API_URL%/api2/json}/nodes/${NODE}/qemu/${VMID}/agent/network-get-interfaces")
    echo "$RES"
  }

  # try repeatedly for up to 10 minutes to get an IPv4 address
  START=$(date +%s)
  TIMEOUT=600
  SLEEP=10
  FOUND_IP=""
  while true; do
    AGENT_JSON=$(fetch_ip_from_agent || true)
    # parse ip (look for ipv4 first)
    FOUND_IP=$(echo "$AGENT_JSON" | jq -r '.data[]?.ip-addresses[]? | select(.family=="ipv4") | .ip-address' 2>/dev/null | head -n1 || true)
    if [ -n "$FOUND_IP" ] && [ "$FOUND_IP" != "null" ]; then
      VM_IP="$FOUND_IP"
      echo "Found IP via guest agent: $VM_IP"
      break
    fi
    NOW=$(date +%s)
    ELAPSED=$((NOW-START))
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
      echo "Timed out waiting for IP via guest agent. Last response:"
      echo "$AGENT_JSON"
      exit 11
    fi
    echo "Waiting for guest-agent IP... sleeping ${SLEEP}s"
    sleep "$SLEEP"
  done
fi

# Vault checks: need VAULT_ADDR and VAULT_TOKEN
if [ -z "${VAULT_ADDR:-}" ] || [ -z "${VAULT_TOKEN:-}" ]; then
  echo "ERROR: VAULT_ADDR or VAULT_TOKEN not set; cannot fetch Windows admin password from Vault"
  exit 12
fi

if ! command -v vault >/dev/null 2>&1; then
  echo "ERROR: vault CLI not found in PATH. Install it or fetch the password another way."
  exit 13
fi

# fetch admin password (adjust vault path to your secret location)
ADMIN_PASS=$(vault kv get -field=admin_password secret/windows/ || true)
if [ -z "$ADMIN_PASS" ]; then
  echo "ERROR: Could not read admin password from Vault path secret/windows/"
  exit 14
fi

# create inventory
INV=$(mktemp /tmp/inv.XXXXXX)
cat > "$INV" <<EOF
[windows]
${VM_IP} ansible_user=Administrator ansible_password=${ADMIN_PASS} ansible_connection=winrm ansible_port=5985 ansible_winrm_server_cert_validation=ignore ansible_winrm_transport=ntlm
EOF

echo "Inventory written to $INV for $VM_IP"

# wait for winrm
for i in $(seq 1 40); do
  if ansible -i "$INV" windows -m win_ping -u Administrator --extra-vars "ansible_password=${ADMIN_PASS}" >/dev/null 2>&1; then
    echo "WinRM up"
    break
  fi
  echo "Waiting for WinRM (attempt $i)..."
  sleep 15
done

case "$ROLE" in
  dc|domain_controller)    PB="${PLAYBOOK_DIR}/domain_controller.yml" ;;
  admin|admin_server)      PB="${PLAYBOOK_DIR}/admin_server.yml" ;;
  rds|rds_server)          PB="${PLAYBOOK_DIR}/rds_server.yml" ;;
  dfs|dfs_server)          PB="${PLAYBOOK_DIR}/dfs_server.yml" ;;
  *)
    echo "Unknown role: $ROLE"
    rm -f "$INV"
    exit 15
    ;;
esac

echo "Running ansible-playbook $PB"
ansible-playbook -i "$INV" "$PB"

rm -f "$INV"
