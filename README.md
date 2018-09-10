# ~ sweet ~

Here is where I keep a personal copy of my config files used on both MacOS and Linux. They are managed via [stow](https://www.gnu.org/software/stow/manual/stow.html) and are easily deployed as:

```shell
$ git clone https://github.com/srydell/dotfiles.git ~/dotfiles && cd ~/dotfiles
$ stow vim
...
```

This will create a symlink from the `dotfiles/vim` directory to the directory containing `dotfiles` (in this case `~`). If there are conflicting files, `stow` will not remove them but will simply terminate with a warning.

Note however that these are **my** config files and I do not recommend using them as they are. It is dangerous to blindly install something. Read through the files you are interested in and copy the lines you understand. I have commented to my best ability.
