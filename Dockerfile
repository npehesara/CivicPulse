# ==========================================
# Stage 1: Build the Application
# ==========================================
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /app

# Copy Maven wrapper and POM first to leverage Docker layer caching for dependencies
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./

# Normalize line endings (in case checked out on Windows) and make wrapper executable
RUN chmod +x ./mvnw && sed -i 's/\r$//' ./mvnw

# Download dependencies offline (cached unless pom.xml changes)
RUN ./mvnw dependency:go-offline -B

# Copy the application source code
COPY src/ src/

# Build the Spring Boot executable JAR skipping test execution
RUN ./mvnw clean package -DskipTests -B

# ==========================================
# Stage 2: Runtime Image
# ==========================================
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Create a non-privileged user for security
RUN addgroup --system spring && adduser --system --ingroup spring spring
USER spring:spring

# Copy the built JAR from the builder stage
COPY --from=build /app/target/*.jar app.jar

# Render assigns a dynamic port via the PORT environment variable (default fallback is 8080)
ENV PORT=8080
EXPOSE 8080

# Run the Spring Boot application, binding to Render's dynamic PORT
ENTRYPOINT ["sh", "-c", "java -jar app.jar --server.port=${PORT:-8080}"]
