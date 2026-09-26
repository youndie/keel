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
# The documentation is not rewritten: it is REPLACED. keel's own documents describe keel, and a rename
# turns them into sentences that are false and look authoritative, which is what the relay's CLAUDE.md
# ended up with ("A GitHub template repository for..."). On the first run the script deletes them and
# installs `skeleton/`: a CLAUDE.md with the rules and no claims, a README, a backlog holding one seed
# item, and an empty coverage map. keel's history stays readable at https://github.com/youndie/keel.
#
# THE CHECK AT THE END IS THE POINT OF THIS SCRIPT. The rewrite is what B-09 did by hand in 32 files,
# and the hand-renamed relay still carries "keel" in renovate.json. The script ends with
# `git grep -il keel` over everything outside the allowlist and fails if anything is left, so an
# occurrence in a form the rules above do not know is a red exit here, not a Docker `COPY` that
# fails far from the rename.
set -euo pipefail

OLD_PACKAGE="io.github.youndie.keel"

# keel's documentation, deleted rather than rewritten when the skeleton is installed. `docs/templates/`
# is not on the list: it describes no project and the clone keeps it.
KEEL_DOCS=(CLAUDE.md README.md backlog.md docs/README.md docs/research docs/backlog docs/features
  docs/api docs/services)

# WHAT THE CHECK DOES NOT READ: this script, because it has to know the old name. Nothing else.
# A line elsewhere may still name the template, but only as an address, `https://github.com/youndie/keel...`:
# the check strips those before it looks, so "started from <link>" passes and "keel is ..." does not.
ALLOW=(scripts/rename.sh)

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
# The rewrite also leaves alone what the skeleton is about to replace, and the skeleton itself, whose
# placeholders are filled in when it is installed.
rewrite_exclude=("${exclude[@]}" ":(exclude)skeleton")
if [ -d skeleton ]; then
  for path in "${KEEL_DOCS[@]}"; do rewrite_exclude+=(":(exclude)$path"); done
fi

# ---- the rewrite ---------------------------------------------------------------------------------
old_dir=${OLD_PACKAGE//.//}
new_dir=${package//.//}

# Package directories first, so the file renames below find their files at the new address.
for root in $(git ls-files -- "${rewrite_exclude[@]}" | grep "/$old_dir/" | sed "s|/$old_dir/.*||" | sort -u); do
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
# The template's address is the one spelling that is NOT rewritten: a comment pointing at
# https://github.com/youndie/keel/... is a link to documentation the clone no longer carries, and
# rewriting it would point at a repository that does not exist. It is set aside first and put back.
RULES='
  my @kept; s{(https://github\.com/youndie/keel[^\s)>\]]*)}{push @kept, $1; "\0" . $#kept . "\0"}ge;
  s/\Q$ENV{OLD_PACKAGE}\E/$ENV{PACKAGE}/g;
  s/\Q$ENV{OLD_DIR}\E/$ENV{NEW_DIR}/g;
  s/KEEL/$ENV{UPPER}/g;
  s/Keel/$ENV{PASCAL}/g;
  s/keel(?=[A-Z])/$ENV{CAMEL}/g;
  s/keel/$ENV{NAME}/g;
  s{\0(\d+)\0}{$kept[$1]}g;
'

git ls-files -- "${rewrite_exclude[@]}" | grep -i 'keel[^/]*$' | while read -r file; do
  renamed="$(dirname "$file")/$(basename "$file" | perl -pe "$RULES")"
  # A spelling no rule knows leaves the name as it was; the check below names it.
  [ "$renamed" = "$file" ] || git mv "$file" "$renamed"
done

git grep -Il -i keel -- "${rewrite_exclude[@]}" | while read -r file; do
  perl -pi -e "$RULES" "$file"
done

# IMPORTS ARE SORTED AGAIN, because the package is part of what they are sorted by. keel's own
# `io.github.youndie.keel` sorts after `io.github.smyrgeorge`, a clone's `com.example.relay` sorts
# before it, and ktlint fails the build on the order: found by building a clone renamed that way.
# The layout is ktlint_official's: everything else, then java, javax, kotlin, then aliases.
git ls-files -- '*.kt' '*.kts' "${rewrite_exclude[@]}" | while read -r file; do
  perl -0777 -pi -e '
    sub group { my $i = shift; return 4 if $i =~ / as /; return 3 if $i =~ /^import kotlin\./;
      return 2 if $i =~ /^import javax\./; return 1 if $i =~ /^import java\./; return 0 }
    s{((?:^import [^\n]*\n)+)}{join "", sort { group($a) <=> group($b) or $a cmp $b } split /(?<=\n)/, $1}gme
  ' "$file"
done

# The repository is the one value that is not a spelling of the name: a clone called `relay` may
# live in `webhook-relay`, which the relay from B-09 does.
perl -pi -e "s|^sborka\\.repository=.*|sborka.repository=$repository|" gradle.properties

# ---- the documentation ---------------------------------------------------------------------------
# First run only: afterwards there is no `skeleton/`, and the documentation is the clone's own.
first_run=false
if [ -d skeleton ]; then
  first_run=true

  # A COMMENT CITING ONE OF KEEL'S ITEMS BECOMES ITS ADDRESS, and it has to happen now, while
  # `docs/backlog/` still says which file each number is. Left bare, "Found by B-08" names an item the
  # clone does not have, and "from B-01 onwards" names the clone's own seed item, which is false.
  items=$(git ls-files 'docs/backlog/B-*.md' | sed 's|.*/||' | tr '\n' ' ')
  git grep -l -E 'B-[0-9]{2}' -- "${rewrite_exclude[@]}" | while read -r file; do
    ITEMS=$items perl -pi -e '
      BEGIN { %item = map { /^(B-\d+)-/ ? ($1 => $_) : () } split " ", $ENV{ITEMS} }
      my @kept; s{(https://github\.com/youndie/keel[^\s)>\]"]*)}{push @kept, $1; "\0" . $#kept . "\0"}ge;
      s{\b(B-\d{2})\b}{exists $item{$1} ? "https://github.com/youndie/keel/blob/main/docs/backlog/$item{$1}" : $1}ge;
      s{\0(\d+)\0}{$kept[$1]}g;
    ' "$file"
  done

  # What the skeleton installs cites the clone's own items, B-01 first, so the check below skips it.
  installed=()
  while read -r file; do installed+=(":(exclude)${file#skeleton/}"); done < <(git ls-files skeleton)

  git rm -r -q --ignore-unmatch -- "${KEEL_DOCS[@]}"
  git ls-files skeleton | while read -r file; do
    target=${file#skeleton/}
    mkdir -p "$(dirname "$target")"
    git mv "$file" "$target"
    NAME=$name PREFIX=$upper PACKAGE=$package perl -pi -e '
      s/\{\{name\}\}/$ENV{NAME}/g; s/\{\{PREFIX\}\}/$ENV{PREFIX}/g; s/\{\{package\}\}/$ENV{PACKAGE}/g;
    ' "$target"
  done
  rm -rf skeleton
fi

# ---- the check -----------------------------------------------------------------------------------
# A placeholder nobody filled is a sentence the clone did not write, so it counts as a leftover too.
left=$(git grep -n -i -e keel -e '{{[A-Za-z]*}}' -- "${exclude[@]}" |
  perl -ne '($loc, $text) = /^([^:]+:\d+):(.*)$/ or next;
    $text =~ s{https://github\.com/youndie/keel[^\s)>\]]*}{}g;
    print "  $loc: $text\n" if $text =~ /keel|\{\{[A-Za-z]*\}\}/i' || true)
named=$(git ls-files -- "${exclude[@]}" | grep -i keel || true)
# On the first run only: afterwards the clone cites its own items, and that is what they are for.
if $first_run; then
  cited=$(git grep -n -E 'B-[0-9]{2}' -- "${exclude[@]}" "${installed[@]}" |
    perl -ne '($loc, $text) = /^([^:]+:\d+):(.*)$/ or next;
      $text =~ s{https://github\.com/youndie/keel[^\s)>\]"]*}{}g;
      print "  $loc: $text  (a template item, cited by number)\n" if $text =~ /\bB-\d{2}\b/' || true)
  left="$left${left:+${cited:+$'\n'}}$cited"
fi
if [ -n "$left$named" ]; then
  echo "rename: the template is still named here, outside the allowlist:" >&2
  [ -z "$left" ] || printf '%s\n' "$left" >&2
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
no 'keel' left outside ${ALLOW[*]}, except as the template's address
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
