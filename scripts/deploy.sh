#!/bin/bash

REPOSITORY=/home/ec2-user/app/step2
PROJECT_NAME=springbootgradledemo

echo "> Build 파일 복사"

cp $REPOSITORY/zip/*.jar $REPOSITORY/

echo "> 현재 구동중인 애플리케이션 pid 확인"

# pgrep : ps명령어와 grep명령어를 합쳐서 하나의 명령어로 사용해서 원하는 정보를 편하게 출력하는 명령어
# -fl : 명령어의 경로 출력, | 프로그램간 결과를 전송하는 명령어, 두 명령어를 복합해서 명령어를 사용하기 위해 사용
# ps : 작동중인 프로세스를 출력
# grep : 파일내용을 검색하여 해당하는 단어나 문자를 찾음
# awk : 입력파일($1 $2 $3)을 읽어 지정된 패턴과 일치하는 패턴을 매칭시켜 해당라인을 찾는 역할 + 패턴 일치시 연산도 수행
CURRENT_PID=$(pgrep -fl springbootgradledemo | grep jar | awk '{print $1}')

echo "현재 구동 중인 애플리케이션 pid: $CURRENT_PID"

# -z : 문자열의 길이가 0인 경우
if [ -z "$CURRENT_PID" ]; then
        echo "> 현재 구동  중인 애플리케이션이 없으므로 종료하지 않습니다."
else
        echo "> kill -15 $CURRENT_PID"
        kill -15 $CURRENT_PID
        sleep 5
fi

echo "> 새 애플리케이션 배포"

# -tr : 시간순 역순으로 출력
# tail : 끝부분을 보여준다.
# -숫자 : 처음(끝)부터 보여줄 줄 수를 지정한다.
JAR_NAME=$(ls -tr $REPOSITORY/*.jar | tail -n 1)

echo "> JAR Name: $JAR_NAME"

echo "> JAR_NAME 에 실행권한 추가"

chmod +x $JAR_NAME

echo "> $JAR_NAME 실행"

# 애플리케이션 실행자가 터미널을 종료해도 애플리케이션은 계속 구동될 수 있도록 nohup 명령어를 사용
# java -jar : 자바 실행 명령어
# -Dspring.config.location : 스프링 설정 파일 위치를 지정합니다.
# 기본 옵션들을 담고 있는 application.properties 와 OAuth 설정들을 담고 있는 application-oauth.properties 의 위치를 지정합니다.
# classpath 가 붙으면 jar 안에 있는 resources 디렉토리를 기준으로 경로가 생성됨
# application-oauth.properties 은 절대경로를 사용. 파일이 외부(ec2)에 있기 때문
# -Dspring.profiles.active=real : application-real.properties를 활성화. application-real.properties 의 spring.profiles.include=oauth.real-db 옵션 때문에 real-db 역시 함께 활성화 대상에 포함됩니다.
# & : 백그라운드에서 실행
# 표준입력, 표준출력, 표준에러에 해당하는 파일 디스크럽터는 각각 0,1,2
# 아래 명령은 실행파일을 백그라운드 모드로 실행을 하면서 로그아웃 후에도 프로세스가 죽지 않고 진행되도록 하는데,
# 실행파일에 의해 발생되는 출력(에러 메시지까지)을 화면에 보이지 않게끔 합니다.
# nohup 명령은 실행을 하면 nohup.out 이라는 이름의 파일이 생성됩니다.
# $JAR_NAME > $REPOSITORY/nohup.out 은 $JAR_NAME 의 결과를 $REPOSITORY/nohup.out 라는 파일속에 넣은다음 모든 출력을 삭제한다는 의미
# 2>&1 & : 2번 파일 디스크럽터를 1번에 지정된 형식과 동일하게 $REPOSITORY/nohup.out 로 지정하여 백그라운드에 실행
# 이 파일에는 nohup 으로 실행하는 명령의 출력이 기록이 되는데 아래 명령을 이용하면 로그를 남기지 않음
nohup java -jar \
        -Dspring.config.location=classpath:/application.properties,/home/ec2-user/app/application-oauth.properties,/home/ec2-user/app/application-real-db.properties,classpath:/application-real.properties \
        -Dspring.profiles.active=real \
        $JAR_NAME > $REPOSITORY/nohup.out 2>&1 &
