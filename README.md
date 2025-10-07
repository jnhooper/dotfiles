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

## starship

https://starship.rs/config/

### tl;dr

`mkdir -p ~/.config && touch ~/.config/starship.toml` copy `starship.toml` into
that file
