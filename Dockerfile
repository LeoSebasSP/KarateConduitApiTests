FROM maven:3.9.16-eclipse-temurin-21-alpine

WORKDIR /usr/src/app

COPY pom.xml /usr/src/app
COPY ./src/test/java /usr/src/app/src/test/java
COPY ./src/test/resources /usr/src/app/src/test/resources

CMD ["mvn", "test", "-Dkarate.env=prod"]