# Firestore Rules Notes (Production)

This project currently runs in Firestore test mode.
The file `firestore.rules` is a saved production baseline.

## Before enabling in production

1. Verify all write payloads contain `uid` for user-scoped sync documents.
2. Confirm chat membership flow still works for:
   - room create
   - self-join member
   - owner/admin role updates
3. Validate these collections from app code:
   - `users/{uid}/notes`
   - `users/{uid}/finance_transactions`
   - `users/{uid}/study_tasks`
   - `users/{uid}/finance_recurring`
   - `users/{uid}/sync_outbox`
   - `users/{uid}/sync_entities`
   - `chat_rooms/*`

## Recommended hardening after rollout

1. Keep strict ownership checks in sync rules:
   - `request.resource.data.uid == request.auth.uid`.
   - `request.resource.data.entity` va `request.resource.data.entityId` ton tai voi `sync_entities`.
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
