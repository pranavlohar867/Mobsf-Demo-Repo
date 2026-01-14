#!/bin/bash
set -e

APP_FILE="app/DivaApplication.apk"
MOBSF_URL="http://host.docker.internal:8000"
API_KEY="$MOBSF_API_KEY"

echo "[*] Checking APK..."
if [ ! -f "$APP_FILE" ]; then
  echo "[!] APK not found at $APP_FILE"
  exit 1
fi

echo "[*] Uploading APK to MobSF..."
UPLOAD=$(curl -s -X POST "$MOBSF_URL/api/v1/upload" \
  -H "Authorization: $API_KEY" \
  -F "file=@$APP_FILE")

HASH=$(echo "$UPLOAD" | jq -r '.hash')
SCAN_TYPE=$(echo "$UPLOAD" | jq -r '.scan_type')

if [ -z "$HASH" ] || [ "$HASH" = "null" ]; then
  echo "[!] Upload failed"
  exit 1
fi

echo "[*] Starting scan..."
curl -s -X POST "$MOBSF_URL/api/v1/scan" \
  -H "Authorization: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"hash\":\"$HASH\",\"scan_type\":\"$SCAN_TYPE\"}" > /dev/null

# Wait for scan completion
echo "[*] Waiting for scan to complete..."
while true; do
    STATUS=$(curl -s -X POST "$MOBSF_URL/api/v1/scan_status" \
        -H "Authorization: $API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"hash\":\"$HASH\"}" | jq -r '.status')

    if [ "$STATUS" = "Completed" ]; then
        echo "[*] Scan completed!"
        break
    fi

    echo "[*] Scan status: $STATUS. Waiting 5 seconds..."
    sleep 5
done

# Fetch JSON report
echo "[*] Fetching JSON report..."
curl -s -X POST "$MOBSF_URL/api/v1/report_json" \
  -H "Authorization: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"hash\":\"$HASH\",\"scan_type\":\"$SCAN_TYPE\"}" \
  -o mobsf-report.json

# Fetch HTML report
echo "[*] Fetching HTML report..."
curl -s -X POST "$MOBSF_URL/api/v1/report_html" \
  -H "Authorization: $API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"hash\":\"$HASH\",\"scan_type\":\"$SCAN_TYPE\"}" \
  -o mobsf-report.html

# Extract critical/high scores safely
CRITICAL=$(jq '.security_score.critical // 0' mobsf-report.json)
HIGH=$(jq '.security_score.high // 0' mobsf-report.json)

echo "Critical: $CRITICAL | High: $HIGH"

if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
  echo "[!] Security gate failed"
  exit 1
fi

echo "[+] MobSF scan passed"
