pipeline {
  
  agent any  
  
  stages {
    stage('checkout') {
      steps {
        checkout scm
  	    }
    	}
    
 
    stage('terraform eks iam role plan') {
      steps {
	    sh 'terraform init'
        sh 'terraform --version'
		sh 'terraform plan -target=module.eks_nodegroup_role'
      }
    }

    stage('eks-iam-role') {
      steps {
        sh 'terraform apply  -target=module.eks_nodegroup_role  -input=false -auto-approve' 
      }
    }	

    stage('terraform eks-deploy plan') {
      steps {
		sh 'terraform plan -target=module.eks_cluster_creation'
      }
    }
	
    stage('eks-deploy') {
      steps {
        sh 'terraform apply -target=module.eks_cluster_creation -input=false -auto-approve'
  	  	    timeout(time: 30, unit: 'MINUTES') {
                    
                } 
      }

    }

  }
  
  
}