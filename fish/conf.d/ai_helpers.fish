# Shared helpers for opencode-backed commit/PR message generation.
# Consumed by `ghpr` and `commit`. Private — underscore prefix.

function _ai_model --description "Pick opencode model per platform"
    if test (uname -s) = Darwin
        echo openai/gpt-4o-mini
    else
        echo opencode/big-pickle
    end
end

function _ai_run --description "Invoke opencode outside a pipeline so \$status survives" \
    --argument-names model prompt_file out_file err_file
    # Fish collapses \$pipestatus to a single element across command substitution,
    # so piping into opencode loses the real exit code. Explicit file redirects
    # keep status intact for the caller.
    opencode run --model $model --format default <$prompt_file >$out_file 2>$err_file
end

function _ai_strip_fences --description "Drop leading ``` fence line + matching trailing ``` line"
    # Reads stdin, writes to stdout. Only outermost fences are stripped;
    # internal ``` blocks in message bodies are preserved.
    awk '
        NR == 1 && /^```/ { next }
        { buf[NR] = $0 }
        END {
            end = NR
            if (end in buf && buf[end] ~ /^```[[:space:]]*$/) end--
            for (i = 1; i <= end; i++) if (i in buf) print buf[i]
        }'
end

function _ai_strip_trailer --description "Truncate output at model pleasantry lines"
    # Reads stdin, stops at lines like "Feel free to modify..." — models emit
    # these despite instructions to the contrary. Pattern is lowercase-matched
    # (BSD awk has no IGNORECASE) but the original line would have been dropped
    # anyway, so casing of the input doesn't matter.
    awk '
        tolower($0) ~ /^(feel free to |let me know if |hope (this|that) helps|if you (need|have)|please (let me|note)|you can (modify|customize|adjust))/ { exit }
        { print }'
end

function _ai_extract_marker --description "Pull TITLE or BODY section from formatted AI output" \
    --argument-names marker file
    # Tolerates markdown-decorated markers (### TITLE:, **BODY:**) by stripping
    # leading # * whitespace *only when probing* — body content is printed
    # verbatim so its own markdown survives.
    awk -v marker="$marker" '
        started == 2 { print; next }
        {
            probe = $0
            sub(/^[[:space:]#*]+/, "", probe)
            sub(/[[:space:]*]+$/, "", probe)
            if (started == 0 && match(probe, "^" marker ":[[:space:]]*")) {
                rest = substr(probe, RLENGTH + 1)
                if (marker == "TITLE") {
                    if (length(rest) > 0) { print rest; exit }
                    want = 1
                } else {
                    started = 2
                    if (length(rest) > 0) print rest
                }
                next
            }
            if (marker == "TITLE" && want && length(probe) > 0) { print probe; exit }
        }' $file
end
