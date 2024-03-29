# Let brew programs come first
export PATH="/usr/local/sbin:$PATH"
export PATH="/opt/local/bin:$PATH"

# Use llvm clang
export PATH="/usr/local/opt/llvm/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/llvm/lib -Wl,-rpath,/usr/local/opt/llvm/lib"
export CPPFLAGS="-I/usr/local/opt/llvm/include -I/usr/local/opt/llvm/include/c++/v1/"

# Use the real gcc
export PATH="/usr/local/bin:$PATH"

# Use LLVM clangd etc
export PATH="/opt/homebrew/Cellar/llvm/16.0.6/bin:$PATH"

export PATH="/opt/homebrew/opt/conan@1/bin:$PATH"

# Brew related env
eval "$(/opt/homebrew/bin/brew shellenv)"
