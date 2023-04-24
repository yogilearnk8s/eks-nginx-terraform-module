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

    stage('eks-iam-role') {
      steps {
        sh 'terraform apply  -target=module.eks_nodegroup_role  -input=false -auto-approve'
  
      }

    }	
    stage('eks-deploy') {
      steps {
        sh 'terraform apply -input=false -auto-approve'
  	  	    timeout(time: 30, unit: 'MINUTES') {
                    
                } 
      }

    }

  }
  
  
}