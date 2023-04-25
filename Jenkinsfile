pipeline {
  
  agent any  
  
  stages {
    stage('checkout') {
      steps {
        checkout scm
  	    }
    	}
    
 
    stage('terraform plan') {
      steps {
	    sh 'pwd'
	    sh 'terraform init'
        sh 'terraform --version'
		sh 'terraform plan '
      }
    }

    stage('eks-deploy') {
      steps {
        sh 'terraform apply  -input=false -auto-approve'
  	  	    timeout(time: 30, unit: 'MINUTES') {
                    
                } 
      }

    }

  }
  
  
}