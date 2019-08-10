# title: git clone from pasteboard
# ifPasteboard: .git
# ifDirectory: true

REPO=$(pbpaste)
git clone $REPO
