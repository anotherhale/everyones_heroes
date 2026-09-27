# Everyone's Heroes AI proxy — Render / container image
# Build context: services/ai_proxy
FROM dart:stable AS build

WORKDIR /app

# Resolve dependencies first for better layer caching.
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o /app/bin/server

# Minimal runtime image (Dart AOT compile includes /runtime from the SDK image).
FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Render injects PORT; ProxyConfig also honors EH_AI_PROXY_PORT, then PORT, then 8787.
ENV EH_AI_PROXY_HOST=0.0.0.0

EXPOSE 10000
CMD ["/app/bin/server"]
