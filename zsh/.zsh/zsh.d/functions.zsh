# git commit with commit message in vim or with a simple string as $1
# Parameter: Optional commit message
# Returns: None
gc() {
	if [[ -z $1 ]]; then
		git commit --verbose
	else
		git commit -m "$1"
	fi
}

# Git checkout branch/tag
gco() {
	local tags branches target
	tags=$(git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}') || return
	branches=$(
		git branch --all | grep -v HEAD             |
		sed "s/.* //"    | sed "s#remotes/[^/]*/##" |
		sort -u          | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}') || return
	target=$(
		(echo "$tags"; echo "$branches") | sed '/^$/d' |
		fzf-down --no-hscroll --reverse --ansi +m -d "\\t" -n 2 -q "$*") || return
	git checkout "$(echo "$target" | awk '{print $2}')"
}

# Create and enter directories
mkd() {
	mkdir -p "$@" && cd "$@"
}

# tmux attach and if an argument is passed, try to attach to that session
ta() {
	if [[ -z $1 ]]; then
		tmux attach
	else
		tmux attach -t "$1"
	fi
}

# Use ffmpeg to convert a file to gif
togif() {
	if [ -f "$1" ]; then
		outfile="output"
		if ! [ -z "$2" ]; then
			outfile="$2"
		fi
		ffmpeg -i "$1" -r "20" "$outfile".gif
	else
		cat <<-END
		Usage:

		    $ togif inputfile outputfile

		Or default to output.gif

		    $ togif inputfile
		END
	fi
}
