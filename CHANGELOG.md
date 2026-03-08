# Changelog

## [1.1.6] - 2026-03-08

### Refactored

* **Architecture Compliance**: Migrated data-access operations across all modules (`WorkLog`, `Subscription`, `Photo`) to the strict Repository Pattern. View controllers no longer orchestrate queries.
* **Photo Module Serialization**: Standardized the Photo workflow. Relegated all path acquisition, target file relocation, and legacy record cleanup functions into `PhotoRepository`.
* **Sync Isolation**: Removed bilateral dependencies between `DbService` and `SyncService`. Cleaned `isDirty`/`remoteId` mapping during create and update transactions to prevent silent duplications.
* **UI/Data Separation in Settings**: Disengaged GetX UI alert invocations from the `BackupService` instance. The Backup/Restore operations strictly utilize Exception throwing to direct feedback on the Presentation layer (`DataManagementView`).
