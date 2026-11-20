#!/usr/bin/env bash
# Live A/B experiment: Sonnet vs Opus per spec-review reviewer.
# Records counts and ids only, never finding text, so no spec content lands on disk.
#
#   review-experiment.sh pick
#   review-experiment.sh log spec=<id> round=<1|2> reviewer=<name> model=<sonnet|opus> \
#       runner=<interactive|archon> raw=N clear=N judgment=N deduped=N kept=N unique_kept=N \
#       contested=N escalated=N skipped=N [tokens=N] [tool_uses=N] [duration_ms=N] \
#       [paraphrase_corrections=N]
#   review-experiment.sh resolve spec=<id> reviewer=<name> kept=N unique_kept=N skipped=N \
#       [paraphrase_corrections=N]
#   review-experiment.sh escaped spec=<id> reviewer=<name>
#   review-experiment.sh summary
#
# Log file: $SPEC_REVIEW_EXPERIMENT_LOG, default ~/.claude/spec-review-experiment.jsonl
set -euo pipefail

LOG="${SPEC_REVIEW_EXPERIMENT_LOG:-$HOME/.claude/spec-review-experiment.jsonl}"
REVIEWERS="correctness completeness reader"
MODELS="sonnet opus"
REQUIRED_LOG="spec round reviewer model runner raw clear judgment deduped kept unique_kept contested escalated skipped"
NUMERIC="round raw clear judgment deduped kept unique_kept contested escalated skipped tokens tool_uses duration_ms paraphrase_corrections"
OPTIONAL_LOG="tokens tool_uses duration_ms paraphrase_corrections"
REQUIRED_RESOLVE="spec reviewer kept unique_kept skipped"

die() { echo "review-experiment: $*" >&2; exit 1; }

in_list() { # in_list <word> <list>
  case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# Build a JSON object from key=value args, checking keys and values.
to_json() { # to_json <type> <required> <allowed> args...
  local type="$1" required="$2" allowed="$3"; shift 3
  local args=(--arg type "$type" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)")
  local filter='{type: $type, ts: $ts'
  local seen="" kv key val
  for kv in "$@"; do
    case "$kv" in *=*) ;; *) die "expected key=value, got '$kv'" ;; esac
    key="${kv%%=*}"; val="${kv#*=}"
    in_list "$key" "$allowed" || die "unknown key '$key'"
    in_list "$key" "$seen" && die "duplicate key '$key'"
    seen="$seen $key"
    case "$key" in
      reviewer) in_list "$val" "$REVIEWERS" || die "reviewer must be one of: $REVIEWERS" ;;
      model) in_list "$val" "$MODELS" || die "model must be one of: $MODELS" ;;
      runner) in_list "$val" "interactive archon" || die "runner must be interactive or archon" ;;
      round) in_list "$val" "1 2" || die "round must be 1 or 2" ;;
    esac
    if in_list "$key" "$NUMERIC"; then
      [[ "$val" =~ ^[0-9]+$ ]] || die "'$key' must be a non-negative integer, got '$val'"
      args+=(--argjson "$key" "$val")
    else
      [ -n "$val" ] || die "'$key' must not be empty"
      args+=(--arg "$key" "$val")
    fi
    filter="$filter, $key: \$$key"
  done
  for key in $required; do
    in_list "$key" "$seen" || die "missing required key '$key'"
  done
  jq -cn "${args[@]}" "$filter}"
}

append() {
  mkdir -p "$(dirname "$LOG")"
  printf '%s\n' "$1" >> "$LOG"
  echo "logged to $LOG"
}

cmd="${1:-}"; [ $# -gt 0 ] && shift
case "$cmd" in
  pick)
    # An independent coin flip per reviewer. Keep the result for both rounds of a run.
    for r in $REVIEWERS; do
      if [ $((RANDOM % 2)) -eq 0 ]; then echo "$r=sonnet"; else echo "$r=opus"; fi
    done
    ;;
  log)
    json="$(to_json review "$REQUIRED_LOG" "$REQUIRED_LOG $OPTIONAL_LOG" "$@")"
    append "$json"
    ;;
  resolve)
    json="$(to_json resolve "$REQUIRED_RESOLVE" "$REQUIRED_RESOLVE paraphrase_corrections" "$@")"
    append "$json"
    ;;
  escaped)
    json="$(to_json escaped "spec reviewer" "spec reviewer" "$@")"
    append "$json"
    ;;
  summary)
    [ -s "$LOG" ] || die "no data yet in $LOG"
    jq -rs '
      def ratio(a; b): if b == 0 then "-" else ((a / b * 100 | round) / 100 | tostring) end;
      def sum(f): map(f // 0) | add // 0;
      (map(select(.type == "review" and .round == 1)) | map({key: "\(.spec)|\(.reviewer)", value: .model}) | from_entries) as $assigned
      | map(if .type == "review" then . else . + {model: ($assigned["\(.spec)|\(.reviewer)"] // "unknown")} end)
      | group_by([.reviewer, .model])
      | ["reviewer", "model", "rows", "specs", "raw", "kept", "unique_kept", "contested", "contested_rate", "tokens_per_kept", "escaped"],
        (.[] | . as $g | $g[0] as $f
          | ($g | map(select(.type == "review"))) as $rev
          | ($g | map(select(.type != "escaped"))) as $settled
          | ($rev | map(select(.tokens != null))) as $tok
          | [$f.reviewer, $f.model, ($rev | length), ($g | map(.spec) | unique | length),
             ($rev | sum(.raw)), ($settled | sum(.kept)), ($settled | sum(.unique_kept)),
             ($rev | sum(.contested)), ratio(($rev | sum(.contested)); ($rev | sum(.raw))),
             ratio(($tok | sum(.tokens)); ($settled | sum(.kept))),
             ($g | map(select(.type == "escaped")) | length)])
      | @tsv' "$LOG" | column -t -s $'\t'
    echo
    echo "tokens_per_kept is raw tokens. Price the two models separately before comparing cost."
    ;;
  *)
    sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'
    [ -z "$cmd" ] || exit 1
    ;;
esac
