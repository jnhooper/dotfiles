# summary

this was setup using gnu stow. it is recommended you install and set it up as
well

https://www.gnu.org/software/stow/manual/stow.html

https://tamerlan.dev/how-i-manage-my-dotfiles-using-gnu-stow/

## zsh_config

repo of zsh configs

### skim

this was influenced by this article and is mainly used to have a better ctrl-r
experience in the terminal

https://tratt.net/laurie/blog/2025/better_shell_history_search.html

in you .zshrc add these lines

```
setopt EXTENDED_HISTORY
setopt inc_append_history_time

source ~/.zsh/skim/key-bindings.zsh
```

### eza

https://github.com/eza-community/eza

### zsh tools

https://github.com/marlonrichert/zsh-autocomplete

https://github.com/zsh-users/zsh-autosuggestions

https://github.com/alexpasmantier/television?tab=readme-ov-file

### zioxide

super charge `cd`

```
brew install zoxide
```

https://github.com/ajeetdsouza/zoxide

## starship

https://starship.rs/config/

### tl;dr

`mkdir -p ~/.config && touch ~/.config/starship.toml` copy `starship.toml` into
that file

## mise

https://mise.jdx.dev/

Manages ruby, node and pnpm (replaced rvm and volta). Global defaults live in
`mise/.config/mise/config.toml`; per-project `.ruby-version` / `.nvmrc` files win
over them, which only works because the config opts those tools into
`idiomatic_version_file_enable_tools`.

```
curl https://mise.run | sh   # installs to ~/.local/bin/mise
stow --no-folding -t ~ mise
mise install                 # ruby is a source build, give it a while
```

`--no-folding` matters here. Without it stow links the whole directory
(`~/.config/mise -> ../dotfiles/mise/.config/mise`), and mise then finds no
config at all — `mise doctor` reports an empty `config_files` and every tool
falls back to the system version. It follows a symlinked config *file* but not a
symlinked config *directory*, so the target has to stay a real directory with
`config.toml` linked inside it.

Activation is split across the two zsh startup files: `.zprofile` adds the shims
so non-interactive shells (editors, CI, Claude Code) still see the tools, and
`.zshrc` runs the full `mise activate zsh` for interactive shells.
