#!/usr/bin/env bash
# Collect / compare host readiness stats for running the Flutter test suite.
#
# Use this on Mac mini and Linux PED to decide where to run the latest full suite.
#
# Examples:
#   ./scripts/test_host_stats.sh
#   ./scripts/test_host_stats.sh --host mac-mini
#   ./scripts/test_host_stats.sh --host linux-ped
#   ./scripts/test_host_stats.sh --compare
#   ./scripts/test_host_stats.sh --recommend
#   ./scripts/test_host_stats.sh --record-run --duration-sec 512 --passed 1258 --failed 0
#
# Snapshots land in .local/test-host-stats/ (gitignored).
# Override host label with --host or EH_TEST_HOST=mac-mini|linux-ped.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

STATS_DIR="${EH_TEST_HOST_STATS_DIR:-$ROOT_DIR/.local/test-host-stats}"
HOST_OVERRIDE="${EH_TEST_HOST:-}"
MODE="collect"
DURATION_SEC=""
PASSED=""
FAILED=""
JSON_ONLY=0

usage() {
  cat <<'EOF'
Collect / compare host readiness stats for running the Flutter test suite.

Use this on Mac mini and Linux PED to decide where to run the latest full suite.

Examples:
  ./scripts/test_host_stats.sh
  ./scripts/test_host_stats.sh --host mac-mini
  ./scripts/test_host_stats.sh --host linux-ped
  ./scripts/test_host_stats.sh --compare
  ./scripts/test_host_stats.sh --recommend
  ./scripts/test_host_stats.sh --record-run --duration-sec 512 --passed 1258 --failed 0

Snapshots land in .local/test-host-stats/ (gitignored).
Override host label with --host or EH_TEST_HOST=mac-mini|linux-ped.
EOF
  exit 0
}

die() {
  echo "error: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage ;;
    --host)
      [[ $# -ge 2 ]] || die "--host requires a value"
      HOST_OVERRIDE="$2"
      shift 2
      ;;
    --compare) MODE="compare"; shift ;;
    --recommend) MODE="recommend"; shift ;;
    --record-run) MODE="record-run"; shift ;;
    --duration-sec)
      [[ $# -ge 2 ]] || die "--duration-sec requires a value"
      DURATION_SEC="$2"
      shift 2
      ;;
    --passed)
      [[ $# -ge 2 ]] || die "--passed requires a value"
      PASSED="$2"
      shift 2
      ;;
    --failed)
      [[ $# -ge 2 ]] || die "--failed requires a value"
      FAILED="$2"
      shift 2
      ;;
    --json) JSON_ONLY=1; shift ;;
    *) die "unknown argument: $1" ;;
  esac
done

mkdir -p "$STATS_DIR"

os_family() {
  local uname_s
  uname_s="$(uname -s)"
  case "$uname_s" in
    Darwin) echo darwin ;;
    Linux) echo linux ;;
    *) echo "$uname_s" | tr '[:upper:]' '[:lower:]' ;;
  esac
}

normalize_host_id() {
  local raw="${1:-}"
  raw="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | tr ' _' '--')"
  case "$raw" in
    mac|macmini|mac-mini|mac_mini|m1|m2|apple-silicon) echo mac-mini ;;
    ped|linuxped|linux-ped|linux_ped|linux) echo linux-ped ;;
    "") echo "" ;;
    *) echo "$raw" ;;
  esac
}

detect_host_id() {
  local override hostname_l family
  override="$(normalize_host_id "$HOST_OVERRIDE")"
  if [[ -n "$override" ]]; then
    echo "$override"
    return
  fi

  hostname_l="$(hostname 2>/dev/null | tr '[:upper:]' '[:lower:]' || true)"
  family="$(os_family)"

  if [[ "$hostname_l" == *mac*mini* || "$hostname_l" == *macmini* ]]; then
    echo mac-mini
    return
  fi
  if [[ "$hostname_l" == *ped* || "$hostname_l" == *linux*ped* ]]; then
    echo linux-ped
    return
  fi

  case "$family" in
    darwin) echo mac-mini ;;
    linux) echo linux-ped ;;
    *) echo "unknown-$family" ;;
  esac
}

json_escape() {
  # Minimal JSON string escape for printable text.
  printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()), end="")' 2>/dev/null \
    || printf '"%s"' "$(printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g')"
}

find_flutter() {
  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return
  fi
  local candidate
  for candidate in \
    "$HOME/flutter/bin/flutter" \
    "$HOME/development/flutter/bin/flutter" \
    /opt/flutter/bin/flutter \
    /usr/local/bin/flutter; do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return
    fi
  done
  echo ""
}

cpu_cores() {
  if [[ "$(os_family)" == darwin ]]; then
    sysctl -n hw.ncpu 2>/dev/null || echo 0
  else
    nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 0
  fi
}

load_averages() {
  # Prints: load1 load5 load15
  if [[ "$(os_family)" == darwin ]]; then
    # e.g. "21:04  up 3 days,  2 users, load averages: 1.23 1.45 1.67"
    local line
    line="$(uptime)"
    if [[ "$line" =~ load\ averages:\ ([0-9.]+)\ ([0-9.]+)\ ([0-9.]+) ]]; then
      echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}"
      return
    fi
  fi
  if [[ -r /proc/loadavg ]]; then
    awk '{print $1, $2, $3}' /proc/loadavg
    return
  fi
  # Fallback: parse generic uptime.
  local line
  line="$(uptime)"
  if [[ "$line" =~ load\ average[s]?:[[:space:]]*([0-9.]+),[[:space:]]*([0-9.]+),[[:space:]]*([0-9.]+) ]]; then
    echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}"
    return
  fi
  echo "0 0 0"
}

memory_stats_mb() {
  # Prints: total_mb available_mb
  if [[ "$(os_family)" == darwin ]]; then
    local page_size pages_free pages_inactive pages_speculative total_bytes avail_bytes
    page_size="$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)"
    pages_free="$(vm_stat | awk '/Pages free/ {gsub("\\.","",$3); print $3}')"
    pages_inactive="$(vm_stat | awk '/Pages inactive/ {gsub("\\.","",$3); print $3}')"
    pages_speculative="$(vm_stat | awk '/Pages speculative/ {gsub("\\.","",$3); print $3}')"
    total_bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
    avail_bytes=$(( (pages_free + pages_inactive + pages_speculative) * page_size ))
    echo $(( total_bytes / 1024 / 1024 )) $(( avail_bytes / 1024 / 1024 ))
    return
  fi
  if [[ -r /proc/meminfo ]]; then
    awk '
      /^MemTotal:/ { total=$2 }
      /^MemAvailable:/ { avail=$2 }
      END { printf "%d %d\n", int(total/1024), int(avail/1024) }
    ' /proc/meminfo
    return
  fi
  echo "0 0"
}

disk_free_gb() {
  df -Pk "$ROOT_DIR" 2>/dev/null | awk 'NR==2 {printf "%.1f", $4/1024/1024}'
}

count_test_files() {
  find "$ROOT_DIR/test" -type f -name '*_test.dart' 2>/dev/null | wc -l | tr -d ' '
}

approx_test_count() {
  # Counts test( / group( declarations; useful as suite-size signal, not exact.
  if command -v rg >/dev/null 2>&1; then
    rg -N --glob '*_test.dart' -c '^\s*(test|group)\s*\(' "$ROOT_DIR/test" 2>/dev/null \
      | awk -F: '{s+=$2} END {print s+0}'
    return
  fi
  grep -R --include='*_test.dart' -E '^\s*(test|group)\s*\(' "$ROOT_DIR/test" 2>/dev/null \
    | wc -l | tr -d ' '
}

busy_flutter_test_count() {
  # Best-effort: count processes that look like an active flutter/dart test run.
  ps aux 2>/dev/null | awk '
    BEGIN { c=0 }
    /[f]lutter( .*)? test/ { c++ }
    /[d]art( .*)? test/ { c++ }
    END { print c+0 }
  '
}

git_meta() {
  local branch sha dirty
  branch="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  sha="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  if git -C "$ROOT_DIR" status --porcelain 2>/dev/null | grep -q .; then
    dirty=1
  else
    dirty=0
  fi
  echo "$branch" "$sha" "$dirty"
}

latest_snapshot_for() {
  local host_id="$1"
  if [[ -f "$STATS_DIR/latest-${host_id}.json" ]]; then
    echo "$STATS_DIR/latest-${host_id}.json"
    return
  fi
  ls -1t "$STATS_DIR"/snapshot-"$host_id"-*.json 2>/dev/null | head -n 1 || true
}

latest_run_for() {
  local host_id="$1"
  ls -1t "$STATS_DIR"/run-"$host_id"-*.json 2>/dev/null | head -n 1 || true
}

score_snapshot() {
  # Higher is better. Prints integer score and reason tags on stderr summary via stdout "score|reasons".
  local file="$1"
  python3 - "$file" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    d = json.load(f)

score = 0
reasons = []

flutter_ok = bool(d.get("toolchain", {}).get("flutter_available"))
if flutter_ok:
    score += 40
    reasons.append("flutter_ready")
else:
    reasons.append("flutter_missing")

busy = int(d.get("busy_flutter_test_processes") or 0)
if busy == 0:
    score += 25
    reasons.append("idle")
else:
    score -= 30
    reasons.append(f"busy({busy})")

load_pc = float(d.get("cpu", {}).get("load1_per_core") or 0)
if load_pc < 0.35:
    score += 20
    reasons.append("low_load")
elif load_pc < 0.75:
    score += 10
    reasons.append("moderate_load")
elif load_pc < 1.2:
    score += 0
    reasons.append("elevated_load")
else:
    score -= 15
    reasons.append("high_load")

avail = int(d.get("memory", {}).get("available_mb") or 0)
if avail >= 8192:
    score += 15
    reasons.append("mem_8g+")
elif avail >= 4096:
    score += 10
    reasons.append("mem_4g+")
elif avail >= 2048:
    score += 5
    reasons.append("mem_2g+")
else:
    score -= 10
    reasons.append("mem_low")

disk = float(d.get("disk_free_gb") or 0)
if disk >= 20:
    score += 5
elif disk < 5:
    score -= 10
    reasons.append("disk_low")

last = d.get("last_recorded_run") or {}
dur = last.get("duration_sec")
if isinstance(dur, (int, float)) and dur > 0:
    # Faster historical full runs are preferred.
    if dur <= 300:
        score += 10
        reasons.append("hist_fast")
    elif dur <= 600:
        score += 5
        reasons.append("hist_ok")
    elif dur >= 1200:
        score -= 5
        reasons.append("hist_slow")

print(f"{score}|{','.join(reasons)}")
PY
}

collect_snapshot() {
  local host_id ts iso cores load1 load5 load15 load1_pc
  local mem_total mem_avail mem_used_pct disk_free
  local flutter_bin flutter_available flutter_version dart_version
  local test_files approx_tests busy branch sha dirty
  local dart_tool_present last_run_path last_run_json
  local out_path

  host_id="$(detect_host_id)"
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  cores="$(cpu_cores)"
  read -r load1 load5 load15 <<<"$(load_averages)"
  if [[ "${cores:-0}" -gt 0 ]]; then
    load1_pc="$(python3 -c "print(round(float('$load1')/float('$cores'), 3))" 2>/dev/null || echo 0)"
  else
    load1_pc="0"
  fi
  read -r mem_total mem_avail <<<"$(memory_stats_mb)"
  if [[ "${mem_total:-0}" -gt 0 ]]; then
    mem_used_pct="$(python3 -c "print(round(100.0*(1.0-float('$mem_avail')/float('$mem_total')),1))" 2>/dev/null || echo 0)"
  else
    mem_used_pct="0"
  fi
  disk_free="$(disk_free_gb)"
  flutter_bin="$(find_flutter)"
  if [[ -n "$flutter_bin" ]]; then
    flutter_available=true
    flutter_version="$("$flutter_bin" --version 2>/dev/null | head -n 1 | tr -d '\r' || true)"
    dart_version="$("$flutter_bin" --version 2>/dev/null | awk '/Dart /{print; exit}' | tr -d '\r' || true)"
  else
    flutter_available=false
    flutter_version=""
    dart_version=""
  fi
  test_files="$(count_test_files)"
  approx_tests="$(approx_test_count)"
  busy="$(busy_flutter_test_count)"
  read -r branch sha dirty <<<"$(git_meta)"
  if [[ -d "$ROOT_DIR/.dart_tool" ]]; then
    dart_tool_present=true
  else
    dart_tool_present=false
  fi

  last_run_path="$(latest_run_for "$host_id")"
  if [[ -n "$last_run_path" ]]; then
    last_run_json="$(cat "$last_run_path")"
  else
    last_run_json="null"
  fi

  out_path="$STATS_DIR/snapshot-${host_id}-${ts}.json"
  cat >"$out_path" <<EOF
{
  "schema": "eh.test_host_stats.v1",
  "kind": "snapshot",
  "captured_at": $(json_escape "$iso"),
  "host_id": $(json_escape "$host_id"),
  "hostname": $(json_escape "$(hostname 2>/dev/null || echo unknown)"),
  "os": {
    "family": $(json_escape "$(os_family)"),
    "uname": $(json_escape "$(uname -a)")
  },
  "cpu": {
    "cores": ${cores:-0},
    "load1": ${load1:-0},
    "load5": ${load5:-0},
    "load15": ${load15:-0},
    "load1_per_core": ${load1_pc:-0}
  },
  "memory": {
    "total_mb": ${mem_total:-0},
    "available_mb": ${mem_avail:-0},
    "used_pct": ${mem_used_pct:-0}
  },
  "disk_free_gb": ${disk_free:-0},
  "toolchain": {
    "flutter_available": ${flutter_available},
    "flutter_bin": $(json_escape "$flutter_bin"),
    "flutter_version": $(json_escape "$flutter_version"),
    "dart_version": $(json_escape "$dart_version"),
    "dart_tool_present": ${dart_tool_present}
  },
  "suite": {
    "test_files": ${test_files:-0},
    "approx_test_or_group_decls": ${approx_tests:-0}
  },
  "busy_flutter_test_processes": ${busy:-0},
  "git": {
    "branch": $(json_escape "$branch"),
    "sha": $(json_escape "$sha"),
    "dirty": $([[ "$dirty" == "1" ]] && echo true || echo false)
  },
  "last_recorded_run": ${last_run_json}
}
EOF

  # Keep a stable "latest" pointer per host.
  cp "$out_path" "$STATS_DIR/latest-${host_id}.json"

  if [[ "$JSON_ONLY" -eq 1 ]]; then
    cat "$out_path"
  else
    print_human_snapshot "$out_path"
    echo
    echo "Saved: $out_path"
  fi
}

print_human_snapshot() {
  local file="$1"
  python3 - "$file" <<'PY'
import json, sys
d = json.load(open(sys.argv[1], encoding="utf-8"))
cpu = d["cpu"]
mem = d["memory"]
tc = d["toolchain"]
suite = d["suite"]
git = d["git"]
last = d.get("last_recorded_run") or {}

print(f"Host:        {d['host_id']}  ({d['hostname']})")
print(f"Captured:    {d['captured_at']} UTC")
print(f"OS:          {d['os']['family']} / {d['os']['uname'].split()[2] if len(d['os']['uname'].split())>2 else d['os']['uname']}")
print(f"CPU:         {cpu['cores']} cores | load {cpu['load1']} {cpu['load5']} {cpu['load15']} | load/core {cpu['load1_per_core']}")
print(f"Memory:      {mem['available_mb']} MB free of {mem['total_mb']} MB ({mem['used_pct']}% used)")
print(f"Disk free:   {d['disk_free_gb']} GB")
print(f"Flutter:     {'YES' if tc['flutter_available'] else 'NO'}"
      + (f" — {tc['flutter_version']}" if tc.get('flutter_version') else ""))
if tc.get("dart_version"):
    print(f"Dart:        {tc['dart_version']}")
print(f".dart_tool:  {'present' if tc['dart_tool_present'] else 'missing (run flutter pub get)'}")
print(f"Suite:       {suite['test_files']} *_test.dart files | ~{suite['approx_test_or_group_decls']} test/group decls")
print(f"Busy tests:  {d['busy_flutter_test_processes']} process(es)")
print(f"Git:         {git['branch']} @ {git['sha']}{' (dirty)' if git['dirty'] else ''}")
if last:
    print(
        "Last run:    "
        f"{last.get('duration_sec', '?')}s"
        f" | passed={last.get('passed', '?')}"
        f" failed={last.get('failed', '?')}"
        f" @ {last.get('recorded_at', '?')}"
    )
else:
    print("Last run:    (none recorded — use --record-run after a suite)")

# Quick readiness line.
issues = []
if not tc["flutter_available"]:
    issues.append("Flutter not found")
if int(d["busy_flutter_test_processes"] or 0) > 0:
    issues.append("test run already active")
if float(cpu["load1_per_core"] or 0) >= 1.2:
    issues.append("high CPU load")
if int(mem["available_mb"] or 0) < 2048:
    issues.append("low free memory (<2GB)")
if float(d["disk_free_gb"] or 0) < 5:
    issues.append("low disk (<5GB)")

print()
if issues:
    print("Readiness:   CAUTION — " + "; ".join(issues))
else:
    print("Readiness:   OK to attempt full flutter test on this host")
PY
}

record_run() {
  local host_id ts iso out_path branch sha dirty
  [[ -n "$DURATION_SEC" ]] || die "--record-run requires --duration-sec"
  host_id="$(detect_host_id)"
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  read -r branch sha dirty <<<"$(git_meta)"
  out_path="$STATS_DIR/run-${host_id}-${ts}.json"
  cat >"$out_path" <<EOF
{
  "schema": "eh.test_host_stats.v1",
  "kind": "run",
  "recorded_at": $(json_escape "$iso"),
  "host_id": $(json_escape "$host_id"),
  "duration_sec": ${DURATION_SEC},
  "passed": ${PASSED:-null},
  "failed": ${FAILED:-null},
  "git": {
    "branch": $(json_escape "$branch"),
    "sha": $(json_escape "$sha"),
    "dirty": $([[ "$dirty" == "1" ]] && echo true || echo false)
  }
}
EOF
  # Refresh latest snapshot's embedded last_recorded_run if present.
  if [[ -f "$STATS_DIR/latest-${host_id}.json" ]]; then
    python3 - "$STATS_DIR/latest-${host_id}.json" "$out_path" <<'PY'
import json, sys
snap_path, run_path = sys.argv[1], sys.argv[2]
snap = json.load(open(snap_path, encoding="utf-8"))
run = json.load(open(run_path, encoding="utf-8"))
snap["last_recorded_run"] = run
with open(snap_path, "w", encoding="utf-8") as f:
    json.dump(snap, f, indent=2)
    f.write("\n")
PY
  fi
  echo "Recorded run: $out_path"
  echo "Host: $host_id | duration=${DURATION_SEC}s | passed=${PASSED:-?} | failed=${FAILED:-?}"
}

compare_hosts() {
  local recommend="$1"
  local mac_path ped_path
  local mac_score_line mac_score mac_reasons
  local ped_score_line ped_score ped_reasons

  mac_path="$(latest_snapshot_for mac-mini)"
  ped_path="$(latest_snapshot_for linux-ped)"

  if [[ -z "$mac_path" && -z "$ped_path" ]]; then
    die "no snapshots found in $STATS_DIR — run this script once on each host first"
  fi

  echo "Comparing latest snapshots in $STATS_DIR"
  echo

  mac_score=-999
  mac_reasons="missing"
  ped_score=-999
  ped_reasons="missing"

  if [[ -n "$mac_path" ]]; then
    echo "=== mac-mini ==="
    print_human_snapshot "$mac_path"
    mac_score_line="$(score_snapshot "$mac_path")"
    mac_score="${mac_score_line%%|*}"
    mac_reasons="${mac_score_line#*|}"
    echo "Score:       $mac_score  ($mac_reasons)"
    echo "Snapshot:    $mac_path"
  else
    echo "=== mac-mini ==="
    echo "(no snapshot yet)"
  fi

  echo
  if [[ -n "$ped_path" ]]; then
    echo "=== linux-ped ==="
    print_human_snapshot "$ped_path"
    ped_score_line="$(score_snapshot "$ped_path")"
    ped_score="${ped_score_line%%|*}"
    ped_reasons="${ped_score_line#*|}"
    echo "Score:       $ped_score  ($ped_reasons)"
    echo "Snapshot:    $ped_path"
  else
    echo "=== linux-ped ==="
    echo "(no snapshot yet)"
  fi

  echo
  if [[ "$recommend" -eq 1 ]]; then
    if [[ "$mac_score" -eq -999 && "$ped_score" -eq -999 ]]; then
      echo "Recommendation: collect snapshots on both hosts first."
    elif [[ "$mac_score" -gt "$ped_score" ]]; then
      echo "Recommendation: prefer mac-mini (score $mac_score > $ped_score)."
      echo "Reasons: $mac_reasons"
    elif [[ "$ped_score" -gt "$mac_score" ]]; then
      echo "Recommendation: prefer linux-ped (score $ped_score > $mac_score)."
      echo "Reasons: $ped_reasons"
    else
      echo "Recommendation: hosts are tied (score $mac_score). Prefer the idle host with more free RAM;"
      echo "use mac-mini if you need iOS/device coverage, otherwise either is fine."
    fi
  fi
}

case "$MODE" in
  collect) collect_snapshot ;;
  record-run) record_run ;;
  compare) compare_hosts 0 ;;
  recommend) compare_hosts 1 ;;
  *) die "unknown mode: $MODE" ;;
esac
