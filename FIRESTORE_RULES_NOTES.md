# Firestore Rules Notes (Production)

This project currently runs in Firestore test mode.
The file `firestore.rules` is a saved production baseline.

## Before enabling in production

1. Verify all write payloads contain `uid` for `*_synced` collections.
2. Confirm chat membership flow still works for:
   - room create
   - self-join member
   - owner/admin role updates
3. Validate these collections from app code:
   - `users/{uid}/notes`
   - `chat_rooms/*`
   - `sync_actions/*`
   - `*_synced/*`

## Recommended hardening after rollout

1. Remove transitional allowance in `*_synced` rule block:
   - Keep only `request.resource.data.uid == request.auth.uid`.
2. Add App Check enforcement at Firebase project level.
3. Add custom claims (`admin`) and move role trust from client to backend.
4. Add rules unit tests using Firebase Emulator Suite.

## Deployment commands (when needed)

```bash
firebase deploy --only firestore:rules
```

Or if your project aliases are configured:

```bash
firebase use <project-id>
firebase deploy --only firestore:rules
```
