# ==========================================
# STAGE 1: Build Frontend
# ==========================================

FROM node:lts-alpine AS frontend-builder

WORKDIR /src

RUN apk add --no-cache git ca-certificates \
    && npm install -g pnpm

RUN git clone --depth 1 https://github.com/go-vikunja/vikunja.git .

WORKDIR /src/frontend

RUN pnpm install

ENV VIKUNJA_FRONTEND_BASE=/vikunja/

RUN pnpm run build


# ==========================================
# STAGE 2: Build Backend
# ==========================================

FROM golang:alpine AS backend-builder

WORKDIR /src

RUN apk add --no-cache git gcc musl-dev

RUN go install github.com/magefile/mage@latest

ENV PATH="/go/bin:${PATH}"

COPY --from=frontend-builder /src /src

RUN mage build


# ==========================================
# STAGE 3: Runtime
# ==========================================

FROM alpine:latest

RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    mailcap

WORKDIR /app/vikunja

COPY --from=backend-builder /src/vikunja /app/vikunja/vikunja

RUN mkdir -p /app/vikunja/files \
    && chmod +x /app/vikunja/vikunja

EXPOSE 3456

CMD ["/app/vikunja/vikunja"]
