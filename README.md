# 스프링부트 프로젝트의 CI/CD 환경 구축
> AWS EC2 인스턴스에 Jenkins, AWS S3, CodeDeploy를 이용하여 CI/CD 환경 구축

## 주요내용
+ 실제 서비스 시에 새로운 코드의 변경사항이 정기적으로 빌드 및 테스트되어 공유 레포지토리에 통합되고 지속적인 배포가 되야 하기 때문에 CI/CD 환경구축
+ Jenkins , AWS S3, AWS CodeDeploy 생성과 Spring Boot와의 연동으로 배포 자동화 구성

![full](https://user-images.githubusercontent.com/37195463/135084243-93a66d6d-bad0-4f8b-b8ee-1e961a46fc76.png)


## CI/CD 란?
+ CI (Continuous Integration - 지속적 통합) : 코드 버전 관리를 하는 VCS 시스템(Git,SVN 등)에 PUSH가 되면 자동으로 테스트와 빌드가 수행되어 안정적인 배포 파일을 만드는 과정  
+ CD (Continuous Deployment - 지속적인 배포) : 빌드 결과를 자동으로 운영 서버에 무중단 배포되는 과정  

## 전체과정
```
1. Docker 설치
2. Jenkins 설치
3. AWS S3 버킷 생성
4. AWS CodeDeploy 생성
5. AWS EC2 인스턴스 생성 (배포용)
6. IAM 역할/사용자 생성
7. Jenkins 작업설정
8. 프로젝트내부에 deploy.sh , appspce.yml 생성
9. Github에 프로젝트 PUSH
```
### Prerequisites / 선행 조건

+ 아래 사항들이 설치가 되어있어야 한다.

```
Run 가능한 스프링부트 
```

# Installing / 설치
## 1. 도커(Docker)  
+ 컨테이너 기반의 오픈소스 가상화 플랫폼  

### 도커에서 의미하는 컨테이너  
+ 프로그램(소프트웨어)을 담는 격리된 공간을 의미. 각 컨테이너는 격리된 공간이기 한 컨테이너에 문제가 생기더라도 컨테이너 간에 영향을 끼치지 않는다.  

### 도커의 장점  
+ 빠르고 가벼운 가상화 솔루션 - 호스트의 운영체제를 공유하여 필요한 최소한의 리소스만 할당 받아 동작  
+ 개발언어에 종속되지 않는다.  
+ 뛰어난 보안성  

### 도커 설치 (로컬환경)
+ Windows10 도커설치 (<https://hub.docker.com/editions/community/docker-ce-desktop-windows/>)

![docker_install01](https://user-images.githubusercontent.com/37195463/135085906-5cd43d54-e164-4e01-bfbe-8b54cacd1d94.png)

+ CMD 에서 "docker -v" 로 도커가 설치되었는지 확인.  

![docker_install](https://user-images.githubusercontent.com/37195463/135085940-f576dfed-247c-4978-a257-09d7659c0b9d.png)

## 2. Jenkins 설치
+ root 권한으로 진행 : root가 아닌 현재유저를 도커그룹에 추가

 
> 현재 유저 확인
```
Echo $USER
```

> 현재 유저 출력결과
```
ec2-user
```

> docker 그룹에 현재 유저 추가
```
sudo usermod -aG docker $USER 
```

> docker 재실행 
```
sudo service docker restart 
```

> 그래도 적용이 안된경우 접속해제 후 재연결 
```
exit
```

> 젠킨스 이미지 받기
```
sudo docker pull jenkins/jenkins:lts
```

> docker jenkins image 확인
```
docker images
```

> docker image를 컨테이너로 등록 후 실행
```
docker run -d -p 32789:8080 -v /jenkins:/var/jenkins_home --name jenkins -u root jenkins/jenkins:lts
  
-d detached mode 흔히 말하는 백그라운드 모드
-p 호스트(앞)와 컨테이너(뒤)의 포트를 연결 (포트포워딩) 로컬 PORT: 컨테이너 PORT
-v 호스트(앞)와 컨테이너(뒤)의 디렉토리를 연결 (마운트)
-u 실행할 사용자 지정
–-name 컨테이너 이름 설정
```
> Jenkins [host ip:port]로 접속
```
http://localhost:32789/
```

> Administrator password 입력

![jenkins pw](https://user-images.githubusercontent.com/37195463/135086092-cb58b74e-576b-42a1-a326-6f6ee6946898.png)

> docker의 jenkins 컨테이너로 접속하여 패스워드 파일 읽기
```
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

>도커 컨테이너 내부로 접속

    docker ps -a
    docker exec -it 도커컨테이너ID /bin/bash    
    
    ex) docker exec -it 6832359260fd /bin/bash

> 설치완료

![jenkins main2](https://user-images.githubusercontent.com/37195463/135086640-596d0806-b805-495c-bfc4-9d63bea4d110.png)

## 3. AWS S3 버킷 생성  
* (액세스 키 ID, 비밀 액세스 키) 기억

## 4. AWS EC2 생성  

## 5. AWS CodeDeploy 생성 (배포그룹생성, EC2태그, 배포구성)  
+ CodeDeploy agent 설치

> EC2에 접속해서 다음 명령어를 입력
```
aws s3 cp 53://aws-codedeploy-ap-northeast-2/latest/install . --region ap-northeast-2
```

> 내려받기가 성공했다면 다음과 같은 메시지가 콘솔에 출력
```
download: 53://aws-codedeploy-ap-northeast-2/latest/install to ./install
```

> install 파일에 실행 권한이 없으니 실행 권한을 추가
```
chmod +X/install
```

> install 파일로 설치를 진행
```
sudo ./install auto
```

> 설치가 끝났으면 Agent가 정상적으로 실행되고 있는지 상태 검사
```
sudo service codedeploy-agent status
```

> 다음과 같이 running 메시지가 출력되면 정상
```
The AWS CodeDeploy agent is running as PID XXX
```
 
> 만약 설치 중에 다음과 같은 에러가 발생한다면 Ruby라는 언어가 설치 안 된 상태이기 때문

    /usr/bin/env: ruby: No such file or directory
    
> 이럴 경우 yum install 로 루비를 설치

    sudo yum install ruby
 

## 6. IAM 역할/사용자 생성
- IAM 역할 - CodeDeploy, EC2  
- IAM 사용자 - Jenkins

## 7. Jenkins 작업설정
> 플러그인 설치
```
• AWS CodeDeploy Plugin for Jenkins  
• GitHub Integration Plugin  
• Gradle Plugin
```
> 플러그인 관리

![jenkins plugin](https://user-images.githubusercontent.com/37195463/135086204-b76572ff-ebad-49b1-a4b4-ca4af7faa9e9.png)

> 새 작업 생성  

![jenkins main](https://user-images.githubusercontent.com/37195463/135087292-c6d1a308-7ca5-4e4d-b454-28996a9d4798.png)

> 프로젝트 이름 입력 후 확인

![jenkins build deploy](https://user-images.githubusercontent.com/37195463/135087284-9e2db8f3-1906-48f4-ad56-883919e2db40.png)

> GitHub project 선택  
> Project url 입력 (https//github.com/ureeze/(Repository 이름) )

![create project 1](https://user-images.githubusercontent.com/37195463/135087317-16511f05-e196-4080-9d1b-aa809f1fff30.png)

> 소스 코드 관리 : Git 선택  
> Repository URL 입력 (https//github.com/ureeze/(Repository 이름).git 

![create project 2](https://user-images.githubusercontent.com/37195463/135087325-37ece8dd-a1e5-40f3-8ca6-62535f5ea7f7.png)

> 빌드 유발 : GitHub hook trigger for GITScm polling 선택

![create project 3](https://user-images.githubusercontent.com/37195463/135087332-31268962-d778-44ed-a694-078c376e585f.png)

> Build  
>> Execute shell/Command  
```
chmod +x gradlew  
./gradlew clean build
```

>> Execute shell/Command  
>>> mkdir -p before-deploy  
```
cp scripts/*.sh before-deploy/  
cp appspec.yml before-deploy/  
cp build/libs/*.jar before-deploy/  
pwd
```

![create project 4](https://user-images.githubusercontent.com/37195463/135087338-74f9f184-1ce9-4362-84e5-42950eeced0a.png)

> 빌드 후 조치 입력

![create project 5](https://user-images.githubusercontent.com/37195463/135087344-76250f1a-6910-4899-8adf-289ff38842b6.png)
 
+ (S3 액세스 키 ID, 비밀 액세스 키 입력)  

![create project 6](https://user-images.githubusercontent.com/37195463/135087269-1de84eed-c242-4ee1-961f-97d0c9bd69dd.png)

+ Github에 Webhook설정  

![webhook](https://user-images.githubusercontent.com/37195463/135087549-365aba8a-af1b-4112-a37c-f6f6ae46c456.png)

> 추가로 하나의 job을 더 생성하고, 위에서 생성한 job이 수행된 후 연속적으로 실행되도록 만든다.  
> 이 job은 앞서 생성한 before-deploy directory를 remove하는 작업을 수행  
> 만약 remove 하지 않으면, 계속해서 build 후의 파일들이 deploy directory에 쌓이게 되어 이전 version의 file들이 s3 bucket으로 함께 upload 되는 문제가 발생

+ 앞서 생성한 before-deploy directory를 remove하기 위한 새 작업 생성  

![jenkins deploydir remove](https://user-images.githubusercontent.com/37195463/135087648-299dd52e-5cb9-45d6-99ab-d11e55dac432.png)
![jenkins remove1](https://user-images.githubusercontent.com/37195463/135087644-fe9e0ce5-aaaf-4090-80b7-0de155a89d63.png)

+ jenkins-build-deploy에 추가 적용  
  
![jenkins remove2](https://user-images.githubusercontent.com/37195463/135087836-5a101d48-c85a-4ad4-a58b-da31ff002564.png)

## 8. 프로젝트내부에 deploy.sh , appspce.yml 생성
> scripts/docker.sh
```
#!/bin/bash

REPOSITORY=/home/ec2-user/app/step2
PROJECT_NAME=springbootgradledemo

echo "> Build 파일 복사"

cp $REPOSITORY/zip/*.jar $REPOSITORY/

echo "> 현재 구동중인 애플리케이션 pid 확인"

CURRENT_PID=$(pgrep -fl springbootgradledemo | grep jar | awk '{print $1}')

echo "현재 구동 중인 애플리케이션 pid: $CURRENT_PID"

if [ -z "$CURRENT_PID" ]; then
        echo "> 현재 구동  중인 애플리케이션이 없으므로 종료하지 않습니다."
else
        echo "> kill -15 $CURRENT_PID"
        kill -15 $CURRENT_PID
        sleep 5
fi

echo "> 새 애플리케이션 배포"

JAR_NAME=$(ls -tr $REPOSITORY/*.jar | tail -n 1)

echo "> JAR Name: $JAR_NAME"

echo "> JAR_NAME 에 실행권한 추가"

chmod +x $JAR_NAME

echo "> $JAR_NAME 실행"

nohup java -jar \
        -Dspring.config.location=classpath:/application.properties,/home/ec2-user/app/application-oauth.properties,/home/ec2-user/app/application-real-db.properties,classpath:/application-real.properties \
        -Dspring.profiles.active=real \
        $JAR_NAME > $REPOSITORY/nohup.out 2>&1 &

```

> appspec.yml
```
version: 0.0  # codeDeploy의 버전, 프로젝트 버전이 아니므로 0.0 외에 다른 버전을 사용하면 오류발생
os: linux
files:     # s3에 업로드 된 파일이 ec2의 어느곳으로 이동시킬지 지정
  - source: /    # s3의 루트 디렉토리를 나타냄. 루트경로(/)는 s3에서 받은 모든파일 의미, destination으로 이동시킬 대상을 지정
    destination: /home/ec2-user/app/step2/zip/   # ec2 디렉토리. source에서 ec2로 지정된 파일을 받을 위치
    overwrite: yes  # 기존에 파일들이 있으면 덮어쓸지

permissions:    # codeDeploy에서 ec2서버로 넘겨준 파일들을 모두 ec2-user권한을 갖도록 함
  - object: /
    pattern: "**"
    owner: ec2-user
    group: ec2-user

hooks:      # CodeDeploy 배포 단계에서 실행할 명령어를 지정합니다.
  ApplicationStart:     # ApplicationStart라는 단계에서 deploy.sh를 ec2-user 권한으로 실행하게 합니다.
    - location: deploy.sh
      timeout: 60       # 60으로 스크립트 실행 60초 이상 수행되면 실패가 됩니다(무한정 기다릴 수 없으니 시간 제한을 둬야만 합니다).
      runas: ec2-user
```
## 9. Github에 프로젝트 PUSH

> Github에 프로젝트 push 후, jenkins로 webhook이 동작되고  
> 신호를 받은 jenkins는 build 후 s3로 (.jar, appspec.yml, deploy.sh) 이 압축된 zip파일을 업로드  
> 그 후 CodeDloy는 jenkins의 신호를 받아 s3의 파일을 ec2에 배포

+ build 후 jenkins 결과 

![jenkins build](https://user-images.githubusercontent.com/37195463/135087914-5847cbb8-25de-4d98-b1fb-9bc13c64bb3c.png)

+ s3에 file 업로드 됨

![s3 file](https://user-images.githubusercontent.com/37195463/135087916-b100f512-35c8-4d53-90eb-a10e75286c7a.png)

+ codeDeploy 배포 상태

![codedeploy status](https://user-images.githubusercontent.com/37195463/135087911-cdb11828-ce82-4058-ba26-6346233ee141.png)

## [참고자료]
<https://goddaehee.tistory.com/252?category=399168>  
<https://jojoldu.tistory.com/441>  
<https://dbjh.tistory.com/71?category=739428>  
참고서적 : 스프링 부트와 AWS로 혼자 구현하는 웹 서비스  
![book](https://user-images.githubusercontent.com/37195463/115071457-3ec14700-9f31-11eb-910a-d9ad9261e76f.png)
