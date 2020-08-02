def k8slabel = "jenkins-pipeline-${UUID.randomUUID().toString()}"
def slavePodTemplate = """
      metadata:
        labels:
          k8s-label: ${k8slabel}
        annotations:
          jenkinsjoblabel: ${env.JOB_NAME}-${env.BUILD_NUMBER}
      spec:
        affinity:
          podAntiAffinity:
            requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                - key: component
                  operator: In
                  values:
                  - jenkins-jenkins-master
              topologyKey: "kubernetes.io/hostname"
        containers:
        - name: buildtools
          image: fuchicorp/buildtools
          imagePullPolicy: IfNotPresent
          command:
          - cat
          tty: true
          volumeMounts:
            - mountPath: /var/run/docker.sock
              name: docker-sock
        - name: docker
          image: docker:latest
          imagePullPolicy: IfNotPresent
          command:
          - cat
          tty: true
          volumeMounts:
            - mountPath: /var/run/docker.sock
              name: docker-sock
         - name: helm
          image: fluxcd/helm-operator:1.2.0
          imagePullPolicy: IfNotPresent
          command:
          - cat
          tty: true
          volumeMounts:
            - mountPath: /var/run/docker.sock
              name: docker-sock     
        serviceAccountName: common-jenkins
        securityContext:
          runAsUser: 0
          fsGroup: 0
        volumes:
          - name: docker-sock
            hostPath:
              path: /var/run/docker.sock
    """
    properties([
        parameters([
            booleanParam(defaultValue: false, description: 'Please select to apply the changes ', name: 'terraformApply'),
            booleanParam(defaultValue: false, description: 'Please select to destroy all ', name: 'terraformDestroy'),
            choice(choices: ['dev', 'qa', 'stage', 'prod'], description: 'Please select the environment to deploy.', name: 'environment')
        ])
    ])
    podTemplate(name: k8slabel, label: k8slabel, yaml: slavePodTemplate, showRawYaml: false) {
      node(k8slabel) {
        stage("Pull SCM") {
            git 'https://github.com/beckkari8/hw3.git'
        }
        stage("Generate Variables") {
          dir('deployments/terraform') {
            println("Generate Variables")
            def deployment_configuration_tfvars = """
            environment = "${environment}"
            """.stripIndent()
            writeFile file: 'deployment_configuration.tfvars', text: "${deployment_configuration_tfvars}"
            sh 'cat deployment_configuration.tfvars >> dev.tfvars'
          }   
        }
        container("buildtools") {
            dir('deployments/terraform') {
                withCredentials([usernamePassword(credentialsId: "aws-access-${environment}", 
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    println("Selected cred is: aws-access-${environment}")
                    sh 'sh /scripts/Dockerfile/set-config.sh'
                    stage("Copying JOBS and Existing CREDENTIALS to /tmp folder"){
                      sh """
                      #!/bin/bash
                      export JENKINS_POD_NAME=\$(kubectl get pod | grep jenkins | awk '{print \$1}' | head -n1)
                      kubectl cp \$JENKINS_POD_NAME:/var/jenkins_home/jobs /tmp/jobs
                      kubectl cp \$JENKINS_POD_NAME:/var/jenkins_home/credentials.xml /tmp/credentials.xml
                      """
                    }

                    stage("Terraform Apply/plan") {
                        if (!params.terraformDestroy) {
                            if (params.terraformApply) {
                                println("Applying the changes")
                                sh """
                                #!/bin/bash
                                source ./setenv.sh dev.tfvars
                                terraform apply -auto-approve -var-file \$DATAFILE
                                """
                            } else {
                                println("Planing the changes")
                                sh """
                                #!/bin/bash
                                set +ex
                                ls -l
                                source ./setenv.sh dev.tfvars
                                terraform plan -var-file \$DATAFILE
                                """
                            }
                        }
                    }
                    stage("Terraform Destroy") {
                        if (params.terraformDestroy) {
                            println("Destroying the all")
                            sh """
                            #!/bin/bash
                            source ./setenv.sh dev.tfvars
                            terraform destroy -auto-approve -var-file \$DATAFILE
                            """
                        } else {
                            println("Skiping the destroy")
                        }
                    }
                    stage("Attaching the PVC to the exixtingClaim"){
                      container("helm") {
                      sh """
                      #!/bin/bash
                      helm upgrade jenkins --set persistence.existingClaim=pvc stable/jenkins
                      """
                    }
                    }
                  
                     stage("Copying JOBS and Existing CREDENTIALS to JENKINS_POD_NAME:/var/jenkins_home "){
                      sh """
                      #!/bin/bash
                      export JENKINS_POD_NAME=\$(kubectl get pod | grep jenkins | awk '{print \$1}' | head -n1)
                      kubectl cp /tmp/credentials.xml \$JENKINS_POD_NAME:/var/jenkins_home
                      kubectl cp /tmp/jobs \$JENKINS_POD_NAME:/var/jenkins_home
                      """
                    }
                }
           }
         }
        }
    }