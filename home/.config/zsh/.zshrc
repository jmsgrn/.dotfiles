# $ZDOTDIR/.zshrc - sourced by interactive zsh shells

# 1. Completion system - MUST be loaded before antidote so oh-my-zsh plugins
# can call compdef at load time without "command not found: compdef" spam.
autoload -Uz compinit && compinit

# 2. Antidote (plugin manager) - load plugins from $ZDOTDIR/.zsh_plugins.txt
ANTIDOTE_HOME="${HOME}/.antidote"
if [[ -f "${ANTIDOTE_HOME}/antidote.zsh" ]]; then
  source "${ANTIDOTE_HOME}/antidote.zsh"
  antidote load "${ZDOTDIR}/.zsh_plugins.txt"
fi

# 3. Source every *.zsh in $ZDOTDIR (= ~/.config/zsh/)
# Picks up the symlinked files (aliases.zsh, functions.zsh, exports.zsh, tools.zsh)
# AND any local-only files like work.zsh that aren't tracked in git.
for f in "${ZDOTDIR}"/*.zsh(N); do
  source "$f"
done

# 4. Starship prompt - last so it wins over any plugin prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# 5. History config
HISTFILE="${ZDOTDIR}/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS INC_APPEND_HISTORY

# 6. Sane shell defaults
setopt AUTO_CD                    # `cd` is optional - just type a path
setopt EXTENDED_GLOB              # **/* recursive glob
setopt INTERACTIVE_COMMENTS       # allow # comments in interactive shells


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
# opencode
export PATH="$HOME/.opencode/bin:$PATH"
