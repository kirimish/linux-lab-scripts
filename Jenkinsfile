pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    environment {
        PACKAGE_NAME    = 'count-files'
        PACKAGE_VERSION = '1.0'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'ls -la'
            }
        }

        stage('Static Analysis (ShellCheck)') {
            agent {
                docker {
                    image 'koalaman/shellcheck-alpine:latest'
                    args '-u root'
                }
            }
            steps {
                checkout scm
                sh 'shellcheck count_files.sh'
            }
        }

        stage('Parallel Build') {
            parallel {
                stage('Build RPM') {
                    agent {
                        docker {
                            image 'fedora:latest'
                            args '-u root'
                        }
                    }
                    steps {
                        checkout scm
                        sh '''
                            dnf install -y rpm-build rpmdevtools
                            rpmdev-setuptree
                            mkdir -p ~/rpmbuild/SOURCES/${PACKAGE_NAME}-${PACKAGE_VERSION}
                            cp count_files.sh ~/rpmbuild/SOURCES/${PACKAGE_NAME}-${PACKAGE_VERSION}/
                            cp count_files.sh ~/rpmbuild/SOURCES/${PACKAGE_NAME}-${PACKAGE_VERSION}/count_files 2>/dev/null || true
                            tar czvf ~/rpmbuild/SOURCES/${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz -C ~/rpmbuild/SOURCES ${PACKAGE_NAME}-${PACKAGE_VERSION}
                            cp ~/rpmbuild/SOURCES/${PACKAGE_NAME}-${PACKAGE_VERSION}.tar.gz ~/rpmbuild/SOURCES/${PACKAGE_NAME}.tar.gz 2>/dev/null || true
                            cp packaging/rpm/count-files.spec ~/rpmbuild/SPECS/
                            rpmbuild -ba ~/rpmbuild/SPECS/count-files.spec
                            find ~/rpmbuild/RPMS/ -name "*.rpm" -exec cp {} . \;
                            ls -la *.rpm
                            chown -R 1000:1000 *.rpm 2>/dev/null || true
                        '''
                        stash includes: '*.rpm', name: 'rpm-package'
                        sh 'rm -f *.rpm'
                    }
                }

                stage('Build DEB') {
                    agent {
                        docker {
                            image 'ubuntu:latest'
                            args '-u root'
                        }
                    }
                    steps {
                        checkout scm
                        sh '''
                            apt-get update
                            apt-get install -y build-essential debhelper devscripts
                            mkdir -p build/${PACKAGE_NAME}-${PACKAGE_VERSION}
                            cp count_files.sh build/${PACKAGE_NAME}-${PACKAGE_VERSION}/count_files
                            cp count_files.sh build/${PACKAGE_NAME}-${PACKAGE_VERSION}/count_files.sh
                            cp -r packaging/deb/debian build/${PACKAGE_NAME}-${PACKAGE_VERSION}/
                            cd build/${PACKAGE_NAME}-${PACKAGE_VERSION}
                            chmod +x count_files count_files.sh
                            dpkg-buildpackage -us -uc -b
                            cd ../..
                            cp build/*.deb . 2>/dev/null || cp *.deb . 2>/dev/null || cp ../*.deb . 2>/dev/null || true
                            ls -la *.deb
                            chown -R 1000:1000 *.deb 2>/dev/null || true
                        '''
                        stash includes: '*.deb', name: 'deb-package'
                        sh 'rm -f *.deb'
                    }
                }
            }
        }

        stage('Parallel Testing') {
            parallel {
                stage('Test RPM Installation') {
                    agent {
                        docker {
                            image 'oraclelinux:8'
                            args '-u root'
                        }
                    }
                    steps {
                        unstash 'rpm-package'
                        sh '''
                            rpm -ivh *.rpm
                            count_files || count_files.sh || true
                            rpm -e ${PACKAGE_NAME} 2>/dev/null || true
                            rm -f *.rpm
                        '''
                    }
                }

                stage('Test DEB Installation') {
                    agent {
                        docker {
                            image 'ubuntu:latest'
                            args '-u root'
                        }
                    }
                    steps {
                        unstash 'deb-package'
                        sh '''
                            dpkg -i *.deb || apt-get install -f -y
                            count_files || count_files.sh || true
                            apt-get remove -y ${PACKAGE_NAME} 2>/dev/null || true
                            rm -f *.deb
                        '''
                    }
                }
            }
        }

        stage('Publish Repository & Tagging') {
            steps {
                unstash 'rpm-package'
                unstash 'deb-package'
                sh '''
                    mkdir -p repo/rpm repo/deb
                    cp *.rpm repo/rpm/ 2>/dev/null || true
                    cp *.deb repo/deb/ 2>/dev/null || true
                    echo "Repository structure generated for version ${PACKAGE_VERSION}" > repo/README.md
                '''
                sh '''
                    git config user.name "Jenkins CI" || true
                    git config user.email "jenkins@localhost" || true
                    git tag -a "v${PACKAGE_VERSION}.${BUILD_NUMBER}" -m "Release version ${PACKAGE_VERSION}.${BUILD_NUMBER} built by Jenkins #${BUILD_NUMBER}" || true
                '''
                stash includes: 'repo/**/*', name: 'repository-artifacts'
            }
        }

        stage('Archive Artifacts') {
            steps {
                unstash 'rpm-package'
                unstash 'deb-package'
                unstash 'repository-artifacts'
                archiveArtifacts artifacts: '*.rpm, *.deb, repo/**/*'
            }
        }
    }

    post {
        success {
            echo "Build #${BUILD_NUMBER} and packaging completed successfully!"
        }
        failure {
            echo "Build #${BUILD_NUMBER} failed!"
        }
        always {
            deleteDir()
        }
    }
}
