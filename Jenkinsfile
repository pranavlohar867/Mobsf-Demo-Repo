pipeline {
    agent any

    environment {
        MOBSF_API_KEY = credentials('mobsf-api-key') // Replace with your Jenkins credential ID
        MOBSF_URL = 'http://host.docker.internal:8000' // Adjust if needed
        APK_PATH = 'app/DivaApplication.apk'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Mobile SAST - MobSF') {
            steps {
                script {
                    // Ensure mobsf_scan.sh is executable and has correct line endings
                    sh 'chmod +x Security/mobsf_scan.sh'
                    sh 'dos2unix Security/mobsf_scan.sh || true'

                    // Run the scan with debugging
                    sh '''
                        #!/bin/bash
                        set -e

                        echo "[*] Checking APK..."
                        if [ ! -f "$APK_PATH" ]; then
                            echo "[!] APK not found at $APK_PATH"
                            exit 1
                        fi

                        echo "[*] Uploading APK to MobSF..."
                        UPLOAD=$(curl -s -X POST "$MOBSF_URL/api/v1/upload" \
                            -H "Authorization: $MOBSF_API_KEY" \
                            -F "file=@$APK_PATH")

                        echo "[DEBUG] Upload response: $UPLOAD"

                        HASH=$(echo $UPLOAD | jq -r '.hash')
                        SCAN_TYPE="apk"

                        if [ "$HASH" == "null" ] || [ -z "$HASH" ]; then
                            echo "[!] Upload failed. Check MobSF URL, API key, or APK."
                            exit 1
                        fi

                        echo "[*] Starting scan..."
                        curl -s -X POST "$MOBSF_URL/api/v1/scan" \
                            -H "Authorization: $MOBSF_API_KEY" \
                            -H "Content-Type: application/json" \
                            -d "{\"hash\":\"$HASH\",\"scan_type\":\"$SCAN_TYPE\"}" > /dev/null

                        echo "[*] Fetching JSON report..."
                        curl -s -X POST "$MOBSF_URL/api/v1/report_json" \
                            -H "Authorization: $MOBSF_API_KEY" \
                            -H "Content-Type: application/json" \
                            -d "{\"hash\":\"$HASH\",\"scan_type\":\"$SCAN_TYPE\"}" > mobsf-report.json

                        echo "[*] Fetching HTML report..."
                        curl -s -X POST "$MOBSF_URL/api/v1/report_html" \
                            -H "Authorization: $MOBSF_API_KEY" \
                            -H "Content-Type: application/json" \
                            -d "{\"hash\":\"$HASH\",\"scan_type\":\"$SCAN_TYPE\"}" > mobsf-report.html

                        CRITICAL=$(jq '.security_score.critical // 0' mobsf-report.json)
                        HIGH=$(jq '.security_score.high // 0' mobsf-report.json)

                        echo "Critical: $CRITICAL | High: $HIGH"

                        if [ "$CRITICAL" -gt 0 ] || [ "$HIGH" -gt 0 ]; then
                            echo "[!] Security gate failed"
                            exit 1
                        fi

                        echo "[+] MobSF scan passed"
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'mobsf-report.*', fingerprint: true
        }
    }
}
