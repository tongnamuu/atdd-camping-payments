###########
# Builder #
###########
FROM eclipse-temurin:17-jdk AS builder
WORKDIR /workspace

COPY . .
RUN chmod +x ./gradlew \
    && ./gradlew --no-daemon clean bootJar -x test

############
# Runtime  #
############
FROM eclipse-temurin:17-jre
WORKDIR /app

COPY --from=builder /workspace/build/libs/*.jar /app/app.jar

EXPOSE 9090

ENTRYPOINT ["java", "-jar", "/app/app.jar"]