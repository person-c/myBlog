#!/usr/bin/env sh

# Preview content with litedown::roam(): reuse a server that already covers the
# target, otherwise start one.  See CLAUDE.md, "Preview with litedown".
#
# Usage: scripts/preview.sh [file-or-dir]      (default: content/note)
# Exit status: 0 = a server covers the target (URL printed),
#              2 = a server is running for a directory that does not cover it.
#
# A ".html" next to the source wins over the source itself, because the .html is
# what the site publishes (hugo.toml ignores *.Rmd).  roam serves that file as
# is: <...>/x.html?preview=1 is the rendered page, while <...>/x.Rmd?preview=1
# is a fresh render of the source.

path=${1:-content/note}
if [ -d "$path" ]; then
  dir=$path
  file=
elif [ -f "$path" ]; then
  dir=$(dirname "$path")
  file=$(basename "$path")
else
  echo "no such file or directory: $path" >&2
  exit 1
fi

abs=$(cd "$dir" && { pwd -W 2>/dev/null || pwd; })
norm() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr '\\' '/'; }
target=$(norm "$abs")

case "$file" in
  *.Rmd|*.md|*.markdown)
    html="${file%.*}.html"
    [ -f "$dir/$html" ] && file=$html
    ;;
esac

for port in $(seq 4321 4330); do
  index=$(curl -s --connect-timeout 2 "http://127.0.0.1:$port/custom/litedown/" 2>/dev/null) || continue
  [ -n "$index" ] || continue
  served_raw=$(printf '%s' "$index" |
    sed -n 's|.*<div class="title"><h1><em>\(.*\):</em></h1></div>.*|\1|p' | head -1)
  served=$(norm "$served_raw")
  [ -n "$served" ] || continue
  case "$target" in
    "$served"|"$served"/*)
      base="http://127.0.0.1:$port/custom/litedown"
      echo "reusing litedown server on port $port"
      echo "  listing: $base/"
      if [ -n "$file" ]; then
        echo "  file:    $base${target#"$served"}/$file?preview=1"
      fi
      exit 0
      ;;
    *)
      echo "port $port serves $served_raw, which does not cover $abs" >&2
      echo "stop that server first, then run this script again" >&2
      exit 2
      ;;
  esac
done

echo "starting litedown::roam('$dir') ..." >&2
exec R -e "litedown::roam('$dir'); while(TRUE) Sys.sleep(1)"
