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
      sh 'terraform state list'
      sh 'terraform state rm module.eks.kubernetes_config_map.aws_auth'
//		sh 'export TF_LOG="DEBUG"'
	//	sh 'export TF_LOG_PATH="/home/ubuntu/terraform-log.log"'
	//    sh 'terraform init'
   //     sh 'terraform --version'
//		sh 'terraform plan '
      }
    }

  //  stage('eks-deploy') {
    //  steps {
      //  sh 'terraform apply  -input=false -auto-approve'
  	  	//    timeout(time: 30, unit: 'MINUTES') {
                    
          //      } 
     // }

   // }

  }
  
  
}