#!/usr/bin/env bash

docker run --rm \
  -v docker_franklyn-keycloak-data:/opt/keycloak/data \
  -v $(pwd)/realm.json:/tmp/realm.json \
  --entrypoint /opt/keycloak/bin/kc.sh \
  quay.io/keycloak/keycloak:latest \
  export --file /tmp/realm.json --realm franklyn



