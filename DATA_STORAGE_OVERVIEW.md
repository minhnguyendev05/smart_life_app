# Tong Quan Luu Tru Du Lieu - SmartLife

Tai lieu nay tong hop du lieu dang duoc luu o dau (local/cloud/in-memory) de ban de quyet dinh huong dieu chinh.

Neu can tai lieu de xuat toi uu kien truc local-first + Firestore user-scoped, xem them file:
- `DATA_STORAGE_OPTIMIZATION_PLAN.md`

## 1) Kien truc luu tru hien tai

- Local key-value: Hive qua `LocalStorageService` (1 box: `smart_life_box`).
- Local relational: SQLite qua `StudySqliteService` (table `study_tasks`).
- Cloud backend: Firebase Auth + Cloud Firestore.
- Runtime only: mot so state chi nam trong RAM, reset khi app restart.

## 2) Bang nhanh theo module

| Module | Local (Hive) | SQLite | Cloud | Ghi chu |
|---|---|---|---|---|
| Finance | `u:{uid}:finance_transactions:v2`, `u:{uid}:finance_custom_categories:v2`, `u:{uid}:finance_recurring_transactions:v2`, `u:{uid}:finance_settings:v2` | - | `users/{uid}/finance_categories`, `users/{uid}/finance_transactions`, `users/{uid}/finance_recurring`, `users/{uid}/finance_settings/main` | `monthlyBudget` da duoc persist local + cloud |
| Moni Chat tab | `u:{uid}:moni_chat_history_v1:v1` | - | - | Lich su chat Moni luu local |
| Notes | `u:{uid}:note_items:v2` | - | `users/{uid}/notes` | Co dong bo cloud 2 chieu |
| Study | `u:{uid}:study_tasks:v2` (cache) | `smartlife_{uid}.db` + table `study_tasks` | `users/{uid}/study_tasks` | SQLite da tach theo user |
| Notification model | `u:{uid}:behavior_model_v1:v2` | - | - | Luu trong so hanh vi/feedback thong bao |
| Sync queue | `u:{uid}:sync_queue_v2:v2`, `u:{uid}:sync_conflicts_v2:v2`, `u:{uid}:sync_merge_policy_v2:v2` | - | `users/{uid}/sync_outbox`, `users/{uid}/sync_entities` | Hang doi dong bo + conflict |
| User profile cache | `app_users_cache_v1` | - | `app_users` | FCM token luu trong `app_users` |
| Community Chat | - | - | `chat_rooms/*` + subcollections | Khong co cache local message |

## 3) Chi tiet key local (Hive)

### 3.1 Box
- Box duy nhat: `smart_life_box`.

### 3.2 Cac key dang dung
- Pattern namespace cho du lieu user: `u:{uid}:{base_key}:{version}`.
- `u:{uid}:finance_transactions:v2`: danh sach giao dich tai chinh.
- `u:{uid}:finance_custom_categories:v2`: danh muc custom finance.
- `u:{uid}:finance_recurring_transactions:v2`: giao dich dinh ky.
- `u:{uid}:finance_settings:v2`: thiet lap finance (bao gom `monthlyBudget`).
- `u:{uid}:note_items:v2`: ghi chu.
- `u:{uid}:study_tasks:v2`: cache task hoc tap.
- `u:{uid}:behavior_model_v1:v2`: model hanh vi thong bao (weights + epoch + lastTrainingAt).
- `u:{uid}:sync_queue_v2:v2`: danh sach action chua sync/xu ly sync.
- `u:{uid}:sync_conflicts_v2:v2`: xung dot sync.
- `u:{uid}:sync_merge_policy_v2:v2`: policy merge theo entity.
- `app_users_cache_v1`: cache ho so user app (global cache).
- `u:{uid}:moni_chat_history_v1:v1`: lich su chat Moni (user/assistant + timestamp).

## 4) SQLite (Study)

Table: `study_tasks`

Columns:
- `id` (TEXT, PK)
- `title` (TEXT)
- `subject` (TEXT)
- `deadline` (TEXT ISO)
- `status` (TEXT)
- `estimated_minutes` (INTEGER)
- `recurrence` (TEXT)
- `reminder_minutes_before` (INTEGER, nullable)

Ghi chu:
- Tren Android/iOS/macOS, Study uu tien doc SQLite theo DB user (`smartlife_{uid}.db`).
- Hive key `u:{uid}:study_tasks:v2` dong vai tro cache/fallback.

## 5) Firestore dang su dung

### 5.1 Auth/User
- Firebase Auth: account dang nhap.
- Collection `app_users/{uid}`: profile + metadata (`displayName`, `email`, `avatarUrl`, `fcmTokens`, ...).

### 5.2 Notes
- `users/{uid}/notes/{noteId}`

Fields chinh:
- `title`, `content`, `updatedAt`, `imagePath`, `pdfPath`

### 5.3 Finance categories
- `users/{uid}/finance_categories/{categoryId}`

Fields chinh:
- du lieu category + `syncedAt`

### 5.4 Community Chat
- `chat_rooms/{roomId}`
- `chat_rooms/{roomId}/members/{userId}`
- `chat_rooms/{roomId}/messages/{messageId}`
- `chat_rooms/{roomId}/meta/typing`

### 5.5 Generic sync pipeline
- `users/{uid}/sync_outbox/{actionId}`
- `users/{uid}/finance_transactions/{entityId}`
- `users/{uid}/study_tasks/{entityId}`
- `users/{uid}/finance_recurring/{entityId}`
- `users/{uid}/sync_entities/{actionId}` (nhat ky/audit cho entity khong map truc tiep)

## 6) Du lieu runtime (chua persist day du)

- ChatProvider khong cache message local; phu thuoc stream Firestore.
- Mot so state UI (tab/filter/expanded state) chi ton tai trong session.

## 7) Diem can luu y khi dieu chinh

1. Neu can ho tro offline manh hon cho chat: can bo sung local cache cho Community Chat (theo room/page).
2. `monthlyBudget` da duoc persist local + cloud; buoc tiep theo nen bo sung migration tu key cu neu can.
3. Neu can audit sync ro rang: nen chuan hoa schema payload theo tung entity trong `users/{uid}/sync_outbox`.
4. Neu can tao bao cao he thong luu tru: co the bo sung versioning cho tung key (`*_v2`, `*_v3`) va migration script.
5. Moni chat hien dang local-only; neu can da thiet bi thi can cloud sync lich su chat.

## 8) De xuat buoc tiep theo (thuc dung)

- Buoc 1: Chot danh sach du lieu phai dong bo da thiet bi (budget, Moni chat, study task).
- Buoc 2: Chot schema Firestore cho cac phan con thieu.
- Buoc 3: Them migration key local + rollback plan.
- Buoc 4: Viet test cho read/write va migration.
