# Development

How to run Everyone’s Heroes on a physical iPhone against the local AI proxy.

The proxy keeps the OpenAI key on the Mac. The phone only receives a compile-time base URL and a dev bearer token.

## What the phone must be given

| Piece | Where it is set | Example |
| --- | --- | --- |
| Proxy URL | Flutter `--dart-define=EH_AI_PROXY_URL=...` | `http://192.168.1.42:8787` |
| Dev token | Same string on the proxy and the app | `dev-token` |

The dev token is `EH_AI_PROXY_AUTH_TOKEN` on both sides.

- Proxy process: `export EH_AI_PROXY_AUTH_TOKEN=dev-token`
- iPhone build: `--dart-define=EH_AI_PROXY_AUTH_TOKEN=dev-token`

The app sends it as `Authorization: Bearer <token>`. The proxy compares that value to its own `EH_AI_PROXY_AUTH_TOKEN`. `GET /health` stays open so you can check reachability before the token is involved.

Both defines are compile-time (`String.fromEnvironment`). Changing the URL or the token requires a new `flutter run`. Hot reload keeps the previous values.

When `EH_AI_PROXY_URL` is set, transcription, Story Builder coach, Story Understanding, Story Authoring, captured-story reading, experience plans, voice rendering, creative direction, and music generation use the proxy. Optional mode defines (`EH_TRANSCRIPTION_MODE=proxy`, and the matching `EH_STORY_*_MODE` defines) force proxy mode explicitly. `development` forces the in-memory adapter for that feature even when a URL is set.

## Why the URL is the Mac’s LAN address

The iPhone is a separate machine. `http://localhost:8787` and `http://127.0.0.1:8787` point at the phone itself, so the proxy on the Mac is never reached.

Use the Mac’s Wi-Fi address, for example `http://192.168.1.42:8787`.

`ios/Runner/Info.plist` allows that cleartext local address:

- `NSAllowsLocalNetworking` permits HTTP to an IP address or a `.local` name. Public hostnames still require HTTPS.
- `NSLocalNetworkUsageDescription` lets iOS show the Local Network permission prompt the first time the app calls the proxy.

Plug the phone in for install if you want. The app still talks to the proxy over Wi-Fi, so the Mac and the iPhone stay on the same network. Guest Wi-Fi and client isolation block this path.

## 1. Start the proxy so the phone can reach it

The proxy listens on `0.0.0.0` by default (`EH_AI_PROXY_HOST`). That is required. Binding only to `127.0.0.1` hides the server from the phone.

```bash
cd services/ai_proxy
dart pub get
export OPENAI_API_KEY=sk-...
export EH_AI_PROXY_HOST=0.0.0.0
export EH_AI_PROXY_PORT=8787
export EH_AI_PROXY_AUTH_TOKEN=dev-token
dart run bin/server.dart
```

Pick any dev token you want. Use that exact string in the Flutter command below. If the proxy token is unset, the server accepts calls with no `Authorization` header. If the proxy token is set and the app token differs, those calls return HTTP 401.

Find the address the phone should use:

```bash
ipconfig getifaddr en0 || ipconfig getifaddr en1
```

Confirm the Mac answers on that address. `/health` does not require the token:

```bash
curl -s "http://192.168.1.42:8787/health"
```

A body of `ok` means the phone’s network can use the same URL. Confirm the token next. A `400` means the bearer was accepted and the empty body was rejected. A `401` means the token does not match `EH_AI_PROXY_AUTH_TOKEN`.

```bash
curl -s -o /dev/null -w "%{http_code}\n" \
  -H "Authorization: Bearer dev-token" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "http://192.168.1.42:8787/story-transcriptions"
```

If `curl` to the LAN address hangs, allow incoming connections for the `dart` process in System Settings → Network → Firewall.

## 2. Build and run on the iPhone

Prerequisites on the Mac: Xcode, Flutter, and an Apple Development certificate. The project uses automatic signing, team `63DCFBMR9Q`, and bundle id `com.example.everyonesheroes`. If that team is not yours, open `ios/Runner.xcworkspace` and select your team once.

On the iPhone: unlock it, trust the computer, and turn on Developer Mode (Settings → Privacy & Security → Developer Mode) on iOS 16 and later.

```bash
flutter devices
flutter run -d <ios-device-id> \
  --dart-define=EH_AI_PROXY_URL=http://192.168.1.42:8787 \
  --dart-define=EH_AI_PROXY_AUTH_TOKEN=dev-token
```

Replace `192.168.1.42` with the address from `ipconfig`, and `dev-token` with the same value exported on the proxy. Quote the defines if the token contains shell characters.

The first proxy call asks for Local Network access. Allow it. If the prompt does not appear, enable Everyone’s Heroes under Settings → Privacy & Security → Local Network, then run the app again.

When the Mac’s DHCP address changes, update `EH_AI_PROXY_URL` and run `flutter run` again.

## EH Platform dev token

The platform server uses a separate dev token. It does not authenticate the AI proxy.

```bash
# services/eh_platform
export EH_DEV_AUTH_TOKEN=dev-platform-token
```

Pass that same value to the app as `EH_PLATFORM_AUTH_TOKEN`, and point `EH_PLATFORM_URL` at the Mac’s LAN address the same way as the proxy (default platform port `8080`):

```bash
flutter run -d <ios-device-id> \
  --dart-define=EH_AI_PROXY_URL=http://192.168.1.42:8787 \
  --dart-define=EH_AI_PROXY_AUTH_TOKEN=dev-token \
  --dart-define=EH_PLATFORM_URL=http://192.168.1.42:8080 \
  --dart-define=EH_H2_MODE=platform \
  --dart-define=EH_PLATFORM_AUTH_TOKEN=dev-platform-token
```
