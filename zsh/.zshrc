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

# cleans up branches merged in main or master

clean() {
  local target branches gone_branches remote="origin"
  local current_branch=$(git branch --show-current)
  
  # 1. Determine if the local repo uses main or master
  if git show-ref --verify --quiet refs/heads/main; then
    target="main"
  elif git show-ref --verify --quiet refs/heads/master; then
    target="master"
  else
    echo "Error: Neither 'main' nor 'master' branch found locally."
    return 1
  fi

  # 2. Prune dead remote-tracking branches
  echo "Pruning deleted remote branches..."
  git fetch --prune "$remote" --quiet

  # 3. Fetch and fast-forward the local target branch
  echo "Fetching latest changes for $target..."
  if [ "$current_branch" = "$target" ]; then
    if ! git pull --ff-only "$remote" "$target" --quiet 2>/dev/null; then
      echo "Warning: Could not pull '$target'. You may have unpushed commits."
    fi
  else
    if ! git fetch "$remote" "$target":"$target" --quiet 2>/dev/null; then
      echo "Warning: Could not cleanly fast-forward local '$target'."
    fi
  fi

  # 4. Standard cleanup: Get strictly merged branches
  branches=$(git branch --merged "$target" | grep -vE "^\s*(\*|main|develop|master)")
  if [ -n "$branches" ]; then
    echo "Cleaning strictly merged branches..."
    echo "$branches" | xargs -n 1 git branch -d
  fi

  # 5. Squash-merge cleanup: Get branches where the remote is 'gone'
  # We skip the current branch so we don't accidentally delete what you're working on
  gone_branches=$(git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads | awk '$2 == "[gone]" {print $1}' | grep -vE "^\s*$current_branch$")
  
  if [ -n "$gone_branches" ]; then
    echo "Cleaning local branches deleted on remote (Squash/Rebase merged)..."
    echo "$gone_branches" | xargs -n 1 git branch -D
  fi

  if [ -z "$branches" ] && [ -z "$gone_branches" ]; then
    echo "Repo is squeaky clean. Nothing to do!"
  fi
}

setopt EXTENDED_HISTORY
setopt inc_append_history_time

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.zsh/skim/key-bindings.zsh

export EDITOR="nvim"
export VISUAL="$EDITOR"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"

show_diffs() {
  git fetch production
  open -a 'firefox developer edition' -g "https://github.com/Giftly/China/compare/`git rev-parse production/master`...`git rev-parse master`"
}

source <(fzf --zsh)
eval "$(zoxide init zsh)"
alias cd="z"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# Added by Antigravity
export PATH="/Users/johnhooper/.antigravity/antigravity/bin:$PATH"
