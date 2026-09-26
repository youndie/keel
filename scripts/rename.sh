#!/usr/bin/env bash
# Renames a clone of keel: scripts/rename.sh <name> [<package>]
#
#   scripts/rename.sh relay
#   scripts/rename.sh webhook-relay com.example.relay
#
# <name> is lower-case, words joined by hyphens. Every spelling of "keel" outside the allowlist below
# is rewritten into the form its context needs:
#
#   io.github.youndie.keel   ->  <package>        package and group; the directories move too
#   KEEL                     ->  WEBHOOK_RELAY    the configuration prefix, so every KEEL_* variable
#   Keel                     ->  WebhookRelay     types and file names: KeelConfig.kt -> WebhookRelayConfig.kt
#   keelX                    ->  webhookRelayX    functions: keelMain, keelModule
#   keel                     ->  webhook-relay    everything else: the binary, the Docker paths,
#                                                 rootProject.name, the Gradle property, the database file
#
# <package> defaults to io.github.<owner>.<name without hyphens>, where <owner> comes from the
# `origin` remote when it is a GitHub repository other than keel itself, and is `youndie` otherwise.
#
# THE CHECK AT THE END IS THE POINT OF THIS SCRIPT. The rewrite is what B-09 did by hand in 32 files,
# and the hand-renamed relay still carries "keel" in renovate.json. The script ends with
# `git grep -il keel` over everything outside the allowlist and fails if anything is left, so an
# occurrence in a form the rules above do not know is a red exit here, not a Docker `COPY` that
# fails far from the rename.
set -euo pipefail

OLD_PACKAGE="io.github.youndie.keel"

# WHAT THE CHECK DOES NOT READ, AND WHY EACH LINE IS HERE.
#
# - this script, because it has to know the old name;
# - keel's own documentation, because it describes keel. Rewriting its prose produces sentences that
#   are false and look authoritative, which is what the relay's CLAUDE.md ended up with (#39). Until
#   #39 separates what keel is from what a clone gets, these files are left exactly as they are.
ALLOW=(
  scripts/rename.sh
  CLAUDE.md
  README.md
  backlog.md
  docs
)

die() { printf 'rename: %s\n' "$*" >&2; exit 2; }

[ $# -ge 1 ] && [ $# -le 2 ] || die "usage: scripts/rename.sh <name> [<package>]"
name=$1
[[ $name =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]] ||
  die "'$name' is not a lower-case name with hyphens between words, like 'relay' or 'webhook-relay'"
# A name containing the old one would pass through the rewrite and then fail the check for a reason
# that has nothing to do with a missed occurrence.
[[ $name != *keel* ]] || die "'$name' contains 'keel'; the check at the end could not tell it from a leftover"

cd "$(git rev-parse --show-toplevel)" || die "not inside a git repository"

ident=${name//-/}
upper=$(printf '%s' "$name" | tr 'a-z-' 'A-Z_')
pascal=$(printf '%s' "$name" | perl -pe 's/(^|-)([a-z])/\u$2/g')
camel=$(printf '%s' "$pascal" | perl -pe 's/^([A-Z])/\l$1/')

owner=youndie
repository="youndie/$name"
if remote=$(git remote get-url origin 2>/dev/null) &&
  [[ $remote =~ github\.com[:/]([^/]+)/([^/]+)$ ]] &&
  [[ ${BASH_REMATCH[2]%.git} != keel ]]; then
  owner=${BASH_REMATCH[1]}
  repository="$owner/${BASH_REMATCH[2]%.git}"
fi
package=${2:-io.github.$(printf '%s' "$owner" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_').$ident}
[[ $package =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]] || die "'$package' is not a package name"

exclude=()
for path in "${ALLOW[@]}"; do exclude+=(":(exclude)$path"); done

# ---- the rewrite ---------------------------------------------------------------------------------
old_dir=${OLD_PACKAGE//.//}
new_dir=${package//.//}

# Package directories first, so the file renames below find their files at the new address.
for root in $(git ls-files -- "${exclude[@]}" | grep "/$old_dir/" | sed "s|/$old_dir/.*||" | sort -u); do
  mkdir -p "$(dirname "$root/$new_dir")"
  git mv "$root/$old_dir" "$root/$new_dir"
  # git tracks no directories, so `io/github/youndie` stays behind empty when the package moves away.
  find "$root" -type d -empty -delete
done

# The order is the rule: the package before the bare word it contains, the two capitalised forms
# before the lower-case one, and the camel form (keel followed by a capital) before the plain one.
# File names go through the same rules as contents, so `KeelConfig.kt` and a `keel.js` both move.
export OLD_PACKAGE OLD_DIR=$old_dir PACKAGE=$package NEW_DIR=$new_dir \
  UPPER=$upper PASCAL=$pascal CAMEL=$camel NAME=$name
# shellcheck disable=SC2016 # perl reads $ENV{...}; the shell must not expand it
RULES='
  s/\Q$ENV{OLD_PACKAGE}\E/$ENV{PACKAGE}/g;
  s/\Q$ENV{OLD_DIR}\E/$ENV{NEW_DIR}/g;
  s/KEEL/$ENV{UPPER}/g;
  s/Keel/$ENV{PASCAL}/g;
  s/keel(?=[A-Z])/$ENV{CAMEL}/g;
  s/keel/$ENV{NAME}/g;
'

git ls-files -- "${exclude[@]}" | grep -i 'keel[^/]*$' | while read -r file; do
  renamed="$(dirname "$file")/$(basename "$file" | perl -pe "$RULES")"
  # A spelling no rule knows leaves the name as it was; the check below names it.
  [ "$renamed" = "$file" ] || git mv "$file" "$renamed"
done

git grep -Il -i keel -- "${exclude[@]}" | while read -r file; do
  perl -pi -e "$RULES" "$file"
done

# IMPORTS ARE SORTED AGAIN, because the package is part of what they are sorted by. keel's own
# `io.github.youndie.keel` sorts after `io.github.smyrgeorge`, a clone's `com.example.relay` sorts
# before it, and ktlint fails the build on the order: found by building a clone renamed that way.
# The layout is ktlint_official's: everything else, then java, javax, kotlin, then aliases.
git ls-files -- '*.kt' '*.kts' "${exclude[@]}" | while read -r file; do
  perl -0777 -pi -e '
    sub group { my $i = shift; return 4 if $i =~ / as /; return 3 if $i =~ /^import kotlin\./;
      return 2 if $i =~ /^import javax\./; return 1 if $i =~ /^import java\./; return 0 }
    s{((?:^import [^\n]*\n)+)}{join "", sort { group($a) <=> group($b) or $a cmp $b } split /(?<=\n)/, $1}gme
  ' "$file"
done

# The repository is the one value that is not a spelling of the name: a clone called `relay` may
# live in `webhook-relay`, which the relay from B-09 does.
perl -pi -e "s|^sborka\\.repository=.*|sborka.repository=$repository|" gradle.properties

# ---- the check -----------------------------------------------------------------------------------
left=$(git grep -il keel -- "${exclude[@]}" || true)
named=$(git ls-files -- "${exclude[@]}" | grep -i keel || true)
if [ -n "$left$named" ]; then
  echo "rename: 'keel' is still here, outside the allowlist:" >&2
  [ -z "$left" ] || git grep -n -i keel -- "${exclude[@]}" >&2 || true
  [ -z "$named" ] || printf '%s\n' "$named" | sed 's/^/  file name: /' >&2
  exit 1
fi

cat <<EOF
renamed keel -> $name
  package        $package
  config prefix  ${upper}_*
  types          ${pascal}Config, ${pascal}Settings, ${camel}Module
  binary         $name   (server/build/native-image/$name, /app/$name in the image)
  repository     $repository   (gradle.properties: sborka.repository)
no 'keel' left outside: ${ALLOW[*]}
EOF

# A LONGER NAME MAKES LONGER LINES, and ktlint fails the build past 120 columns. keel's own lines
# have a few characters of headroom, so `demo` fits and `webhook-relay` did not, in a test where one
# line spells the name twice. This script does not reformat Kotlin; ktlint does, and every rule it
# broke on that clone was one `ktlintFormat` corrects.
long=$(git ls-files -- '*.kt' '*.kts' "${exclude[@]}" | xargs awk 'length > 120 { print FILENAME ":" FNR }')
if [ -n "$long" ]; then
  echo
  echo "lines past 120 columns now, which ktlint will refuse:"
  printf '%s\n' "$long" | sed 's/^/  /'
  echo "next: ./gradlew ktlintFormat"
fi
