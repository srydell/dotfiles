# Let brew programs come first
export PATH="/usr/local/sbin:$PATH"
export PATH="/opt/local/bin:$PATH"

# Use llvm clang
export PATH="/usr/local/opt/llvm/bin:$PATH"

# Use the real gcc
export PATH="/usr/local/bin:$PATH"

# Use LLVM clangd etc
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib -Wl,-rpath,/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include -I/opt/homebrew/opt/llvm/include/c++/v1/"

export PATH="/opt/homebrew/opt/conan@1/bin:$PATH"

# Brew related env
eval "$(/opt/homebrew/bin/brew shellenv)"
