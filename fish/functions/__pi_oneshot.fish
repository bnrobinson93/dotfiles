# Reads a prompt on stdin, writes the model's reply on stdout. Callers parse
# that reply, so the --no-* flags are load-bearing: with session, tools, context
# files, or skills left on, the same prompt answers differently per repo and per
# run.
function __pi_oneshot
    pi --model openai/gpt-5.6-luna \
        --no-session --no-tools --no-context-files \
        --no-skills --no-prompt-templates --no-extensions --print
end
