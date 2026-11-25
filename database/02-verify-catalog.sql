IF DB_NAME() <> N'ArchitecturePilot_Acceptance_5E22' OR NOT EXISTS (
    SELECT 1 FROM sys.extended_properties
    WHERE class = 0 AND name = N'ArchitecturePilot.Acceptance.5E22' AND CONVERT(nvarchar(10), value) = N'1'
)
    THROW 51000, 'Select the marked pilot test database in SSMS and run the whole file.', 1;
IF @@TRANCOUNT <> 0
    THROW 51001, 'Run from a clean query connection.', 1;
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
SET IMPLICIT_TRANSACTIONS OFF;
SELECT @@VERSION AS SQLServerVersion, DB_NAME() AS DatabaseName,
       compatibility_level, is_read_committed_snapshot_on
FROM sys.databases WHERE database_id = DB_ID();

DECLARE @ExpectedColumns TABLE (C1 nvarchar(128), C2 nvarchar(128), C3 nvarchar(128), C4 int, C5 int, C6 int, C7 int);
INSERT @ExpectedColumns VALUES
    (N'Users', N'UserId', N'int', 4, 0, 0, 1),
    (N'Users', N'DisplayName', N'nvarchar', 300, 0, 0, 0),
    (N'Users', N'Email', N'nvarchar', 508, 0, 0, 0),
    (N'Users', N'GoogleSubject', N'nvarchar', 510, 0, 0, 0),
    (N'Projects', N'ProjectId', N'int', 4, 0, 0, 1),
    (N'Projects', N'ArchitectUserId', N'int', 4, 0, 0, 0),
    (N'Projects', N'CurrentStageId', N'int', 4, 0, 1, 0),
    (N'Projects', N'CreationOperationId', N'uniqueidentifier', 16, 0, 0, 0),
    (N'Projects', N'ProjectName', N'nvarchar', 400, 0, 0, 0),
    (N'Projects', N'ClientName', N'nvarchar', 300, 0, 0, 0),
    (N'Projects', N'ClientEmail', N'nvarchar', 508, 0, 0, 0),
    (N'Projects', N'ClientPhone', N'nvarchar', 64, 0, 0, 0),
    (N'Projects', N'LocationOrNote', N'nvarchar', 500, 0, 1, 0),
    (N'Projects', N'CreatedAt', N'datetime2', 7, 3, 0, 0),
    (N'ProjectMembers', N'ProjectMemberId', N'int', 4, 0, 0, 1),
    (N'ProjectMembers', N'ProjectId', N'int', 4, 0, 0, 0),
    (N'ProjectMembers', N'UserId', N'int', 4, 0, 0, 0),
    (N'ProjectMembers', N'AccessStatus', N'tinyint', 1, 0, 0, 0),
    (N'ProjectMembers', N'CanApprove', N'bit', 1, 0, 0, 0),
    (N'ProjectInvitations', N'InvitationId', N'int', 4, 0, 0, 1),
    (N'ProjectInvitations', N'ProjectId', N'int', 4, 0, 0, 0),
    (N'ProjectInvitations', N'InvitedEmail', N'nvarchar', 508, 0, 0, 0),
    (N'ProjectInvitations', N'CanApprove', N'bit', 1, 0, 0, 0),
    (N'ProjectInvitations', N'Status', N'tinyint', 1, 0, 0, 0),
    (N'ProjectInvitations', N'ExpiresAt', N'datetime2', 7, 3, 0, 0),
    (N'ProjectInvitations', N'IssuedAt', N'datetime2', 7, 3, 0, 0),
    (N'ProjectInvitations', N'TokenHash', N'binary', 32, 0, 0, 0),
    (N'ProjectInvitations', N'AcceptedByProjectMemberId', N'int', 4, 0, 1, 0),
    (N'ProjectStages', N'ProjectStageId', N'int', 4, 0, 0, 1),
    (N'ProjectStages', N'ProjectId', N'int', 4, 0, 0, 0),
    (N'ProjectStages', N'StageName', N'nvarchar', 300, 0, 0, 0),
    (N'ProjectStages', N'SortOrder', N'int', 4, 0, 0, 0),
    (N'ProjectStages', N'Status', N'tinyint', 1, 0, 0, 0),
    (N'ProjectStages', N'DueAt', N'datetime2', 7, 3, 1, 0),
    (N'Inquiries', N'InquiryId', N'int', 4, 0, 0, 1),
    (N'Inquiries', N'SubmissionOperationId', N'uniqueidentifier', 16, 0, 0, 0),
    (N'Inquiries', N'InquiryType', N'tinyint', 1, 0, 0, 0),
    (N'Inquiries', N'ProjectName', N'nvarchar', 400, 0, 1, 0),
    (N'Inquiries', N'ContactName', N'nvarchar', 300, 0, 0, 0),
    (N'Inquiries', N'Email', N'nvarchar', 508, 0, 0, 0),
    (N'Inquiries', N'Description', N'nvarchar', 4000, 0, 0, 0),
    (N'Inquiries', N'Phone', N'nvarchar', 64, 0, 1, 0),
    (N'Inquiries', N'City', N'nvarchar', 200, 0, 1, 0),
    (N'Inquiries', N'ExpectedStart', N'nvarchar', 200, 0, 1, 0),
    (N'Inquiries', N'Status', N'tinyint', 1, 0, 0, 0),
    (N'Inquiries', N'CreatedAt', N'datetime2', 7, 3, 0, 0),
    (N'Sketches', N'SketchId', N'int', 4, 0, 0, 1),
    (N'Sketches', N'ProjectId', N'int', 4, 0, 0, 0),
    (N'Sketches', N'CurrentVersionId', N'int', 4, 0, 1, 0),
    (N'Sketches', N'SketchName', N'nvarchar', 400, 0, 0, 0),
    (N'SketchVersions', N'SketchVersionId', N'int', 4, 0, 0, 1),
    (N'SketchVersions', N'SketchId', N'int', 4, 0, 0, 0),
    (N'SketchVersions', N'VersionNumber', N'int', 4, 0, 0, 0),
    (N'SketchVersions', N'PdfStorageKey', N'nvarchar', 1024, 0, 0, 0),
    (N'SketchVersions', N'Status', N'tinyint', 1, 0, 0, 0),
    (N'SketchVersions', N'PublishedAt', N'datetime2', 7, 3, 1, 0),
    (N'ApprovalRequests', N'ApprovalRequestId', N'int', 4, 0, 0, 1),
    (N'ApprovalRequests', N'SketchVersionId', N'int', 4, 0, 0, 0),
    (N'ApprovalRequests', N'SketchId', N'int', 4, 0, 0, 0),
    (N'ApprovalRequests', N'ApproverProjectMemberId', N'int', 4, 0, 0, 0),
    (N'ApprovalRequests', N'AlternativeLabel', N'nvarchar', 300, 0, 1, 0),
    (N'ApprovalRequests', N'Status', N'tinyint', 1, 0, 0, 0),
    (N'ApprovalRequests', N'ClosedReason', N'tinyint', 1, 0, 1, 0),
    (N'ApprovalRequests', N'DueAt', N'datetime2', 7, 3, 1, 0),
    (N'ApprovalRequests', N'Instructions', N'nvarchar', 4000, 0, 1, 0),
    (N'ApprovalRequests', N'CreatedAt', N'datetime2', 7, 3, 0, 0),
    (N'Approvals', N'ApprovalId', N'int', 4, 0, 0, 1),
    (N'Approvals', N'ApprovalRequestId', N'int', 4, 0, 0, 0),
    (N'Approvals', N'ApprovedByUserId', N'int', 4, 0, 0, 0),
    (N'Approvals', N'ApprovedAt', N'datetime2', 7, 3, 0, 0),
    (N'CorrectionRequests', N'CorrectionRequestId', N'int', 4, 0, 0, 1),
    (N'CorrectionRequests', N'ApprovalRequestId', N'int', 4, 0, 0, 0),
    (N'CorrectionRequests', N'RequestedByUserId', N'int', 4, 0, 0, 0),
    (N'CorrectionRequests', N'RequestedAt', N'datetime2', 7, 3, 0, 0),
    (N'CorrectionRequests', N'ResolvedInVersionId', N'int', 4, 0, 1, 0),
    (N'CorrectionRequests', N'Description', N'nvarchar', 8000, 0, 0, 0),
    (N'CorrectionRequests', N'Status', N'tinyint', 1, 0, 0, 0),
    (N'SketchThreads', N'SketchThreadId', N'int', 4, 0, 0, 1),
    (N'SketchThreads', N'SketchVersionId', N'int', 4, 0, 0, 0),
    (N'SketchThreads', N'ResolvedInVersionId', N'int', 4, 0, 1, 0),
    (N'SketchThreads', N'Status', N'tinyint', 1, 0, 0, 0),
    (N'SketchMessages', N'SketchMessageId', N'int', 4, 0, 0, 1),
    (N'SketchMessages', N'SketchThreadId', N'int', 4, 0, 0, 0),
    (N'SketchMessages', N'AuthorUserId', N'int', 4, 0, 0, 0),
    (N'SketchMessages', N'Body', N'nvarchar', 8000, 0, 0, 0),
    (N'SketchMessages', N'CreatedAt', N'datetime2', 7, 3, 0, 0),
    (N'EmailOutbox', N'EmailOutboxId', N'int', 4, 0, 0, 1),
    (N'EmailOutbox', N'OperationKey', N'uniqueidentifier', 16, 0, 0, 0),
    (N'EmailOutbox', N'EmailType', N'tinyint', 1, 0, 0, 0),
    (N'EmailOutbox', N'RecipientEmail', N'nvarchar', 508, 0, 0, 0),
    (N'EmailOutbox', N'InquiryId', N'int', 4, 0, 1, 0),
    (N'EmailOutbox', N'InvitationId', N'int', 4, 0, 1, 0),
    (N'EmailOutbox', N'ApprovalRequestId', N'int', 4, 0, 1, 0),
    (N'EmailOutbox', N'Status', N'tinyint', 1, 0, 0, 0),
    (N'EmailOutbox', N'AttemptCount', N'int', 4, 0, 0, 0),
    (N'EmailOutbox', N'CreatedAt', N'datetime2', 7, 3, 0, 0),
    (N'EmailOutbox', N'LastAttemptAt', N'datetime2', 7, 3, 1, 0),
    (N'EmailOutbox', N'SentAt', N'datetime2', 7, 3, 1, 0),
    (N'EmailOutbox', N'EncryptedInvitationPayload', N'varbinary', -1, 0, 1, 0),
    (N'EmailOutbox', N'LeaseId', N'uniqueidentifier', 16, 0, 1, 0),
    (N'EmailOutbox', N'LeaseUntil', N'datetime2', 7, 3, 1, 0),
    (N'EmailOutbox', N'LastErrorCode', N'nvarchar', 200, 0, 1, 0);
SELECT C1, C2, C3, C4, C5, C6, C7 INTO #Columns FROM (
    SELECT t.name, c.name, TYPE_NAME(c.user_type_id), CONVERT(int,c.max_length), CONVERT(int,c.scale),
           CONVERT(int,c.is_nullable), CONVERT(int,c.is_identity)
    FROM sys.tables AS t JOIN sys.columns AS c ON c.object_id = t.object_id
WHERE t.schema_id = SCHEMA_ID('dbo')
  AND t.name <> N'sysdiagrams'
  AND t.is_ms_shipped = 0
) AS Actual(C1, C2, C3, C4, C5, C6, C7);
IF EXISTS (SELECT * FROM @ExpectedColumns EXCEPT SELECT * FROM #Columns)
   OR EXISTS (SELECT * FROM #Columns EXCEPT SELECT * FROM @ExpectedColumns)
BEGIN
    SELECT 'Missing or changed' AS Difference, d.* FROM (SELECT * FROM @ExpectedColumns EXCEPT SELECT * FROM #Columns) AS d;
    SELECT 'Unexpected' AS Difference, d.* FROM (SELECT * FROM #Columns EXCEPT SELECT * FROM @ExpectedColumns) AS d;
    THROW 51003, 'Catalog mismatch: Columns', 1;
END;
DROP TABLE #Columns;
SELECT 'Catalog Columns' AS Test, 'PASS' AS Result;

DECLARE @ExpectedIdentity TABLE (C1 nvarchar(128), C2 nvarchar(128), C3 int, C4 int);
INSERT @ExpectedIdentity VALUES
    (N'Users', N'UserId', 1, 1),
    (N'Projects', N'ProjectId', 1, 1),
    (N'ProjectMembers', N'ProjectMemberId', 1, 1),
    (N'ProjectInvitations', N'InvitationId', 1, 1),
    (N'ProjectStages', N'ProjectStageId', 1, 1),
    (N'Inquiries', N'InquiryId', 1, 1),
    (N'Sketches', N'SketchId', 1, 1),
    (N'SketchVersions', N'SketchVersionId', 1, 1),
    (N'ApprovalRequests', N'ApprovalRequestId', 1, 1),
    (N'Approvals', N'ApprovalId', 1, 1),
    (N'CorrectionRequests', N'CorrectionRequestId', 1, 1),
    (N'SketchThreads', N'SketchThreadId', 1, 1),
    (N'SketchMessages', N'SketchMessageId', 1, 1),
    (N'EmailOutbox', N'EmailOutboxId', 1, 1);
SELECT C1, C2, C3, C4 INTO #Identity FROM (
    SELECT t.name,c.name,CONVERT(int,c.seed_value),CONVERT(int,c.increment_value)
    FROM sys.tables AS t JOIN sys.identity_columns AS c ON c.object_id=t.object_id
    WHERE t.schema_id=SCHEMA_ID('dbo') AND t.is_ms_shipped=0
) AS Actual(C1, C2, C3, C4);
IF EXISTS (SELECT * FROM @ExpectedIdentity EXCEPT SELECT * FROM #Identity)
   OR EXISTS (SELECT * FROM #Identity EXCEPT SELECT * FROM @ExpectedIdentity)
BEGIN
    SELECT 'Missing or changed' AS Difference, d.* FROM (SELECT * FROM @ExpectedIdentity EXCEPT SELECT * FROM #Identity) AS d;
    SELECT 'Unexpected' AS Difference, d.* FROM (SELECT * FROM #Identity EXCEPT SELECT * FROM @ExpectedIdentity) AS d;
    THROW 51003, 'Catalog mismatch: Identity', 1;
END;
DROP TABLE #Identity;
SELECT 'Catalog Identity' AS Test, 'PASS' AS Result;

DECLARE @ExpectedDefaults TABLE (C1 nvarchar(128), C2 nvarchar(128), C3 nvarchar(128), C4 nvarchar(128));
INSERT @ExpectedDefaults VALUES
    (N'ProjectMembers', N'AccessStatus', N'DF_ProjectMembers_AccessStatus', N'1'),
    (N'ProjectMembers', N'CanApprove', N'DF_ProjectMembers_CanApprove', N'0'),
    (N'ProjectInvitations', N'CanApprove', N'DF_ProjectInvitations_CanApprove', N'0'),
    (N'ProjectInvitations', N'Status', N'DF_ProjectInvitations_Status', N'1'),
    (N'ProjectStages', N'Status', N'DF_ProjectStages_Status', N'1'),
    (N'Inquiries', N'Status', N'DF_Inquiries_Status', N'1'),
    (N'SketchVersions', N'Status', N'DF_SketchVersions_Status', N'1'),
    (N'ApprovalRequests', N'Status', N'DF_ApprovalRequests_Status', N'1'),
    (N'CorrectionRequests', N'Status', N'DF_CorrectionRequests_Status', N'1'),
    (N'SketchThreads', N'Status', N'DF_SketchThreads_Status', N'1'),
    (N'EmailOutbox', N'Status', N'DF_EmailOutbox_Status', N'1'),
    (N'EmailOutbox', N'AttemptCount', N'DF_EmailOutbox_AttemptCount', N'0');
SELECT C1, C2, C3, C4 INTO #Defaults FROM (
    SELECT t.name,c.name,d.name,REPLACE(REPLACE(d.definition,'(',''),')','')
    FROM sys.tables AS t JOIN sys.default_constraints AS d ON d.parent_object_id=t.object_id
    JOIN sys.columns AS c ON c.object_id=t.object_id AND c.column_id=d.parent_column_id
    WHERE t.schema_id=SCHEMA_ID('dbo') AND t.is_ms_shipped=0
) AS Actual(C1, C2, C3, C4);
IF EXISTS (SELECT * FROM @ExpectedDefaults EXCEPT SELECT * FROM #Defaults)
   OR EXISTS (SELECT * FROM #Defaults EXCEPT SELECT * FROM @ExpectedDefaults)
BEGIN
    SELECT 'Missing or changed' AS Difference, d.* FROM (SELECT * FROM @ExpectedDefaults EXCEPT SELECT * FROM #Defaults) AS d;
    SELECT 'Unexpected' AS Difference, d.* FROM (SELECT * FROM #Defaults EXCEPT SELECT * FROM @ExpectedDefaults) AS d;
    THROW 51003, 'Catalog mismatch: Defaults', 1;
END;
DROP TABLE #Defaults;
SELECT 'Catalog Defaults' AS Test, 'PASS' AS Result;

DECLARE @ExpectedForeignKeys TABLE (C1 nvarchar(128), C2 nvarchar(128), C3 int, C4 nvarchar(128), C5 nvarchar(128), C6 nvarchar(128));
INSERT @ExpectedForeignKeys VALUES
    (N'Projects', N'FK_Projects_ArchitectUserId', 1, N'ArchitectUserId', N'Users', N'UserId'),
    (N'Projects', N'FK_Projects_CurrentStageId', 1, N'ProjectId', N'ProjectStages', N'ProjectId'),
    (N'Projects', N'FK_Projects_CurrentStageId', 2, N'CurrentStageId', N'ProjectStages', N'ProjectStageId'),
    (N'ProjectMembers', N'FK_ProjectMembers_ProjectId', 1, N'ProjectId', N'Projects', N'ProjectId'),
    (N'ProjectMembers', N'FK_ProjectMembers_UserId', 1, N'UserId', N'Users', N'UserId'),
    (N'ProjectInvitations', N'FK_ProjectInvitations_ProjectId', 1, N'ProjectId', N'Projects', N'ProjectId'),
    (N'ProjectInvitations', N'FK_ProjectInvitations_AcceptedByProjectMemberId', 1, N'ProjectId', N'ProjectMembers', N'ProjectId'),
    (N'ProjectInvitations', N'FK_ProjectInvitations_AcceptedByProjectMemberId', 2, N'AcceptedByProjectMemberId', N'ProjectMembers', N'ProjectMemberId'),
    (N'ProjectStages', N'FK_ProjectStages_ProjectId', 1, N'ProjectId', N'Projects', N'ProjectId'),
    (N'Sketches', N'FK_Sketches_ProjectId', 1, N'ProjectId', N'Projects', N'ProjectId'),
    (N'Sketches', N'FK_Sketches_CurrentVersionId', 1, N'SketchId', N'SketchVersions', N'SketchId'),
    (N'Sketches', N'FK_Sketches_CurrentVersionId', 2, N'CurrentVersionId', N'SketchVersions', N'SketchVersionId'),
    (N'SketchVersions', N'FK_SketchVersions_SketchId', 1, N'SketchId', N'Sketches', N'SketchId'),
    (N'ApprovalRequests', N'FK_ApprovalRequests_SketchVersionId', 1, N'SketchVersionId', N'SketchVersions', N'SketchVersionId'),
    (N'ApprovalRequests', N'FK_ApprovalRequests_SketchId', 1, N'SketchId', N'SketchVersions', N'SketchId'),
    (N'ApprovalRequests', N'FK_ApprovalRequests_SketchId', 2, N'SketchVersionId', N'SketchVersions', N'SketchVersionId'),
    (N'ApprovalRequests', N'FK_ApprovalRequests_ApproverProjectMemberId', 1, N'ApproverProjectMemberId', N'ProjectMembers', N'ProjectMemberId'),
    (N'Approvals', N'FK_Approvals_ApprovalRequestId', 1, N'ApprovalRequestId', N'ApprovalRequests', N'ApprovalRequestId'),
    (N'Approvals', N'FK_Approvals_ApprovedByUserId', 1, N'ApprovedByUserId', N'Users', N'UserId'),
    (N'CorrectionRequests', N'FK_CorrectionRequests_ApprovalRequestId', 1, N'ApprovalRequestId', N'ApprovalRequests', N'ApprovalRequestId'),
    (N'CorrectionRequests', N'FK_CorrectionRequests_RequestedByUserId', 1, N'RequestedByUserId', N'Users', N'UserId'),
    (N'CorrectionRequests', N'FK_CorrectionRequests_ResolvedInVersionId', 1, N'ResolvedInVersionId', N'SketchVersions', N'SketchVersionId'),
    (N'SketchThreads', N'FK_SketchThreads_SketchVersionId', 1, N'SketchVersionId', N'SketchVersions', N'SketchVersionId'),
    (N'SketchThreads', N'FK_SketchThreads_ResolvedInVersionId', 1, N'ResolvedInVersionId', N'SketchVersions', N'SketchVersionId'),
    (N'SketchMessages', N'FK_SketchMessages_SketchThreadId', 1, N'SketchThreadId', N'SketchThreads', N'SketchThreadId'),
    (N'SketchMessages', N'FK_SketchMessages_AuthorUserId', 1, N'AuthorUserId', N'Users', N'UserId'),
    (N'EmailOutbox', N'FK_EmailOutbox_InquiryId', 1, N'InquiryId', N'Inquiries', N'InquiryId'),
    (N'EmailOutbox', N'FK_EmailOutbox_InvitationId', 1, N'InvitationId', N'ProjectInvitations', N'InvitationId'),
    (N'EmailOutbox', N'FK_EmailOutbox_ApprovalRequestId', 1, N'ApprovalRequestId', N'ApprovalRequests', N'ApprovalRequestId');
SELECT C1, C2, C3, C4, C5, C6 INTO #ForeignKeys FROM (
    SELECT t.name,f.name,k.constraint_column_id,COL_NAME(t.object_id,k.parent_column_id),
           OBJECT_NAME(k.referenced_object_id),COL_NAME(k.referenced_object_id,k.referenced_column_id)
    FROM sys.foreign_keys AS f JOIN sys.tables AS t ON t.object_id=f.parent_object_id
    JOIN sys.foreign_key_columns AS k ON k.constraint_object_id=f.object_id
    WHERE t.schema_id=SCHEMA_ID('dbo') AND OBJECT_SCHEMA_NAME(k.referenced_object_id)='dbo'
      AND f.is_disabled=0 AND f.is_not_trusted=0 AND f.is_not_for_replication=0
      AND f.delete_referential_action=0 AND f.update_referential_action=0
) AS Actual(C1, C2, C3, C4, C5, C6);
IF EXISTS (SELECT * FROM @ExpectedForeignKeys EXCEPT SELECT * FROM #ForeignKeys)
   OR EXISTS (SELECT * FROM #ForeignKeys EXCEPT SELECT * FROM @ExpectedForeignKeys)
BEGIN
    SELECT 'Missing or changed' AS Difference, d.* FROM (SELECT * FROM @ExpectedForeignKeys EXCEPT SELECT * FROM #ForeignKeys) AS d;
    SELECT 'Unexpected' AS Difference, d.* FROM (SELECT * FROM #ForeignKeys EXCEPT SELECT * FROM @ExpectedForeignKeys) AS d;
    THROW 51003, 'Catalog mismatch: ForeignKeys', 1;
END;
DROP TABLE #ForeignKeys;
SELECT 'Catalog ForeignKeys' AS Test, 'PASS' AS Result;

DECLARE @ExpectedChecks TABLE (C1 nvarchar(128), C2 nvarchar(128));
INSERT @ExpectedChecks VALUES
    (N'ProjectMembers', N'CK_ProjectMembers_AccessStatus'),
    (N'ProjectInvitations', N'CK_ProjectInvitations_Status'),
    (N'ProjectInvitations', N'CK_ProjectInvitations_Expiry'),
    (N'ProjectInvitations', N'CK_ProjectInvitations_AcceptedMember'),
    (N'ProjectStages', N'CK_ProjectStages_Status'),
    (N'Inquiries', N'CK_Inquiries_Status'),
    (N'Inquiries', N'CK_Inquiries_InquiryType'),
    (N'SketchVersions', N'CK_SketchVersions_Status'),
    (N'SketchVersions', N'CK_SketchVersions_VersionNumber'),
    (N'SketchVersions', N'CK_SketchVersions_Publication'),
    (N'ApprovalRequests', N'CK_ApprovalRequests_Status'),
    (N'ApprovalRequests', N'CK_ApprovalRequests_Closure'),
    (N'CorrectionRequests', N'CK_CorrectionRequests_Status'),
    (N'CorrectionRequests', N'CK_CorrectionRequests_Resolution'),
    (N'SketchThreads', N'CK_SketchThreads_Status'),
    (N'EmailOutbox', N'CK_EmailOutbox_Status'),
    (N'EmailOutbox', N'CK_EmailOutbox_EmailType'),
    (N'EmailOutbox', N'CK_EmailOutbox_AttemptCount'),
    (N'EmailOutbox', N'CK_EmailOutbox_Sent'),
    (N'EmailOutbox', N'CK_EmailOutbox_Lease'),
    (N'EmailOutbox', N'CK_EmailOutbox_Payload'),
    (N'EmailOutbox', N'CK_EmailOutbox_Source');
SELECT C1, C2 INTO #Checks FROM (
    SELECT t.name,c.name FROM sys.check_constraints AS c JOIN sys.tables AS t ON t.object_id=c.parent_object_id
    WHERE t.schema_id=SCHEMA_ID('dbo') AND c.is_disabled=0 AND c.is_not_trusted=0 AND c.is_not_for_replication=0
) AS Actual(C1, C2);
IF EXISTS (SELECT * FROM @ExpectedChecks EXCEPT SELECT * FROM #Checks)
   OR EXISTS (SELECT * FROM #Checks EXCEPT SELECT * FROM @ExpectedChecks)
BEGIN
    SELECT 'Missing or changed' AS Difference, d.* FROM (SELECT * FROM @ExpectedChecks EXCEPT SELECT * FROM #Checks) AS d;
    SELECT 'Unexpected' AS Difference, d.* FROM (SELECT * FROM #Checks EXCEPT SELECT * FROM @ExpectedChecks) AS d;
    THROW 51003, 'Catalog mismatch: Checks', 1;
END;
DROP TABLE #Checks;
SELECT 'Catalog Checks' AS Test, 'PASS' AS Result;

DECLARE @ExpectedIndexes TABLE (C1 nvarchar(128), C2 nvarchar(128), C3 int, C4 nvarchar(128), C5 int, C6 char(2), C7 nvarchar(128));
INSERT @ExpectedIndexes VALUES
    (N'Users', N'PK_Users', 1, N'UserId', 1, N'PK', NULL),
    (N'Users', N'UQ_Users_GoogleSubject', 1, N'GoogleSubject', 1, N'UQ', NULL),
    (N'Projects', N'PK_Projects', 1, N'ProjectId', 1, N'PK', NULL),
    (N'Projects', N'UQ_Projects_ArchitectUserId_CreationOperationId', 1, N'ArchitectUserId', 1, N'UQ', NULL),
    (N'Projects', N'UQ_Projects_ArchitectUserId_CreationOperationId', 2, N'CreationOperationId', 1, N'UQ', NULL),
    (N'ProjectMembers', N'PK_ProjectMembers', 1, N'ProjectMemberId', 1, N'PK', NULL),
    (N'ProjectMembers', N'UQ_ProjectMembers_ProjectId_UserId', 1, N'ProjectId', 1, N'UQ', NULL),
    (N'ProjectMembers', N'UQ_ProjectMembers_ProjectId_UserId', 2, N'UserId', 1, N'UQ', NULL),
    (N'ProjectMembers', N'UQ_ProjectMembers_ProjectId_ProjectMemberId', 1, N'ProjectId', 1, N'UQ', NULL),
    (N'ProjectMembers', N'UQ_ProjectMembers_ProjectId_ProjectMemberId', 2, N'ProjectMemberId', 1, N'UQ', NULL),
    (N'ProjectInvitations', N'PK_ProjectInvitations', 1, N'InvitationId', 1, N'PK', NULL),
    (N'ProjectInvitations', N'UQ_ProjectInvitations_TokenHash', 1, N'TokenHash', 1, N'UQ', NULL),
    (N'ProjectStages', N'PK_ProjectStages', 1, N'ProjectStageId', 1, N'PK', NULL),
    (N'ProjectStages', N'UQ_ProjectStages_ProjectId_ProjectStageId', 1, N'ProjectId', 1, N'UQ', NULL),
    (N'ProjectStages', N'UQ_ProjectStages_ProjectId_ProjectStageId', 2, N'ProjectStageId', 1, N'UQ', NULL),
    (N'Inquiries', N'PK_Inquiries', 1, N'InquiryId', 1, N'PK', NULL),
    (N'Inquiries', N'UQ_Inquiries_SubmissionOperationId', 1, N'SubmissionOperationId', 1, N'UQ', NULL),
    (N'Sketches', N'PK_Sketches', 1, N'SketchId', 1, N'PK', NULL),
    (N'SketchVersions', N'PK_SketchVersions', 1, N'SketchVersionId', 1, N'PK', NULL),
    (N'SketchVersions', N'UQ_SketchVersions_SketchId_VersionNumber', 1, N'SketchId', 1, N'UQ', NULL),
    (N'SketchVersions', N'UQ_SketchVersions_SketchId_VersionNumber', 2, N'VersionNumber', 1, N'UQ', NULL),
    (N'SketchVersions', N'UQ_SketchVersions_SketchId_SketchVersionId', 1, N'SketchId', 1, N'UQ', NULL),
    (N'SketchVersions', N'UQ_SketchVersions_SketchId_SketchVersionId', 2, N'SketchVersionId', 1, N'UQ', NULL),
    (N'ApprovalRequests', N'PK_ApprovalRequests', 1, N'ApprovalRequestId', 1, N'PK', NULL),
    (N'Approvals', N'PK_Approvals', 1, N'ApprovalId', 1, N'PK', NULL),
    (N'Approvals', N'UQ_Approvals_ApprovalRequestId', 1, N'ApprovalRequestId', 1, N'UQ', NULL),
    (N'CorrectionRequests', N'PK_CorrectionRequests', 1, N'CorrectionRequestId', 1, N'PK', NULL),
    (N'CorrectionRequests', N'UQ_CorrectionRequests_ApprovalRequestId', 1, N'ApprovalRequestId', 1, N'UQ', NULL),
    (N'SketchThreads', N'PK_SketchThreads', 1, N'SketchThreadId', 1, N'PK', NULL),
    (N'SketchMessages', N'PK_SketchMessages', 1, N'SketchMessageId', 1, N'PK', NULL),
    (N'EmailOutbox', N'PK_EmailOutbox', 1, N'EmailOutboxId', 1, N'PK', NULL),
    (N'EmailOutbox', N'UQ_EmailOutbox_OperationKey', 1, N'OperationKey', 1, N'UQ', NULL),
    (N'SketchVersions', N'UX_SketchVersions_OneDraft', 1, N'SketchId', 1, N'IX', N'STATUS=1'),
    (N'ApprovalRequests', N'UX_ApprovalRequests_OneOpen', 1, N'SketchId', 1, N'IX', N'STATUS=1'),
    (N'ProjectMembers', N'UX_ProjectMembers_OneActiveApprover', 1, N'ProjectId', 1, N'IX', N'ACCESSSTATUS=1ANDCANAPPROVE=1'),
    (N'Projects', N'IX_Projects_Architect', 1, N'ArchitectUserId', 0, N'IX', NULL),
    (N'Projects', N'IX_Projects_Architect', 2, N'CreatedAt', 0, N'IX', NULL),
    (N'Projects', N'IX_Projects_Architect', 3, N'ProjectId', 0, N'IX', NULL),
    (N'ProjectMembers', N'IX_ProjectMembers_User', 1, N'UserId', 0, N'IX', NULL),
    (N'ProjectMembers', N'IX_ProjectMembers_User', 2, N'AccessStatus', 0, N'IX', NULL),
    (N'ProjectMembers', N'IX_ProjectMembers_User', 3, N'ProjectId', 0, N'IX', NULL),
    (N'SketchMessages', N'IX_SketchMessages_Thread', 1, N'SketchThreadId', 0, N'IX', NULL),
    (N'SketchMessages', N'IX_SketchMessages_Thread', 2, N'CreatedAt', 0, N'IX', NULL),
    (N'SketchMessages', N'IX_SketchMessages_Thread', 3, N'SketchMessageId', 0, N'IX', NULL),
    (N'EmailOutbox', N'IX_EmailOutbox_Queue', 1, N'Status', 0, N'IX', NULL),
    (N'EmailOutbox', N'IX_EmailOutbox_Queue', 2, N'LeaseUntil', 0, N'IX', NULL),
    (N'EmailOutbox', N'IX_EmailOutbox_Queue', 3, N'CreatedAt', 0, N'IX', NULL),
    (N'EmailOutbox', N'IX_EmailOutbox_Queue', 4, N'EmailOutboxId', 0, N'IX', NULL);
SELECT C1, C2, C3, C4, C5, C6, C7 INTO #Indexes FROM (
    SELECT t.name,i.name,CONVERT(int,k.key_ordinal),COL_NAME(t.object_id,k.column_id),CONVERT(int,i.is_unique),
           CASE WHEN i.is_primary_key=1 THEN 'PK' WHEN i.is_unique_constraint=1 THEN 'UQ' ELSE 'IX' END,
           UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(i.filter_definition,'[',''),']',''),'(',''),')',''),' ',''))
    FROM sys.tables AS t JOIN sys.indexes AS i ON i.object_id=t.object_id
    JOIN sys.index_columns AS k ON k.object_id=i.object_id AND k.index_id=i.index_id
    WHERE t.schema_id=SCHEMA_ID('dbo') AND i.is_disabled=0 AND i.is_hypothetical=0
      AND i.ignore_dup_key=0 AND k.is_descending_key=0 AND k.key_ordinal>0
) AS Actual(C1, C2, C3, C4, C5, C6, C7);
IF EXISTS (SELECT * FROM @ExpectedIndexes EXCEPT SELECT * FROM #Indexes)
   OR EXISTS (SELECT * FROM #Indexes EXCEPT SELECT * FROM @ExpectedIndexes)
BEGIN
    SELECT 'Missing or changed' AS Difference, d.* FROM (SELECT * FROM @ExpectedIndexes EXCEPT SELECT * FROM #Indexes) AS d;
    SELECT 'Unexpected' AS Difference, d.* FROM (SELECT * FROM #Indexes EXCEPT SELECT * FROM @ExpectedIndexes) AS d;
    THROW 51003, 'Catalog mismatch: Indexes', 1;
END;
DROP TABLE #Indexes;
SELECT 'Catalog Indexes' AS Test, 'PASS' AS Result;

SELECT OBJECT_NAME(parent_object_id) AS TableName, name, definition FROM sys.check_constraints ORDER BY TableName,name;
