#!/bin/bash
set -euo pipefail

# Reset all TCC permissions for VoidKit so permission prompts can be re-tested.
# Requires running with sudo (TCC database is protected by SIP on newer macOS,
# but the reset command is allowed).

BUNDLE_ID="com.secelead.voidkit"

echo "Resetting TCC permissions for $BUNDLE_ID..."

# Reset all TCC entries for the app
tccutil reset All "$BUNDLE_ID"

echo "Done. All TCC permissions for $BUNDLE_ID have been revoked."
echo ""
echo "You may also want to:"
echo "  1. Remove Full Disk Access manually in System Settings → Privacy & Security → Full Disk Access"
echo "  2. Relaunch VoidKit to re-trigger permission prompts"
