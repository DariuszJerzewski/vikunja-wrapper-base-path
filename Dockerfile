# ==========================================
# STAGE 1: Build the Frontend with Custom Path
# ==========================================
FROM node:lts-alpine AS frontend-builder
WORKDIR /src

# Install git and pnpm
RUN apk add --no-cache git ca-certificates && npm install -g pnpm

# Pull the latest Vikunja source code
RUN git clone --depth 1 https://github.com/go-vikunja/vikunja.git .

# Move to frontend, install deps, and build with your custom path
WORKDIR /src/frontend
RUN pnpm install

# Use custom frontend base path
ENV VIKUNJA_FRONTEND_BASE=/vikunja/
RUN pnpm run build


# ==========================================
# STAGE 2: Build the Go Backend
# ==========================================
FROM golang:alpine AS backend-builder
WORKDIR /src

# Install Go build dependencies and Mage (Vikunja's build tool)
RUN apk add --no-cache git gcc musl-dev
RUN go install github.com/magefile/mage@latest
ENV PATH="/go/bin:${PATH}"

# Copy the entire source (which now includes your compiled frontend)
COPY --from=frontend-builder /src /src

# Compile the final binary
WORKDIR /src
RUN mage build


# ==========================================
# STAGE 3: Final Production Image
# ==========================================
FROM alpine:latest

# Install runtime requirements
RUN apk add --no-cache ca-certificates tzdata mailcap

WORKDIR /app
# Pull the finished binary from the previous stage
COPY --from=backend-builder /src/vikunja /app/vikunja

# Make it executable
RUN chmod +x /app/vikunja

# Vikunja runs on 3456 by default
EXPOSE 3456

CMD ["/app/vikunja"]

