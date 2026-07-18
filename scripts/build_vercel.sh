#!/usr/bin/env bash

set -euo pipefail

: "${SUPABASE_URL:?Configure SUPABASE_URL in the Vercel project}"
: "${SUPABASE_ANON_KEY:?Configure SUPABASE_ANON_KEY in the Vercel project}"

admin_email="${ADMIN_EMAIL:-allansakai@gmail.com}"

flutter pub get
flutter build web --release \
  --no-wasm-dry-run \
  --dart-define="SUPABASE_URL=${SUPABASE_URL}" \
  --dart-define="SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}" \
  --dart-define="ADMIN_EMAIL=${admin_email}"
