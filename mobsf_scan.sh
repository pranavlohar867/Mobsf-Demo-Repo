#!/bin/bash
set -e

APP_FILE="app/DivaApplication.apk"
MOBSF_URL="http://host.docker.internal:8000"
API_KEY="$MOBSF_API_KEY"

echo "[*] Uploading APK to MobSF..."

UPLOAD=$(curl -s -X POST "$MOBSF_URL/api/v1/upload" \
  -H "Authorization: $API_KEY" \
  -F "file=@$APP_FILE")

HASH=$(echo $UPLOAD | jq -r '.hash')
SCAN_TYPE=$(echo $UPLOAD | jq -r '.scan_type')

if [ "$HASH" == "null" ]; then
  echo "[!] Upload failed"
  exit 1
fi

echo "[*] Starting scan..."
curl -s -X POST "$MOBSF_URL/api/v1/scan" \
  -H "Authorization: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"hash\":\"$HASH\",\"scan_type\":\"$SCAN_TYPE\"}" > /dev/null

echo "[*] Fetching report..."
curl -s -X POST "$MOBSF_URL/api/v1/report_json" \
  -H "Authorization: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"hash\":\"$HASH\",\"scan_type\":\"$SCAN_TYPE\"}" > mobsf-report.json

CRITICAL=$(jq '.security_score.critical' mobsf-report.json)
HIGH=$(jq '.security_score.high' mobsf-report.json)

echo "Critical: $CRITICAL | High: $HIGH"

if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
  echo "[!] Security gate failed"
  exit 1
fi

echo "[+] MobSF scan passed"
