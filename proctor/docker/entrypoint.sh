#!/bin/sh
set -eu

missing=0
for var in KEYCLOAK_HOST KEYCLOAK_REALM KEYCLOAK_CLIENT_ID; do
    eval "val=\${$var:-}"
    if [ -z "$val" ]; then
        echo "${var} is required" >&2
        missing=1
    fi
done
[ "$missing" -ne 0 ] && exit 1

cat > /usr/share/nginx/html/config.json <<EOF
{
  "keycloakUrl": "${KEYCLOAK_HOST}",
  "keycloakRealm": "${KEYCLOAK_REALM}",
  "keycloakClientId": "${KEYCLOAK_CLIENT_ID}"
}
EOF

exec nginx -g 'daemon off;'
