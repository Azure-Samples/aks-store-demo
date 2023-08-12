FROM mcr.microsoft.com/openjdk/jdk:17-mariner as build
WORKDIR /app
COPY .mvn .mvn
COPY mvnw .
COPY pom.xml .

RUN chmod +x mvnw
RUN ./mvnw dependency:go-offline -B

COPY src ./src
RUN ./mvnw package -DskipTests

FROM mcr.microsoft.com/openjdk/jdk:17-mariner
COPY --from=build /app/target/product-service-0.1.0.jar /app.jar

CMD ["java", "-jar", "/app.jar"]