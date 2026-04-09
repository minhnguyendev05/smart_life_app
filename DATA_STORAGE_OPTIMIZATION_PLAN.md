# DATA STORAGE OPTIMIZATION PLAN - SMART LIFE

Tai lieu nay de xuat phuong an toi uu toan bo he thong luu tru du lieu theo huong local-first + Firestore user-scoped.

## 1) Muc tieu

- Khong tron du lieu giua cac user.
- Local-first: app van dung duoc khi offline, dong bo lai khi online.
- Cung mot mau sync cho tat ca module (finance, notes, study, chat, profile).
- Co lo trinh migrate an toan, co rollback.

## 2) Van de hien tai (xac nhan)

- Dang ton tai collection root-level dang *finance_synced, notes_synced, study_synced*.
- Cloud sync chua bat buoc uid trong payload.
- Nhieu du lieu quan trong chua cloud sync day du (finance transactions, study).
- Local key hien tai chua namespace theo user, de bi lon du lieu neu logout/login nhieu tai khoan tren cung thiet bi.
- Mot so state quan trong dang RAM-only (monthlyBudget).

## 3) Nguyen tac kien truc moi

1. Firestore chi duoc phep user-scoped cho du lieu ca nhan.
2. Local key phai namespace theo uid.
3. Moi entity co metadata sync thong nhat:
- id
- localUpdatedAt
- serverUpdatedAt
- syncStatus: queued | syncing | synced | failed | conflict
- isDeleted (soft delete)
4. Tat ca ghi cloud di qua outbox queue (idempotent theo actionId).
5. Rule bat buoc ownership theo uid, khong con transitional allow.

## 4) Firestore target schema (de xuat)

### 4.1 User-scoped data

- users/{uid}/profile/main
- users/{uid}/finance_transactions/{txId}
- users/{uid}/finance_categories/{categoryId}
- users/{uid}/finance_recurring/{recurringId}
- users/{uid}/finance_settings/main
- users/{uid}/notes/{noteId}
- users/{uid}/study_tasks/{taskId}
- users/{uid}/moni_messages/{messageId}
- users/{uid}/chat_room_refs/{roomId}
- users/{uid}/sync_outbox/{actionId}
- users/{uid}/sync_conflicts/{conflictId}
- users/{uid}/sync_entities/{actionId}

### 4.2 Shared/global only where truly needed

- chat_rooms/{roomId}
- chat_rooms/{roomId}/members/{uid}
- chat_rooms/{roomId}/messages/{messageId}
- chat_rooms/{roomId}/meta/typing

Ghi chu:
- chat_rooms la global collaboration object, nhung room refs va read-state nen co them ban sao user-scoped de query nhanh.

## 5) Local-first target (Hive + SQLite)

## 5.1 Hive key namespace theo user

Khuyen nghi format key:
- u:{uid}:finance:transactions:v2
- u:{uid}:finance:categories:v2
- u:{uid}:finance:recurring:v2
- u:{uid}:finance:settings:v2
- u:{uid}:notes:items:v2
- u:{uid}:study:tasks_cache:v2
- u:{uid}:chat:room:{roomId}:messages:v1
- u:{uid}:moni:messages:v1
- u:{uid}:sync:outbox:v2
- u:{uid}:sync:conflicts:v2
- u:{uid}:sync:merge_policy:v2

## 5.2 SQLite (Study)

- Lua chon A (de lam): them cot uid vao bang study_tasks, query theo uid.
- Lua chon B (sach hon): tach DB theo user, vi du study_{uid}.db.

Khuyen nghi chon B neu app ho tro doi tai khoan thuong xuyen tren cung thiet bi.

## 6) Sync architecture thong nhat (outbox pattern)

## 6.1 Luong ghi

1. UI ghi local truoc (Hive/SQLite).
2. Tao action vao outbox local voi actionId duy nhat.
3. Worker dong bo outbox len users/{uid}/sync_outbox/{actionId}.
4. Worker apply payload vao document dich user-scoped.
5. Danh dau synced va cap nhat serverUpdatedAt.

## 6.2 Conflict strategy

- Mac dinh: Last write wins theo localUpdatedAt.
- Finance transaction: uu tien id bat bien + upsert, tranh merge sai amount/type.
- Notes: cho phep merge text theo field-level neu can.
- Study task status: merge theo field + updatedAt.

## 6.3 Retry strategy

- Exponential backoff: 2s, 5s, 15s, 30s, 60s.
- Gioi han retryCount, qua nguong thi chuyen conflict/failure bucket.

## 7) Firestore rules muc tieu

- Tat ca users/{uid}/...: chi owner uid duoc read/write.
- Khong chap nhan document thieu uid trong create/update.
- users/{uid}/sync_outbox va users/{uid}/sync_conflicts chi owner truy cap.
- users/{uid}/sync_entities chi dung de audit payload sync.
- chat_rooms read/write dua tren membership (members/{uid}).

## 8) Mapping migrate tu schema cu

- finance_synced/{doc} -> users/{uid}/finance_transactions/{doc}
- study_synced/{doc} -> users/{uid}/study_tasks/{doc}
- sync_actions/{actionId} -> users/{uid}/sync_outbox/{actionId}
- notes_synced/{doc} -> users/{uid}/sync_entities/{actionId} (audit)

Neu doc cu khong co uid ro rang:
- dua vao collection quarantine: migration_quarantine/{docId}
- cho review thu cong, khong auto gan uid de tranh sai ownership.

## 9) Lo trinh trien khai an toan

### Phase 0 - Chuan bi
- Them feature flags cho dual-write va read-source.
- Bo sung index can thiet cho schema moi.

### Phase 1 - Dual write
- Van doc schema cu, nhung ghi dong thoi schema cu + schema moi.
- Bo sung uid bat buoc tren payload moi.

### Phase 2 - Backfill
- Chay script migrate cloud: doc cu -> ghi users/{uid}/... moi theo schema dich.
- Chay migrate local key: key cu -> key moi co uid namespace.

### Phase 3 - Read switch
- Chuyen read path sang schema moi theo tung module.
- Theo doi metrics loi, conflict, do tre sync.

### Phase 4 - Cleanup
- Tat ghi schema cu.
- Xoa collection cu sau khi on dinh 2-4 tuan.

## 10) Uu tien thuc thi (top impact)

1. Bat buoc uid trong cloud sync payload va write path user-scoped.
2. Chuyen finance transactions sang users/{uid}/finance_transactions.
3. Persist monthlyBudget vao local + cloud.
4. Chuyen sync_actions va du lieu projection sang users/{uid}/sync_outbox + users/{uid}/sync_entities.
5. Namespace toan bo key local theo uid.
6. Them local cache cho community chat theo room.
7. Dong bo day du study task qua users/{uid}/study_tasks.
8. Viet migration + rollback playbook.
9. Bo sung Firestore rules tests tren emulator.
10. Dat dashboard monitor: sync success rate, conflict rate, migration coverage.

## 11) Quy uoc implementation de tranh loi lap lai

- Khong tao them collection root-level moi cho du lieu user ca nhan.
- Moi service cloud phai nhan uid tu Auth tai thoi diem write.
- Moi provider local phai clear cache dung uid khi logout.
- Moi schema moi phai co version suffix trong local keys (v2, v3).

