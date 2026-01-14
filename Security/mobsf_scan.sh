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

echo "[*] Waiting for scan to complete..."
while true; do
    STATUS=$(curl -s -X POST "$MOBSF_URL/api/v1/scan_status" \
        -H "Authorization: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"hash\":\"$HASH\"}" | jq -r '.status')

    if [ "$STATUS" == "Completed" ]; then
        break
    fi

    echo "[*] Scan status: $STATUS. Waiting 5 seconds..."
    sleep 5
done

echo "[*] Fetching JSON report..."
curl -s -X POST "$MOBSF_URL/api/v1/report_json" \
  -H "Authorization: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"hash\":\"$HASH\",\"scan_type\":\"$SCAN_TYPE\"}" > mobsf-report.json

echo "[*] Fetching HTML report..."
curl -s -X POST "$MOBSF_URL/api/v1/report_html" \
  -H "Authorization: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"hash\":\"$HASH\",\"scan_type\":\"$SCAN_TYPE\"}" > mobsf-report.html

echo "Critical: $CRITICAL | High: $HIGH"

if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
  echo "[!] Security gate failed"
  exit 1
fi

echo "[+] MobSF scan passed"

