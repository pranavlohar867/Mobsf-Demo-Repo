pipeline {
  agent any

  environment {
    MOBSF_API_KEY = credentials('mobsf-api-key')
  }

  stages {
    stage('Mobile SAST - MobSF') {
  steps {
    sh 'pwd'                     // Prints current directory path
    sh 'ls -l'                   // Lists files in workspace root
    sh 'ls -l Security'          // List files inside Security folder (adjust if lowercase)
    sh 'cat Security/mobsf_scan.sh'  // Show the script content
    sh 'chmod +x Security/mobsf_scan.sh'
    sh 'sh 'sh ./Security/mobsf_scan.sh''
  }
}
  }

  post {
    always {
      archiveArtifacts artifacts: 'mobsf-report.json', allowEmptyArchive: true
    }
  }
}
