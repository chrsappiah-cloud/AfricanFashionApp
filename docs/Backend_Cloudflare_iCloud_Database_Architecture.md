# Backend Database Architecture: Cloudflare + iCloud

## Target Outcome
Provide one backend contract that supports:
- Admin data and publishing workflows
- User profile/progress synchronization
- Safe media upload and playback metadata
- Cloudflare edge performance with iCloud ecosystem continuity

## Recommended Architecture
- **API + edge control**: Cloudflare Worker (`backend/cloudflare-worker`)
- **Transactional datastore**: PostgreSQL (recommended) or D1 equivalent schema
- **Object storage**: Cloudflare R2 for media binaries
- **Device sync metadata**: iCloud CloudKit records for Apple-device continuity

## Storage Responsibility Split
- **Cloudflare**
  - Video/audio/module assets
  - Signed upload and download URLs
  - Edge-cached playback manifests
  - Upload integrity enforcement (MIME + checksum + policy)
- **iCloud**
  - Learner progress checkpoints
  - Admin draft pointers and revision heads
  - Last-opened course/module state
  - Cross-device continuity metadata

## Canonical Data Model
1. `users`
   - user/admin identity, role, access tier
2. `courses`
   - course metadata and publication status
3. `modules_lessons`
   - syllabus tree, lecture units, sequencing
4. `video_assets`
   - generated media metadata and safety status
5. `enrollments_progress`
   - learner enrollment and progress checkpoints
6. `assignments_quizzes_submissions`
   - assessment records and outcomes
7. `admin_drafts_audit`
   - immutable admin publishing trace

## Required Policies
- HTTPS-only transport
- Signed URL expiration for uploads/downloads
- MIME whitelist for uploads
- SHA-256 checksum validation for media ingestion
- Role-bound authorization (admin vs user)
- Immutable audit records for admin publish operations

## API Contract Added
The backend now exposes:
- `GET /v1/system/storage-backends`
- `GET /v1/system/database-blueprint`
- `POST /v1/storage/resolve`

Use these endpoints to let the app/admin studio discover:
- active provider routing (`cloudflare` primary, `icloud` failover),
- schema contract for compatibility checks,
- per-workload storage routing (admin/user/media).

## Operational Recommendation
- Keep relational DB as source-of-truth.
- Treat CloudKit as synchronization metadata layer, not binary source-of-truth.
- Store only canonical IDs in CloudKit records (`user_id`, `course_id`, `video_asset_id`), and resolve full objects from backend API.
