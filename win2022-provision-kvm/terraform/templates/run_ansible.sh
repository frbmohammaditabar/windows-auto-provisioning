#!/usr/bin/env bash
set -euo pipefail

VM_IP="$1"
ROLE="$2"
PLAYBOOK_DIR="$3"

# Ensure Vault env vars exist
if [ -z "${VAULT_ADDR:-}" ] || [ -z "${VAULT_TOKEN:-}" ]; then
  echo "ERROR: VAULT_ADDR or VAULT_TOKEN not set"
  exit 2
fi

# Fetch Windows Administrator password from Vault
# Adjust the path "secret/data/windows/admin" to match your Vault setup
ADMIN_PASS=$(vault kv get -field=admin_password secret/windows/ || true)

if [ -z "$ADMIN_PASS" ]; then
  echo "ERROR: Could not retrieve Administrator password from Vault"
  exit 3
fi

# Create temporary inventory
INV="$(mktemp /tmp/inv.XXXXXX)"
cat > "$INV" <<EOF
[windows]
$VM_IP ansible_user=Administrator ansible_password=$ADMIN_PASS ansible_connection=winrm ansible_port=5985 ansible_winrm_server_cert_validation=ignore ansible_winrm_transport=ntlm
EOF

echo "Waiting for WinRM on $VM_IP ..."
for i in {1..40}; do
  ansible-playbook -i "$INV" "$PLAYBOOK_DIR/wait_for_winrm.yml" && break || {
    echo "WinRM not ready yet (attempt $i). sleeping 15s"
    sleep 15
  }
done

# Pick the right playbook based on role
case "$ROLE" in
  dc|domain_controller)    PB="$PLAYBOOK_DIR/domain_controller.yml" ;;
  admin|admin_server)      PB="$PLAYBOOK_DIR/admin_server.yml" ;;
  rds|rds_server)          PB="$PLAYBOOK_DIR/rds_server.yml" ;;
  dfs|dfs_server)          PB="$PLAYBOOK_DIR/dfs_server.yml" ;;
  *) echo "Unknown role $ROLE"; exit 4 ;;
esac

echo "Running $PB against $VM_IP"
ansible-playbook -i "$INV" "$PB"

rm -f "$INV"
