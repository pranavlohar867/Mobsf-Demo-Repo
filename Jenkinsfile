pipeline {
  agent any

  environment {
    MOBSF_API_KEY = credentials('mobsf-api-key')
  }

  stages {
    stage('Mobile SAST - MobSF') {
      steps {
        sh 'chmod +x Security/mobsf_scan.sh'
        sh 'Security/mobsf_scan.sh'
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: 'mobsf-report.json', allowEmptyArchive: true
    }
  }
}
