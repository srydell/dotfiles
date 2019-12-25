export PATH="/usr/lib/ccache/bin/:$PATH"
# Find the flags programmatically. Good for not blowing up your lesser machine :)
LFLAG=$(grep -c '^processor' /proc/cpuinfo)
((JFLAG=LFLAG+1))
export MAKEFLAGS="-j$JFLAG -l$LFLAG"
