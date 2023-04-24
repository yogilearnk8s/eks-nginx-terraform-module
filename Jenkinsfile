pipeline {
  
  agent any  
  
  stages {
    stage('checkout') {
      steps {
        checkout scm
  	    }
    	}
    
 
    stage('terraform version') {
      steps {
	    sh 'terraform init'
        sh 'terraform --version'
		sh 'terraform plan'
      }
    }
	
    stage('k8s-infra-deploy') {
      steps {
        sh 'terraform apply -input=false -auto-approve'
  	  	    timeout(time: 30, unit: 'MINUTES') {
                    
                } 
      }

    }

  }
  
  
}