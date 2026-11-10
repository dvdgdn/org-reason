#!/bin/sh
# Builds ~/Applications/Org Protocol.app from handler.applescript and registers
# it with macOS as the handler for org-protocol:// URLs. Safe to re-run.
#
# It uses the emacsclient of /Applications/Emacs.app; name another one with
#   EMACSCLIENT=/path/to/emacsclient ./install.sh
set -eu

here=$(cd "$(dirname "$0")" && pwd)
client=${EMACSCLIENT:-/Applications/Emacs.app/Contents/MacOS/bin/emacsclient}
app="$HOME/Applications/Org Protocol.app"
plist="$app/Contents/Info.plist"
buddy=/usr/libexec/PlistBuddy
lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

[ -x "$client" ] || { echo "emacsclient not found at $client; set EMACSCLIENT" >&2; exit 1; }

source=$(mktemp -t org-protocol).applescript
trap 'rm -f "$source"' EXIT
sed "s|^property emacsclient : .*|property emacsclient : \"$client\"|" "$here/handler.applescript" > "$source"

mkdir -p "$HOME/Applications"
rm -rf "$app"
osacompile -o "$app" "$source"

"$buddy" -c 'Set :CFBundleIdentifier local.org-protocol-handler' "$plist" 2>/dev/null ||
  "$buddy" -c 'Add :CFBundleIdentifier string local.org-protocol-handler' "$plist"
"$buddy" -c 'Add :LSUIElement bool true' \
         -c 'Add :CFBundleURLTypes array' \
         -c 'Add :CFBundleURLTypes:0 dict' \
         -c 'Add :CFBundleURLTypes:0:CFBundleURLName string org-protocol' \
         -c 'Add :CFBundleURLTypes:0:CFBundleURLSchemes array' \
         -c 'Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string org-protocol' \
         "$plist"

# Editing Info.plist invalidates osacompile's ad-hoc signature; re-sign.
codesign --force --deep --sign - "$app"
"$lsregister" -f "$app"
echo "Installed $app (emacsclient: $client)"
