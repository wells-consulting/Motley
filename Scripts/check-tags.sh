#!/bin/bash
#
# check-tags.sh
#
# Compares every local tag with the one on the remote, by commit.
#
# SwiftPM remembers the revision it first saw for each version, so a tag that
# points somewhere new is a resolve failure on every machine that already
# resolved the old one. That error only appears later, on someone else's
# checkout. This finds it here.
#
# Usage:
#   check-tags.sh              Compares with github
#   check-tags.sh <remote>     Compares with any remote
#
# The exit status is 1 when a tag has moved.

set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 1

remote=${1:-github}

tmp=$(mktemp -d "${TMPDIR:-/tmp}/check-tags.XXXXXX") || exit 1
trap 'rm -rf "$tmp"' EXIT

if ! git ls-remote --tags "$remote" >"$tmp/remote"; then
    echo "check-tags: couldn't read the tags on $remote" >&2
    exit 1
fi

# The commit each published tag points at. An annotated tag lists its commit
# on its own "^{}" line, which comes after the tag object's line.
awk '
    {
        oid = $1
        ref = $2
        if (ref ~ /\^\{\}$/) {
            sub(/\^\{\}$/, "", ref)
            commit[ref] = oid
        } else if (!(ref in commit)) {
            commit[ref] = oid
        }
    }
    END { for (ref in commit) print ref, commit[ref] }
' "$tmp/remote" >"$tmp/published"

# The commit each local tag points at; *objectname is the target of a tag
# object, and empty for a lightweight tag.
git for-each-ref refs/tags \
    --format='%(refname) %(refname:short) %(objectname) %(*objectname)' |
    awk '{ print $1, $2, ($4 != "" ? $4 : $3) }' | sort -V >"$tmp/local"

awk -v remote="$remote" '
    NR == FNR {
        published[$1] = $2
        next
    }
    {
        ref = $1
        tag = $2
        commit = $3
        if (!(ref in published)) {
            printf "%-14s not on %s\n", tag, remote
            missing++
            next
        }
        if (published[ref] == commit) {
            printf "%-14s ok\n", tag
            next
        }
        printf "%-14s moved: local %s, %s %s\n", tag, substr(commit, 1, 7), remote, substr(published[ref], 1, 7)
        moved++
    }
    END {
        if (moved > 0) {
            print ""
            print moved " tag(s) moved. Apps that resolved the old one cannot resolve this one."
            print "Cut a new version instead of reusing the tag."
            exit 1
        }
        if (missing > 0) {
            print ""
            print missing " tag(s) are local only, which is fine until you push them."
        }
    }
' "$tmp/published" "$tmp/local"
