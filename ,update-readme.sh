#!/bin/dash
# Rewrites the Usage section of README.md (everything after its "Usage" heading)
# from `my-otr --help`. Run it from anywhere after changing the help text.
# --help needs no config, and shows the home directory as "~": no path of this
# machine ends up in the published README.

D=$(cd "$(dirname "$0")" && pwd) || exit 1
T=$(mktemp -d /tmp/my-otr-readme.XXXXXX) || exit 1
trap 'rm -rf "$T"' EXIT INT TERM HUP

"$D/my-otr" --help > "$T/help" 2>&1 || { cat "$T/help" >&2; exit 1; }
[ -s "$T/help" ] || { echo "my-otr --help printed nothing" >&2; exit 1; }

awk '
  FILENAME == ARGV[1] { if (!done) print; if (prev == "Usage" && $0 == "-----") { print ""; done = 1 }; prev = $0; next }
  { print ($0 == "" ? "" : "    " $0) }
' "$D/README.md" "$T/help" > "$T/README.md" || exit 1
grep -q '^Usage$' "$T/README.md" || { echo "README.md has no 'Usage' heading" >&2; exit 1; }

mv -f "$T/README.md" "$D/README.md" && echo " >>> README.md: Usage section rewritten from my-otr --help"
