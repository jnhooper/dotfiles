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
# Fast PR reviewer using gh and tuicr.
#
# Scoped to the repo you are standing in by default; pass -g to search every
# repo you have access to. Either way it hands tuicr a full PR URL (tuicr
# accepts <owner/repo#N> or a URL and fetches the PR itself), so the launch
# works from anywhere, including outside a git repo.
#
# PRs someone has already approved are hidden, since they no longer need you;
# -a shows them with a ✅. The remainder are labelled by your own last review,
# because GitHub drops you from a PR's requested reviewers the moment you
# submit any review, so PRs you already commented on would otherwise vanish:
#   🆕 review requested, you have not weighed in yet
#   💬 you commented, nothing decided since
#   🔁 you requested changes, waiting on a re-review
#
# Approval is computed from the full `reviews` list, taking each author's most
# recent state. The tempting shortcuts are both wrong: `reviewDecision` is null
# unless the repo has branch protection configured (Giftly/China does not), and
# `latestReviews` silently omits reviewers.
#
# NOTE: never pipe JSON through `echo` here. zsh's echo expands backslash
# escapes, so the \n and \t inside GitHub's JSON strings become real control
# characters and jq rejects them ("Invalid string: control characters from
# U+0000 through U+001F must be escaped"). Use a <<< herestring instead.
review_prs() {
  local raw pr_json count skipped selection target where scope=''
  local global=0 show_approved=0 repo me

  while (( $# )); do
    case "$1" in
      -g | --global) global=1 ;;
      -a | --all | --include-approved) show_approved=1 ;;
      -h | --help)
        echo "Usage: tpr [-g|--global] [-a|--all]"
        echo "  Lists open PRs waiting on your review in the current repo."
        echo "  -g, --global   search every repo instead of just this one"
        echo "  -a, --all      include PRs someone has already approved (✅)"
        return 0
        ;;
      *)
        echo "❌ Unknown option: $1"
        echo "Usage: tpr [-g|--global] [-a|--all]"
        return 1
        ;;
    esac
    shift
  done

  me=$(gh api user --jq .login 2>/dev/null)
  if [[ -z "$me" ]]; then
    echo "❌ Could not determine your GitHub login. Try: gh auth status"
    return 1
  fi

  if (( global )); then
    where="across all repos"
  else
    repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null)
    if [[ -z "$repo" ]]; then
      echo "❌ Not in a GitHub repo. cd into one, or search everywhere with: tpr -g"
      return 1
    fi
    scope="repo:$repo "
    where="in $repo"
  fi

  # One request, two searches: PRs awaiting your review, plus PRs you have
  # already reviewed (which GitHub no longer counts as "review requested").
  # `-author:@me` matters for the second one: commenting on your own PR makes
  # you one of its reviewers, which would otherwise put it in your queue.
  raw=$(gh api graphql \
    -f query='
      query($q1: String!, $q2: String!) {
        requested: search(query: $q1, type: ISSUE, first: 50) { nodes { ...F } }
        reviewed:  search(query: $q2, type: ISSUE, first: 50) { nodes { ...F } }
      }
      fragment F on PullRequest {
        number
        title
        url
        author { login }
        repository { nameWithOwner }
        reviews(last: 50) { nodes { state author { login } } }
      }' \
    -f q1="${scope}is:open is:pr review-requested:@me -author:@me sort:updated-desc" \
    -f q2="${scope}is:open is:pr reviewed-by:@me -author:@me sort:updated-desc" 2>/dev/null)

  if [[ -z "$raw" ]]; then
    echo "❌ GitHub query failed. Check your connection, or run: gh auth status"
    return 1
  fi

  pr_json=$(jq -c --arg me "$me" --argjson keep_approved "$show_approved" '
    [ .data.requested.nodes[], .data.reviewed.nodes[] ]
    | map(select(.number))
    | unique_by(.url)
    | map(
        # Each author'"'"'s standing verdict: their most recent APPROVED or
        # CHANGES_REQUESTED, since a later plain comment does not revoke an
        # approval on GitHub. DISMISSED does revoke one, so it counts here too.
        ( [ .reviews.nodes[]
            | select(.state == "APPROVED" or .state == "CHANGES_REQUESTED" or .state == "DISMISSED") ]
          | group_by(.author.login)
          | map(.[-1]) ) as $verdicts
        | ([ $verdicts[] | select(.state == "APPROVED") | .author.login ]) as $approvers
        | ([ $verdicts[] | select(.author.login == $me) | .state ] | first // "none") as $my_verdict
        | ([ .reviews.nodes[] | select(.author.login == $me and .state != "PENDING") ] | length > 0) as $i_reviewed
        | . + { approved: (($approvers | length) > 0),
                icon: (if ($approvers | length) > 0 then "✅"
                       elif $my_verdict == "CHANGES_REQUESTED" then "🔁"
                       elif $i_reviewed then "💬"
                       else "🆕" end),
                rank: (if ($approvers | length) > 0 then 3
                       elif $my_verdict == "CHANGES_REQUESTED" then 0
                       elif $i_reviewed then 1
                       else 2 end) }
      )
    | { skipped: ([ .[] | select(.approved) ] | length),
        prs: ( (if $keep_approved == 1 then . else map(select(.approved | not)) end)
               | to_entries | sort_by([.value.rank, .key]) | map(.value) ) }
  ' <<< "$raw")

  if [[ -z "$pr_json" ]]; then
    echo "❌ Could not parse the response from GitHub."
    return 1
  fi

  count=$(jq '.prs | length' <<< "$pr_json")
  skipped=$(jq '.skipped' <<< "$pr_json")
  if [[ -z "$count" || -z "$skipped" ]]; then
    echo "❌ Could not count pending PRs."
    return 1
  fi

  # Never drop PRs silently: say how many were filtered out and how to see them.
  local note=''
  if (( skipped > 0 && ! show_approved )); then
    note=" ($skipped already approved, hidden — see them with -a)"
  fi

  if (( count == 0 )); then
    echo "🎉 No PRs waiting on your review $where!$note"
    return 0
  fi

  # Handle the single PR auto-open shortcut
  if (( count == 1 )); then
    target=$(jq -r '.prs[0].url' <<< "$pr_json")
    echo "🚀 Only 1 pending PR: $(jq -r '"\(.prs[0].icon) \(.prs[0].repository.nameWithOwner)#\(.prs[0].number) by @\(.prs[0].author.login // "unknown")"' <<< "$pr_json")$note. Opening in tuicr..."
    tuicr pr "$target"
    return 0
  fi

  # Display the numbered list. The repo prefix only earns its space when the
  # results can span repos.
  echo "📥 PRs waiting on your review $where:$note"
  echo "   🆕 new   💬 you commented   🔁 you requested changes$( (( show_approved )) && echo "   ✅ already approved")"
  echo "--------------------------------------------------"
  jq -r --argjson showrepo "$global" '
    .prs | to_entries[]
    | "[\(.key + 1)] \(.value.icon) "
      + (if $showrepo == 1 then .value.repository.nameWithOwner else "" end)
      + "#\(.value.number) @\(.value.author.login // "unknown") - \(.value.title | gsub("\\s+"; " "))"
  ' <<< "$pr_json"

  # Wait for user input selection
  echo "--------------------------------------------------"
  echo -n "Enter the number to review in tuicr (or press Enter to cancel): "
  read -r selection

  if [[ -z "$selection" ]]; then
    echo "Cancelled."
    return 0
  fi

  if [[ ! "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > count )); then
    echo "❌ Invalid selection."
    return 1
  fi

  target=$(jq -r ".prs[$((selection - 1))].url" <<< "$pr_json")

  echo "Opening $target in tuicr..."
  tuicr pr "$target"
}

# Optional: Add a short alias to trigger it quickly
alias tpr="review_prs"

# cleans up branches merged in main or master, plus their worktrees

# prints the worktree path a branch is checked out in (empty if none)
_clean_worktree_for() {
  git worktree list --porcelain | awk -v b="branch refs/heads/$1" '
    /^worktree /{ p = substr($0, 10) }
    $0 == b { print p; exit }
  '
}

# deletes a branch, first removing the worktree holding it (if any)
_clean_delete_branch() {
  local branch="$1" flag="$2"
  local wt=$(_clean_worktree_for "$branch")

  if [ -n "$wt" ]; then
    if [ "$wt" = "$(git rev-parse --show-toplevel 2>/dev/null)" ]; then
      echo "  skipping $branch: checked out in the current worktree"
      return 1
    fi
    if [ -n "$(git -C "$wt" status --porcelain)" ]; then
      echo "  skipping $branch: worktree $wt has uncommitted changes"
      return 1
    fi
    echo "  removing worktree $wt"
    git worktree remove "$wt" || return 1
  fi

  git branch "$flag" "$branch"
}

clean() {
  local target branch remote="origin" merged=0 gone=0 h_merged=0 h_gone=0
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

  # 2. Prune dead remote-tracking branches and worktrees whose dirs are gone
  echo "Pruning deleted remote branches and stale worktrees..."
  git fetch --prune "$remote" --quiet
  git worktree prune

  # 3. Fetch and fast-forward the local target branch, wherever it lives
  echo "Fetching latest changes for $target..."
  local target_worktree=$(_clean_worktree_for "$target")
  if [ -n "$target_worktree" ]; then
    if ! git -C "$target_worktree" pull --ff-only "$remote" "$target" --quiet 2>/dev/null; then
      echo "Warning: Could not pull '$target' in $target_worktree. You may have unpushed commits."
    fi
  else
    if ! git fetch "$remote" "$target":"$target" --quiet 2>/dev/null; then
      echo "Warning: Could not cleanly fast-forward local '$target'."
    fi
  fi

  # 4. Standard cleanup: strictly merged branches
  while IFS= read -r branch; do
    [ -n "$branch" ] || continue
    [ "$h_merged" -eq 0 ] && echo "Cleaning strictly merged branches..." && h_merged=1
    _clean_delete_branch "$branch" -d && merged=$((merged + 1))
  done < <(git branch --merged "$target" --format='%(refname:short)' |
    grep -vxE "main|master|develop|$current_branch")

  # 5. Squash-merge cleanup: branches where the remote is 'gone'
  # We skip the current branch so we don't accidentally delete what you're working on
  while IFS= read -r branch; do
    [ -n "$branch" ] || continue
    [ "$h_gone" -eq 0 ] && echo "Cleaning local branches deleted on remote (Squash/Rebase merged)..." && h_gone=1
    _clean_delete_branch "$branch" -D && gone=$((gone + 1))
  done < <(git for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads |
    awk '$2 == "[gone]" {print $1}' |
    grep -vxE "main|master|develop|$current_branch")

  if [ "$h_merged" -eq 0 ] && [ "$h_gone" -eq 0 ]; then
    echo "Repo is squeaky clean. Nothing to do!"
  else
    echo "Deleted $merged merged and $gone squash-merged branch(es)."
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
# zoxide's doctor check false-positives in non-interactive shells (e.g. Claude Code's
# shell snapshot replays aliases/functions but not the chpwd_functions array).
export _ZO_DOCTOR=0
eval "$(zoxide init zsh)"
alias cd="z"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# Added by Antigravity
export PATH="/Users/johnhooper/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/johnhooper/.lmstudio/bin"
# End of LM Studio CLI section


# pnpm
export PNPM_HOME="/Users/johnhooper/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
#
autoload -Uz compinit && compinit
if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
