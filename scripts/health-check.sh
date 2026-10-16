#!/usr/bin/env bash
set -u

URLS=(
  "https://kamilpietka.dev"
  "https://vouchers.kamilpietka.dev"
  "https://api-vouchers.kamilpietka.dev"
  "https://mojabiblioteka.kamilpietka.dev"
  "https://mojabiblioteka.app"
  "https://www.mojabiblioteka.app"
)

failed=0

for url in "${URLS[@]}"; do
  printf "%-52s " "$url"

  status="$(
    curl -L -sS -o /dev/null \
      -w "%{http_code}" \
      --connect-timeout 8 \
      --max-time 15 \
      "$url" || true
  )"

  if [[ "$status" =~ ^[23] ]]; then
    echo "OK ($status)"
  else
    echo "FAILED (${status:-no response})"
    failed=1
  fi
done

exit "$failed"
