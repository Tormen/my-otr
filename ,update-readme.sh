#!/bin/dash
# Rewrites the Usage section of README.md (everything after its "Usage" heading)
# from `my-otr --help`. Run it from anywhere after changing the usage text.
#
# --help needs a config, so it gets a throwaway one with placeholder values:
# no credential and no path of this machine ends up in the published README.

D=$(cd "$(dirname "$0")" && pwd) || exit 1
T=$(mktemp -d /tmp/my-otr-readme.XXXXXX) || exit 1
trap 'rm -rf "$T"' EXIT INT TERM HUP

cat > "$T/my-otr.conf" <<'EOF'
DATENKELLER_LOGIN=x; DATENKELLER_PASSW=x; DATENKELLER_APIKEY=x; OTR_LOGIN=x; OTR_PASSW=x
LOGFILE='~/.my-otr.log'
EOF

HOME=/nonexistent "$D/my-otr" --conf "$T/my-otr.conf" --help > "$T/help" 2>&1 || { cat "$T/help" >&2; exit 1; }
[ -s "$T/help" ] || { echo "my-otr --help printed nothing" >&2; exit 1; }

# --conf shows the throwaway file and DEFAULT_CONF_FILE ($HOME/.my-otr.conf), usage shows $0: all read as documented
awk -v tmp="$T/my-otr.conf" -v self="$D/my-otr" '
  NR == FNR { if (!done) print; if (prev == "Usage" && $0 == "-----") { print ""; done = 1 }; prev = $0; next }
  { gsub(tmp, "~/.my-otr.conf"); gsub(self, "my-otr"); gsub("/nonexistent/.my-otr.conf", "~/.my-otr.conf"); print "    " $0 }
' "$D/README.md" "$T/help" > "$T/README.md" || exit 1
grep -q '^Usage$' "$T/README.md" || { echo "README.md has no 'Usage' heading" >&2; exit 1; }

mv -f "$T/README.md" "$D/README.md" && echo " >>> README.md: Usage section rewritten from my-otr --help"
