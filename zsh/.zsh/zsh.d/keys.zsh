# Keychain only handles the latest gpg key
# LATEST_GPGKEY=$(gpg --list-secret-keys --with-colons 2>/dev/null | awk -F: '($1 ~ "sec") { print $5 }' | tail -n 1)
# Control ssh-agent. Only handles keys listed here.
# To add a new key, add the name of the file after id_rsa if it is in ~/.ssh/
# or give an absolute path
# eval $(keychain --eval --quiet --ignore-missing --agents gpg,ssh id_rsa "$LATEST_GPGKEY")
eval $(keychain --eval  --quiet --ignore-missing --agents ssh --inherit any id_rsa)
# unset LATEST_GPGKEY

# Always prompt for gpg password in the terminal instead of gui popup
export GPG_TTY=$(tty)

unset DISPLAY

gpg-connect-agent updatestartuptty /bye > /dev/null
