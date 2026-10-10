#!/usr/bin/env sh

# Find or remove review annotations in content files.
#
# Usage:
#   scripts/clear-review-notes.sh --published [path ...]  # .md only -- the ones the site publishes (exit 1 if any)
#   scripts/clear-review-notes.sh --check     [path ...]  # every file that carries annotations (exit 1 if any)
#   scripts/clear-review-notes.sh             [path ...]  # remove the blocks, in place
#
# Default path is content/.
#
# Why .md is the one that matters: Hugo renders .md with
# markup.goldmark.renderer.unsafe = true, so a committed annotation is a
# *published* annotation.  litedown drops raw HTML when it renders .Rmd ->
# .html, so annotations in an .Rmd never reach the site -- they only clutter the
# source (and they carry the litedown math problem, see CLAUDE.md).
#
# An annotation is a <div> whose opening tag carries class="review-note" or the
# palette signature of the review templates (border-left: 4px solid #<palette>).
# See .claude/skills/review-article/SKILL.md.
#
# Caveat: an annotation must not contain a nested <div>, or the removal stops at
# the inner </div> -- keep quoted HTML inside fenced code blocks instead.

mode=remove
case "$1" in
  --check)     mode=check; shift ;;
  --published) mode=published; shift ;;
esac
[ $# -gt 0 ] || set -- content

# NB: the '/' in <\/div> is escaped so the pattern can be interpolated into a
# perl s/// expression without terminating it early.
pattern='<div[^>]*(?:class="review-note"|border-left: 4px solid #(?:e53e3e|dd6b20|3182ce|38a169|805ad5|2b6cb0))[^>]*>.*?<\/div>[ \t]*\n?'
# count with an explicit loop: the `() = //g` idiom returns capture groups, not
# matches, and starts undefined (printing nothing) when there is no match
count() { perl -0777 -ne "\$c = 0; \$c++ while /$pattern/gs; print \$c" "$1"; }

files=$(find "$@" -type f \( -name '*.md' -o -name '*.Rmd' -o -name '*.html' \) 2>/dev/null | sort)
[ -n "$files" ] || { echo "no .md/.Rmd/.html files under: $*" >&2; exit 1; }

if [ "$mode" = published ]; then
  found=0
  for f in $(printf '%s\n' "$files" | grep '[.]md$'); do
    n=$(count "$f")
    [ "$n" -gt 0 ] && { printf '%s: %s published annotation block(s)\n' "$f" "$n"; found=$((found + n)); }
  done
  if [ "$found" -gt 0 ]; then
    echo ""
    echo "$found annotation block(s) in .md files: Hugo renders these with unsafe = true,"
    echo "so they are live on the site.  Remove them with:"
    echo "  scripts/clear-review-notes.sh content"
    exit 1
  fi
  echo "no annotations in .md files"
  exit 0
fi

if [ "$mode" = check ]; then
  found=0
  for f in $files; do
    n=$(count "$f")
    [ "$n" -gt 0 ] && { printf '%s: %s annotation block(s)\n' "$f" "$n"; found=$((found + n)); }
  done
  if [ "$found" -gt 0 ]; then
    echo ""
    echo "$found annotation block(s) still in the tree.  Remove them with:"
    echo "  scripts/clear-review-notes.sh content"
    exit 1
  fi
  echo "no review annotations found"
  exit 0
fi

removed=0
for f in $files; do
  n=$(count "$f")
  [ "$n" -gt 0 ] || continue
  perl -0777 -i -pe "s/$pattern//gs" "$f"
  printf '%s: removed %s block(s)\n' "$f" "$n"
  removed=$((removed + n))
done
echo "removed $removed annotation block(s)"
