# Ring BEL when a command fails, which drives kitty's screen-shake shader
# (~/.config/kitty/shaders/shake.pipeline). Sourced from ~/.bashrc by the
# CachyOS and Ubuntu installers.
#
# The bell should only ring after a command that actually ran. $? keeps its
# last value across an empty Enter or a Ctrl-C at the prompt, so a precmd-only
# check would shake again on every blank line after a failure. bash-preexec
# (which atuin loads) gives a preexec hook that sets a flag when a command
# starts. Source this after `eval "$(atuin init bash)"` so the hooks exist.

[[ $- == *i* ]] || return 0

__kitty_shake_preexec() { __kitty_shake_ran=1; }
__kitty_shake_precmd() {
    local s=$?
    [[ -n ${__kitty_shake_ran-} && $s -ne 0 ]] && printf '\a'
    __kitty_shake_ran=
    return $s
}

if [[ -n ${bash_preexec_imported-}${__bp_imported-} ]]; then
    preexec_functions+=(__kitty_shake_preexec)
    precmd_functions+=(__kitty_shake_precmd)
else
    # No bash-preexec: ring on any failed $? at prompt time. This does re-ring
    # on an empty Enter after a failure. Prepend so $? is still the command's.
    __kitty_shake_fallback() { local s=$?; ((s)) && printf '\a'; return $s; }
    if [[ $(declare -p PROMPT_COMMAND 2>/dev/null) == "declare -a"* ]]; then
        PROMPT_COMMAND=(__kitty_shake_fallback "${PROMPT_COMMAND[@]}")
    else
        PROMPT_COMMAND="__kitty_shake_fallback${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
    fi
fi
