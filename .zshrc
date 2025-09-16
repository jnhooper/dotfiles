eval "$(starship init zsh)"
# eza (better `ls`)
alias l="eza --icons"
alias ls="eza --icons"
alias ll="eza -lg --icons"
alias la="eza -lag --icons"
alias lt="eza -lTg --icons"
alias lt1="eza -lTg --level=1 --icons"
alias lt2="eza -lTg --level=2 --icons"
alias lt3="eza -lTg --level=3 --icons"
alias lta="eza -lTag --icons"
alias lta1="eza -lTag --level=1 --icons"
alias lta2="eza -lTag --level=2 --icons"
alias lta3="eza -lTag --level=3 --icons"

setopt EXTENDED_HISTORY
setopt inc_append_history_time

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/skim/key-bindings.zsh



# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

show_diffs() {
  git fetch production
  open -a 'firefox developer edition' -g "https://github.com/Giftly/China/compare/`git rev-parse production/master`...`git rev-parse master`"
}

source <(fzf --zsh)
eval "$(zoxide init zsh)"
alias cd="z"
