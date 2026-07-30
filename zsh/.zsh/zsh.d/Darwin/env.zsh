# Homebrew lives in /opt/homebrew on Apple Silicon and /usr/local on Intel.
# It may also be absent during the first shell started on a new machine.
if (( $+commands[brew] )); then
	brew_command=$commands[brew]
elif [[ -x /opt/homebrew/bin/brew ]]; then
	brew_command=/opt/homebrew/bin/brew
elif [[ -x /usr/local/bin/brew ]]; then
	brew_command=/usr/local/bin/brew
fi

if [[ -n ${brew_command:-} ]]; then
	eval "$("$brew_command" shellenv)"
	brew_prefix=$("$brew_command" --prefix)

	# Prefer Homebrew LLVM when installed, without adding nonexistent paths.
	llvm_prefix=$("$brew_command" --prefix llvm 2>/dev/null)
	if [[ -d $llvm_prefix ]]; then
		path=("$llvm_prefix/bin" $path)
		export LDFLAGS="-L$llvm_prefix/lib -Wl,-rpath,$llvm_prefix/lib${LDFLAGS:+ $LDFLAGS}"
		export CPPFLAGS="-I$llvm_prefix/include -I$llvm_prefix/include/c++/v1${CPPFLAGS:+ $CPPFLAGS}"
	fi

	openjdk_prefix=$("$brew_command" --prefix openjdk 2>/dev/null)
	if [[ -d $openjdk_prefix ]]; then
		export JAVA_HOME="$openjdk_prefix/libexec/openjdk.jdk/Contents/Home"
		path=("$openjdk_prefix/bin" $path)
	fi

	chruby_prefix=$("$brew_command" --prefix chruby 2>/dev/null)
	if [[ -r $chruby_prefix/share/chruby/chruby.sh ]]; then
		source "$chruby_prefix/share/chruby/chruby.sh"
		source "$chruby_prefix/share/chruby/auto.sh"
	fi
fi

unset brew_command brew_prefix llvm_prefix openjdk_prefix chruby_prefix

# MacPorts, when installed.
[[ -d /opt/local/bin ]] && path=(/opt/local/bin $path)

# Locally installed Rubies, when present.
[[ -d $HOME/.rubies/ruby-3.3.0/bin ]] && path=("$HOME/.rubies/ruby-3.3.0/bin" $path)
