# ========== Backend build ==========
FROM eclipse-temurin:21-jdk AS backend-build
WORKDIR /app

COPY backend/ .
RUN ./mvnw package -DskipTests -q

# ========== Frontend build ==========
FROM node:20-alpine AS frontend-build
WORKDIR /app

ARG NEXT_PUBLIC_BACKEND_URL
ENV NEXT_PUBLIC_BACKEND_URL=${NEXT_PUBLIC_BACKEND_URL}

COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

COPY frontend/ .
RUN npm run build

# ========== Runtime: one image, both processes ==========
FROM node:20-alpine AS runtime
RUN apk add --no-cache openjdk21-jre-headless

WORKDIR /app

# Backend JAR
COPY --from=backend-build /app/target/*.jar /app/backend.jar

# Frontend standalone (server.js and .next must live together)
COPY --from=frontend-build /app/.next/standalone /app/frontend/
COPY --from=frontend-build /app/public /app/frontend/public
COPY --from=frontend-build /app/.next/static /app/frontend/.next/static

# Entrypoint: start backend in background, run frontend as PID 1
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN sed -i 's/\r$//' /app/docker-entrypoint.sh && chmod +x /app/docker-entrypoint.sh

EXPOSE 8080 3000
ENTRYPOINT ["/app/docker-entrypoint.sh"]
