FROM maven:3.9-eclipse-temurin-17

WORKDIR /app

COPY pom.xml .
COPY DatabaseCreator.java .

RUN mvn dependency:go-offline

RUN mkdir -p src/main/java

RUN mv DatabaseCreator.java src/main/java/DatabaseCreator.java

RUN mvn package

CMD ["java", "-cp", "target/classes:$HOME/.m2/repository/com/mysql/mysql-connector-j/9.4.0/mysql-connector-j-9.4.0.jar", "DatabaseCreator"]
