FROM openjdk:8-jdk-alpine
EXPOSE 9091  # Changed from 8083 to 9091
ADD target/docker-spring-boot.war docker-spring-boot.war
ENTRYPOINT ["java","-jar","/docker-spring-boot.war"]
