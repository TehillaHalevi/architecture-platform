-- 03-seed-and-test.sql
-- מוסיף נתוני דמה למסד הבדיקה ומוודא שכללי הסכמה נאכפים בפועל.
-- בודק שפעולות תקינות מצליחות ושפעולות כמו כפילות או שיוך שגוי נדחות.
-- PASS פירושו שהתוצאה בפועל תאמה לתוצאה הצפויה, גם כשהפעולה נועדה להיכשל.
-- נתוני הדמה הדרושים לבדיקות 04 ו־05 נשמרים במסד.
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
SET XACT_ABORT ON;
DECLARE @now datetime2(3)=SYSUTCDATETIME(), @arch int, @client int, @other int, @p int, @m int, @st int, @s int, @v int, @p2 int, @m2 int, @st2 int, @s2 int, @v2 int, @draft int, @inv int, @accepted int, @inq int, @req int, @req2 int, @thread int, @msg int, @mail int;
IF EXISTS (SELECT 1 FROM dbo.Users) OR EXISTS (SELECT 1 FROM dbo.Inquiries)
    THROW 51004, 'Acceptance seed requires fresh pilot tables.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.Users (DisplayName, Email, GoogleSubject)
    VALUES (N'arch', N'arch@example.invalid', N'pilot-fixture-arch');
    SET @arch = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.Users (DisplayName, Email, GoogleSubject)
    VALUES (N'client', N'client@example.invalid', N'pilot-fixture-client');
    SET @client = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.Users (DisplayName, Email, GoogleSubject)
    VALUES (N'other', N'other@example.invalid', N'pilot-fixture-other');
    SET @other = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.Projects (ArchitectUserId, CreationOperationId, ProjectName, ClientName, ClientEmail, ClientPhone, CreatedAt)
    VALUES (@arch, NEWID(), N'Pilot project', N'Demo', N'client@example.invalid', N'0500000000', @now);
    SET @p = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.ProjectMembers (ProjectId, UserId, CanApprove)
    VALUES (@p, @client, 1);
    SET @m = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.ProjectStages (ProjectId, StageName, SortOrder)
    VALUES (@p, N'Design', 1);
    SET @st = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.Sketches (ProjectId, SketchName)
    VALUES (@p, N'pilot-fixture-s');
    SET @s = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.SketchVersions (SketchId, VersionNumber, PdfStorageKey, Status, PublishedAt)
    VALUES (@s, 1, N'fixture/private/dummy.pdf', 2, @now);
    SET @v = CONVERT(int, SCOPE_IDENTITY());
    IF NOT EXISTS (SELECT 1 FROM dbo.Projects WHERE ProjectId=@p AND CurrentStageId IS NULL)
        OR NOT EXISTS (SELECT 1 FROM dbo.Sketches WHERE SketchId=@s AND CurrentVersionId IS NULL)
        THROW 51004, 'Optional composite reference rejected NULL.', 1;
    UPDATE dbo.Projects SET CurrentStageId=@st WHERE ProjectId=@p;
    UPDATE dbo.Sketches SET CurrentVersionId=@v WHERE SketchId=@s;
    INSERT dbo.Projects (ArchitectUserId, CreationOperationId, ProjectName, ClientName, ClientEmail, ClientPhone, CreatedAt)
    VALUES (@arch, NEWID(), N'Pilot project', N'Demo', N'other@example.invalid', N'0500000000', @now);
    SET @p2 = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.ProjectMembers (ProjectId, UserId, CanApprove)
    VALUES (@p2, @other, 1);
    SET @m2 = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.ProjectStages (ProjectId, StageName, SortOrder)
    VALUES (@p2, N'Design', 1);
    SET @st2 = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.Sketches (ProjectId, SketchName)
    VALUES (@p2, N'pilot-fixture-s2');
    SET @s2 = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.SketchVersions (SketchId, VersionNumber, PdfStorageKey, Status, PublishedAt)
    VALUES (@s2, 1, N'fixture/private/dummy.pdf', 2, @now);
    SET @v2 = CONVERT(int, SCOPE_IDENTITY());
    IF NOT EXISTS (SELECT 1 FROM dbo.Projects WHERE ProjectId=@p2 AND CurrentStageId IS NULL)
        OR NOT EXISTS (SELECT 1 FROM dbo.Sketches WHERE SketchId=@s2 AND CurrentVersionId IS NULL)
        THROW 51004, 'Optional composite reference rejected NULL.', 1;
    UPDATE dbo.Projects SET CurrentStageId=@st2 WHERE ProjectId=@p2;
    UPDATE dbo.Sketches SET CurrentVersionId=@v2 WHERE SketchId=@s2;
    INSERT dbo.SketchVersions (SketchId, VersionNumber, PdfStorageKey)
    VALUES (@s, 2, N'fixture/private/draft.pdf');
    SET @draft = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.ProjectInvitations (ProjectId, InvitedEmail, ExpiresAt, IssuedAt, TokenHash)
    VALUES (@p, N'client@example.invalid', DATEADD(day,7,@now), @now, HASHBYTES('SHA2_256','dummy-invitation'));
    SET @inv = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.ProjectInvitations (ProjectId, InvitedEmail, ExpiresAt, IssuedAt, Status, AcceptedByProjectMemberId, TokenHash)
    VALUES (@p, N'client@example.invalid', DATEADD(day,7,@now), @now, 2, @m, HASHBYTES('SHA2_256','dummy-accepted'));
    SET @accepted = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.Inquiries (SubmissionOperationId, InquiryType, ContactName, Email, Description, CreatedAt)
    VALUES (NEWID(), 1, N'Fixture', N'public@example.invalid', N'Demo request', @now);
    SET @inq = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.ApprovalRequests (SketchVersionId, SketchId, ApproverProjectMemberId, Instructions, CreatedAt)
    VALUES (@v, @s, @m, N'pilot-fixture-race', @now);
    SET @req = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.ApprovalRequests (SketchVersionId, SketchId, ApproverProjectMemberId, Instructions, CreatedAt)
    VALUES (@v2, @s2, @m2, N'pilot-fixture-rollback', @now);
    SET @req2 = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.SketchThreads (SketchVersionId)
    VALUES (@v);
    SET @thread = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.SketchMessages (SketchThreadId, AuthorUserId, Body, CreatedAt)
    VALUES (@thread, @client, N'Demo message', @now);
    SET @msg = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.EmailOutbox (OperationKey, EmailType, RecipientEmail, InvitationId, CreatedAt, EncryptedInvitationPayload)
    VALUES ('51E22000-0000-4000-8000-000000000001', 2, N'client@example.invalid', @inv, @now, 0x010203);
    SET @mail = CONVERT(int, SCOPE_IDENTITY());
    INSERT dbo.EmailOutbox (OperationKey, EmailType, RecipientEmail, CreatedAt, InquiryId)
    VALUES (NEWID(), 1, N'fixture@example.invalid', @now, @inq);
    INSERT dbo.EmailOutbox (OperationKey, EmailType, RecipientEmail, CreatedAt, ApprovalRequestId)
    VALUES (NEWID(), 3, N'fixture@example.invalid', @now, @req);
    INSERT dbo.EmailOutbox (OperationKey, EmailType, RecipientEmail, CreatedAt, ApprovalRequestId)
    VALUES (NEWID(), 4, N'fixture@example.invalid', @now, @req);
    IF NOT EXISTS (
        SELECT 1 FROM dbo.Projects AS p
        JOIN dbo.ProjectStages AS st ON st.ProjectId=p.ProjectId AND st.ProjectStageId=p.CurrentStageId
        JOIN dbo.ProjectMembers AS m ON m.ProjectId=p.ProjectId
        JOIN dbo.Sketches AS s ON s.ProjectId=p.ProjectId
        JOIN dbo.SketchVersions AS v ON v.SketchId=s.SketchId AND v.SketchVersionId=s.CurrentVersionId
        JOIN dbo.ApprovalRequests AS r ON r.SketchId=s.SketchId AND r.SketchVersionId=v.SketchVersionId
                                     AND r.ApproverProjectMemberId=m.ProjectMemberId
        WHERE r.ApprovalRequestId=@req AND r.Status=1 AND v.Status=2
          AND m.AccessStatus=1 AND m.CanApprove=1 AND st.Status=1
    ) OR NOT EXISTS (SELECT 1 FROM dbo.EmailOutbox WHERE EmailOutboxId=@mail
                   AND Status=1 AND AttemptCount=0 AND LeaseId IS NULL AND LeaseUntil IS NULL)
      OR NOT EXISTS (SELECT 1 FROM dbo.ProjectInvitations WHERE InvitationId=@inv
                   AND Status=1 AND CanApprove=0 AND AcceptedByProjectMemberId IS NULL)
      OR NOT EXISTS (SELECT 1 FROM dbo.SketchVersions WHERE SketchVersionId=@draft AND Status=1 AND PublishedAt IS NULL)
      OR NOT EXISTS (SELECT 1 FROM dbo.SketchThreads WHERE SketchThreadId=@thread AND Status=1 AND ResolvedInVersionId IS NULL)
      OR NOT EXISTS (SELECT 1 FROM dbo.Inquiries WHERE InquiryId=@inq AND Status=1)
        THROW 51004, 'Positive fixture or defaults mismatch.', 1;
    COMMIT;
    SELECT 'Positive fixture and defaults' AS Test, 'PASS' AS Result;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    THROW;
END CATCH;

DECLARE @Results TABLE (Test nvarchar(150), Expected nvarchar(250), Actual nvarchar(2048), Result varchar(4));
DECLARE @changed int;
BEGIN TRY
    BEGIN TRANSACTION;
    -- Demonstration of the server write path. Authorization and response share this transaction.
    IF NOT EXISTS (
        SELECT 1 FROM dbo.ProjectMembers AS m WITH (HOLDLOCK)
        JOIN dbo.Sketches AS s ON s.ProjectId=m.ProjectId
        WHERE m.ProjectMemberId=@m2 AND m.UserId=@other
          AND m.AccessStatus=1 AND m.CanApprove=1 AND s.SketchId=@s2
    )
        THROW 51010, 'Fixture actor lacks approval access.', 1;
    UPDATE dbo.ApprovalRequests
    SET Status=3
    WHERE ApprovalRequestId=@req2 AND SketchId=@s2
      AND ApproverProjectMemberId=@m2 AND Status=1;
    SET @changed=@@ROWCOUNT;
    IF @changed=1
    BEGIN
        INSERT dbo.CorrectionRequests (ApprovalRequestId,RequestedByUserId,RequestedAt,Description)
        VALUES (@req2,@other,SYSUTCDATETIME(),NULL);
    END;
    ROLLBACK;
    INSERT @Results VALUES ('Response transaction rollback','515, request open, zero responses','No expected insert error','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results
    SELECT 'Response transaction rollback','515, request open, zero responses',
           CONCAT(ERROR_MESSAGE(), ' | status=', r.Status,
                  ' | approvals=', a.Total, ' | corrections=', c.Total),
           CASE WHEN ERROR_NUMBER()=515 AND CHARINDEX('Description',ERROR_MESSAGE())>0
                      AND @changed=1 AND r.Status=1 AND a.Total=0 AND c.Total=0 THEN 'PASS' ELSE 'FAIL' END
    FROM dbo.ApprovalRequests AS r
    CROSS APPLY (SELECT COUNT(*) AS Total FROM dbo.Approvals WHERE ApprovalRequestId=r.ApprovalRequestId) AS a
    CROSS APPLY (SELECT COUNT(*) AS Total FROM dbo.CorrectionRequests WHERE ApprovalRequestId=r.ApprovalRequestId) AS c
    WHERE r.ApprovalRequestId=@req2;
END CATCH;

-- Each invalid mutation is isolated, including unexpectedly accepted changes.

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.Users (DisplayName,Email,GoogleSubject) VALUES (N'Duplicated',N'duplicate@example.invalid',N'pilot-fixture-client');
    ROLLBACK;
    INSERT @Results VALUES (N'Users duplicate GoogleSubject',N'2627 / UQ_Users_GoogleSubject','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Users duplicate GoogleSubject',N'2627 / UQ_Users_GoogleSubject',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=2627 AND CHARINDEX(N'UQ_Users_GoogleSubject',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.Projects (ArchitectUserId,CreationOperationId,ProjectName,ClientName,ClientEmail,ClientPhone,CreatedAt)
SELECT ArchitectUserId,CreationOperationId,ProjectName,ClientName,ClientEmail,ClientPhone,CreatedAt FROM dbo.Projects WHERE ProjectId=@p;
    ROLLBACK;
    INSERT @Results VALUES (N'Projects duplicate ArchitectUserId_CreationOperationId',N'2627 / UQ_Projects_ArchitectUserId_CreationOperationId','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Projects duplicate ArchitectUserId_CreationOperationId',N'2627 / UQ_Projects_ArchitectUserId_CreationOperationId',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=2627 AND CHARINDEX(N'UQ_Projects_ArchitectUserId_CreationOperationId',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.ProjectMembers (ProjectId,UserId) VALUES (@p,@client);
    ROLLBACK;
    INSERT @Results VALUES (N'ProjectMembers duplicate ProjectId_UserId',N'2627 / UQ_ProjectMembers_ProjectId_UserId','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'ProjectMembers duplicate ProjectId_UserId',N'2627 / UQ_ProjectMembers_ProjectId_UserId',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=2627 AND CHARINDEX(N'UQ_ProjectMembers_ProjectId_UserId',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.ProjectMembers (ProjectId,UserId,CanApprove) VALUES (@p,@other,1);
    ROLLBACK;
    INSERT @Results VALUES (N'ProjectMembers duplicate OneActiveApprover',N'2601 / UX_ProjectMembers_OneActiveApprover','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'ProjectMembers duplicate OneActiveApprover',N'2601 / UX_ProjectMembers_OneActiveApprover',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=2601 AND CHARINDEX(N'UX_ProjectMembers_OneActiveApprover',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.ProjectInvitations (ProjectId,InvitedEmail,IssuedAt,ExpiresAt,TokenHash)
SELECT ProjectId,InvitedEmail,IssuedAt,ExpiresAt,TokenHash FROM dbo.ProjectInvitations WHERE InvitationId=@inv;
    ROLLBACK;
    INSERT @Results VALUES (N'ProjectInvitations duplicate TokenHash',N'2627 / UQ_ProjectInvitations_TokenHash','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'ProjectInvitations duplicate TokenHash',N'2627 / UQ_ProjectInvitations_TokenHash',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=2627 AND CHARINDEX(N'UQ_ProjectInvitations_TokenHash',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.Inquiries (SubmissionOperationId,InquiryType,ContactName,Email,Description,CreatedAt)
SELECT SubmissionOperationId,InquiryType,ContactName,Email,Description,CreatedAt FROM dbo.Inquiries WHERE InquiryId=@inq;
    ROLLBACK;
    INSERT @Results VALUES (N'Inquiries duplicate SubmissionOperationId',N'2627 / UQ_Inquiries_SubmissionOperationId','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Inquiries duplicate SubmissionOperationId',N'2627 / UQ_Inquiries_SubmissionOperationId',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=2627 AND CHARINDEX(N'UQ_Inquiries_SubmissionOperationId',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.SketchVersions (SketchId,VersionNumber,PdfStorageKey,Status,PublishedAt) VALUES (@s,1,N'demo.pdf',2,@now);
    ROLLBACK;
    INSERT @Results VALUES (N'SketchVersions duplicate SketchId_VersionNumber',N'2627 / UQ_SketchVersions_SketchId_VersionNumber','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'SketchVersions duplicate SketchId_VersionNumber',N'2627 / UQ_SketchVersions_SketchId_VersionNumber',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=2627 AND CHARINDEX(N'UQ_SketchVersions_SketchId_VersionNumber',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.SketchVersions (SketchId,VersionNumber,PdfStorageKey) VALUES (@s,3,N'demo.pdf');
    ROLLBACK;
    INSERT @Results VALUES (N'SketchVersions duplicate OneDraft',N'2601 / UX_SketchVersions_OneDraft','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'SketchVersions duplicate OneDraft',N'2601 / UX_SketchVersions_OneDraft',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=2601 AND CHARINDEX(N'UX_SketchVersions_OneDraft',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.ApprovalRequests (SketchVersionId,SketchId,ApproverProjectMemberId,CreatedAt) VALUES (@v,@s,@m,@now);
    ROLLBACK;
    INSERT @Results VALUES (N'ApprovalRequests duplicate OneOpen',N'2601 / UX_ApprovalRequests_OneOpen','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'ApprovalRequests duplicate OneOpen',N'2601 / UX_ApprovalRequests_OneOpen',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=2601 AND CHARINDEX(N'UX_ApprovalRequests_OneOpen',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.EmailOutbox (OperationKey,EmailType,RecipientEmail,InvitationId,CreatedAt) VALUES ('51E22000-0000-4000-8000-000000000001',2,N'demo@example.invalid',@inv,@now);
    ROLLBACK;
    INSERT @Results VALUES (N'EmailOutbox duplicate OperationKey',N'2627 / UQ_EmailOutbox_OperationKey','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'EmailOutbox duplicate OperationKey',N'2627 / UQ_EmailOutbox_OperationKey',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=2627 AND CHARINDEX(N'UQ_EmailOutbox_OperationKey',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.Projects SET CurrentStageId=@st2 WHERE ProjectId=@p;
    ROLLBACK;
    INSERT @Results VALUES (N'Projects cross-parent CurrentStageId',N'547 / FK_Projects_CurrentStageId','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Projects cross-parent CurrentStageId',N'547 / FK_Projects_CurrentStageId',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'FK_Projects_CurrentStageId',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.Sketches SET CurrentVersionId=@v2 WHERE SketchId=@s;
    ROLLBACK;
    INSERT @Results VALUES (N'Sketches cross-parent CurrentVersionId',N'547 / FK_Sketches_CurrentVersionId','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Sketches cross-parent CurrentVersionId',N'547 / FK_Sketches_CurrentVersionId',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'FK_Sketches_CurrentVersionId',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ProjectInvitations SET Status=2,AcceptedByProjectMemberId=@m2 WHERE InvitationId=@inv;
    ROLLBACK;
    INSERT @Results VALUES (N'ProjectInvitations cross-parent AcceptedByProjectMemberId',N'547 / FK_ProjectInvitations_AcceptedByProjectMemberId','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'ProjectInvitations cross-parent AcceptedByProjectMemberId',N'547 / FK_ProjectInvitations_AcceptedByProjectMemberId',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'FK_ProjectInvitations_AcceptedByProjectMemberId',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ApprovalRequests SET SketchVersionId=@v2 WHERE ApprovalRequestId=@req;
    ROLLBACK;
    INSERT @Results VALUES (N'ApprovalRequests cross-parent SketchId',N'547 / FK_ApprovalRequests_SketchId','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'ApprovalRequests cross-parent SketchId',N'547 / FK_ApprovalRequests_SketchId',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'FK_ApprovalRequests_SketchId',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ProjectMembers SET AccessStatus=9 WHERE ProjectMemberId=@m;
    ROLLBACK;
    INSERT @Results VALUES (N'ProjectMembers AccessStatus',N'547 / CK_ProjectMembers_AccessStatus','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'ProjectMembers AccessStatus',N'547 / CK_ProjectMembers_AccessStatus',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_ProjectMembers_AccessStatus',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ProjectInvitations SET Status=9 WHERE InvitationId=@inv;
    ROLLBACK;
    INSERT @Results VALUES (N'ProjectInvitations Status',N'547 / CK_ProjectInvitations_Status','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'ProjectInvitations Status',N'547 / CK_ProjectInvitations_Status',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_ProjectInvitations_Status',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ProjectStages SET Status=9 WHERE ProjectStageId=@st;
    ROLLBACK;
    INSERT @Results VALUES (N'ProjectStages Status',N'547 / CK_ProjectStages_Status','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'ProjectStages Status',N'547 / CK_ProjectStages_Status',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_ProjectStages_Status',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.Inquiries SET Status=9 WHERE InquiryId=@inq;
    ROLLBACK;
    INSERT @Results VALUES (N'Inquiries Status',N'547 / CK_Inquiries_Status','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Inquiries Status',N'547 / CK_Inquiries_Status',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_Inquiries_Status',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.Inquiries SET InquiryType=9 WHERE InquiryId=@inq;
    ROLLBACK;
    INSERT @Results VALUES (N'Inquiries InquiryType',N'547 / CK_Inquiries_InquiryType','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Inquiries InquiryType',N'547 / CK_Inquiries_InquiryType',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_Inquiries_InquiryType',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.SketchVersions SET Status=9 WHERE SketchVersionId=@v;
    ROLLBACK;
    INSERT @Results VALUES (N'SketchVersions Status',N'547 / CK_SketchVersions_Status','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'SketchVersions Status',N'547 / CK_SketchVersions_Status',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_SketchVersions_Status',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ApprovalRequests SET Status=9 WHERE ApprovalRequestId=@req;
    ROLLBACK;
    INSERT @Results VALUES (N'ApprovalRequests Status',N'547 / CK_ApprovalRequests_Status','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'ApprovalRequests Status',N'547 / CK_ApprovalRequests_Status',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_ApprovalRequests_Status',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.SketchThreads SET Status=9 WHERE SketchThreadId=@thread;
    ROLLBACK;
    INSERT @Results VALUES (N'SketchThreads Status',N'547 / CK_SketchThreads_Status','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'SketchThreads Status',N'547 / CK_SketchThreads_Status',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_SketchThreads_Status',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.EmailOutbox SET Status=9 WHERE EmailOutboxId=@mail;
    ROLLBACK;
    INSERT @Results VALUES (N'EmailOutbox Status',N'547 / CK_EmailOutbox_Status','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'EmailOutbox Status',N'547 / CK_EmailOutbox_Status',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_EmailOutbox_Status',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.EmailOutbox SET EmailType=9,EncryptedInvitationPayload=NULL WHERE EmailOutboxId=@mail;
    ROLLBACK;
    INSERT @Results VALUES (N'EmailOutbox EmailType',N'547 / CK_EmailOutbox_EmailType','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'EmailOutbox EmailType',N'547 / CK_EmailOutbox_EmailType',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_EmailOutbox_EmailType',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.CorrectionRequests (ApprovalRequestId,RequestedByUserId,RequestedAt,Description,Status)
VALUES (@req,@client,@now,N'Fixture',9);
    ROLLBACK;
    INSERT @Results VALUES (N'CorrectionRequests Status',N'547 / CK_CorrectionRequests_Status','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'CorrectionRequests Status',N'547 / CK_CorrectionRequests_Status',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_CorrectionRequests_Status',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ProjectInvitations SET ExpiresAt=IssuedAt WHERE InvitationId=@inv;
    ROLLBACK;
    INSERT @Results VALUES (N'ProjectInvitations Expiry',N'547 / CK_ProjectInvitations_Expiry','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'ProjectInvitations Expiry',N'547 / CK_ProjectInvitations_Expiry',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_ProjectInvitations_Expiry',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ProjectInvitations SET Status=2 WHERE InvitationId=@inv;
    ROLLBACK;
    INSERT @Results VALUES (N'Invitation accepted without member',N'547 / CK_ProjectInvitations_AcceptedMember','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Invitation accepted without member',N'547 / CK_ProjectInvitations_AcceptedMember',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_ProjectInvitations_AcceptedMember',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ProjectInvitations SET AcceptedByProjectMemberId=@m WHERE InvitationId=@inv;
    ROLLBACK;
    INSERT @Results VALUES (N'Pending invitation with accepted member',N'547 / CK_ProjectInvitations_AcceptedMember','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Pending invitation with accepted member',N'547 / CK_ProjectInvitations_AcceptedMember',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_ProjectInvitations_AcceptedMember',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.SketchVersions SET VersionNumber=0 WHERE SketchVersionId=@v;
    ROLLBACK;
    INSERT @Results VALUES (N'SketchVersions VersionNumber',N'547 / CK_SketchVersions_VersionNumber','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'SketchVersions VersionNumber',N'547 / CK_SketchVersions_VersionNumber',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_SketchVersions_VersionNumber',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.SketchVersions SET PublishedAt=NULL WHERE SketchVersionId=@v;
    ROLLBACK;
    INSERT @Results VALUES (N'Published version without timestamp',N'547 / CK_SketchVersions_Publication','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Published version without timestamp',N'547 / CK_SketchVersions_Publication',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_SketchVersions_Publication',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.SketchVersions SET PublishedAt=@now WHERE SketchVersionId=@draft;
    ROLLBACK;
    INSERT @Results VALUES (N'Draft with publication timestamp',N'547 / CK_SketchVersions_Publication','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Draft with publication timestamp',N'547 / CK_SketchVersions_Publication',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_SketchVersions_Publication',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.SketchVersions SET Status=3,PublishedAt=NULL WHERE SketchVersionId=@v;
    ROLLBACK;
    INSERT @Results VALUES (N'Removed version without publication history',N'547 / CK_SketchVersions_Publication','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Removed version without publication history',N'547 / CK_SketchVersions_Publication',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_SketchVersions_Publication',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ApprovalRequests SET Status=4 WHERE ApprovalRequestId=@req;
    ROLLBACK;
    INSERT @Results VALUES (N'Closed request without reason',N'547 / CK_ApprovalRequests_Closure','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Closed request without reason',N'547 / CK_ApprovalRequests_Closure',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_ApprovalRequests_Closure',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ApprovalRequests SET Status=4,ClosedReason=9 WHERE ApprovalRequestId=@req;
    ROLLBACK;
    INSERT @Results VALUES (N'Closed request with illegal reason',N'547 / CK_ApprovalRequests_Closure','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Closed request with illegal reason',N'547 / CK_ApprovalRequests_Closure',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_ApprovalRequests_Closure',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.ApprovalRequests SET ClosedReason=1 WHERE ApprovalRequestId=@req;
    ROLLBACK;
    INSERT @Results VALUES (N'Open request with closure reason',N'547 / CK_ApprovalRequests_Closure','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Open request with closure reason',N'547 / CK_ApprovalRequests_Closure',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_ApprovalRequests_Closure',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.CorrectionRequests (ApprovalRequestId,RequestedByUserId,RequestedAt,Description,Status)
VALUES (@req,@client,@now,N'Fixture',2);
    ROLLBACK;
    INSERT @Results VALUES (N'Resolved correction without version',N'547 / CK_CorrectionRequests_Resolution','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Resolved correction without version',N'547 / CK_CorrectionRequests_Resolution',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_CorrectionRequests_Resolution',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.CorrectionRequests (ApprovalRequestId,RequestedByUserId,RequestedAt,Description,ResolvedInVersionId)
VALUES (@req,@client,@now,N'Fixture',@v);
    ROLLBACK;
    INSERT @Results VALUES (N'Open correction with resolved version',N'547 / CK_CorrectionRequests_Resolution','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Open correction with resolved version',N'547 / CK_CorrectionRequests_Resolution',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_CorrectionRequests_Resolution',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.EmailOutbox SET AttemptCount=-1 WHERE EmailOutboxId=@mail;
    ROLLBACK;
    INSERT @Results VALUES (N'EmailOutbox AttemptCount',N'547 / CK_EmailOutbox_AttemptCount','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'EmailOutbox AttemptCount',N'547 / CK_EmailOutbox_AttemptCount',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_EmailOutbox_AttemptCount',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.EmailOutbox SET Status=2 WHERE EmailOutboxId=@mail;
    ROLLBACK;
    INSERT @Results VALUES (N'Sent mail without provider timestamp',N'547 / CK_EmailOutbox_Sent','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Sent mail without provider timestamp',N'547 / CK_EmailOutbox_Sent',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_EmailOutbox_Sent',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.EmailOutbox SET SentAt=@now WHERE EmailOutboxId=@mail;
    ROLLBACK;
    INSERT @Results VALUES (N'Pending mail with provider timestamp',N'547 / CK_EmailOutbox_Sent','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Pending mail with provider timestamp',N'547 / CK_EmailOutbox_Sent',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_EmailOutbox_Sent',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.EmailOutbox SET LeaseId=NEWID() WHERE EmailOutboxId=@mail;
    ROLLBACK;
    INSERT @Results VALUES (N'Only LeaseId',N'547 / CK_EmailOutbox_Lease','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Only LeaseId',N'547 / CK_EmailOutbox_Lease',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_EmailOutbox_Lease',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.EmailOutbox SET LeaseUntil=@now WHERE EmailOutboxId=@mail;
    ROLLBACK;
    INSERT @Results VALUES (N'Only LeaseUntil',N'547 / CK_EmailOutbox_Lease','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Only LeaseUntil',N'547 / CK_EmailOutbox_Lease',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_EmailOutbox_Lease',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.EmailOutbox SET InvitationId=NULL WHERE EmailOutboxId=@mail;
    ROLLBACK;
    INSERT @Results VALUES (N'Missing mail source',N'547 / CK_EmailOutbox_Source','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Missing mail source',N'547 / CK_EmailOutbox_Source',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_EmailOutbox_Source',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.EmailOutbox SET InquiryId=@inq WHERE EmailOutboxId=@mail;
    ROLLBACK;
    INSERT @Results VALUES (N'Multiple mail sources',N'547 / CK_EmailOutbox_Source','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Multiple mail sources',N'547 / CK_EmailOutbox_Source',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_EmailOutbox_Source',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.EmailOutbox SET InvitationId=NULL,InquiryId=@inq WHERE EmailOutboxId=@mail;
    ROLLBACK;
    INSERT @Results VALUES (N'Single mail source of wrong type',N'547 / CK_EmailOutbox_Source','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Single mail source of wrong type',N'547 / CK_EmailOutbox_Source',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_EmailOutbox_Source',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE dbo.EmailOutbox SET EmailType=1,InvitationId=NULL,InquiryId=@inq WHERE EmailOutboxId=@mail;
    ROLLBACK;
    INSERT @Results VALUES (N'Invitation payload on inquiry mail',N'547 / CK_EmailOutbox_Payload','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Invitation payload on inquiry mail',N'547 / CK_EmailOutbox_Payload',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=547 AND CHARINDEX(N'CK_EmailOutbox_Payload',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.Approvals (ApprovalRequestId,ApprovedByUserId,ApprovedAt) VALUES (@req,@client,@now);
    INSERT dbo.Approvals (ApprovalRequestId,ApprovedByUserId,ApprovedAt) VALUES (@req,@client,@now);
    ROLLBACK;
    INSERT @Results VALUES (N'Approvals duplicate ApprovalRequestId',N'2627 / UQ_Approvals_ApprovalRequestId','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'Approvals duplicate ApprovalRequestId',N'2627 / UQ_Approvals_ApprovalRequestId',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=2627 AND CHARINDEX(N'UQ_Approvals_ApprovalRequestId',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

BEGIN TRY
    BEGIN TRANSACTION;
    INSERT dbo.CorrectionRequests (ApprovalRequestId,RequestedByUserId,RequestedAt,Description) VALUES (@req,@client,@now,N'Demo correction');
    INSERT dbo.CorrectionRequests (ApprovalRequestId,RequestedByUserId,RequestedAt,Description) VALUES (@req,@client,@now,N'Demo correction');
    ROLLBACK;
    INSERT @Results VALUES (N'CorrectionRequests duplicate ApprovalRequestId',N'2627 / UQ_CorrectionRequests_ApprovalRequestId','Statement unexpectedly succeeded','FAIL');
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    INSERT @Results VALUES (N'CorrectionRequests duplicate ApprovalRequestId',N'2627 / UQ_CorrectionRequests_ApprovalRequestId',ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER()=2627 AND CHARINDEX(N'UQ_CorrectionRequests_ApprovalRequestId',ERROR_MESSAGE())>0 THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

SELECT Test, Expected, Actual, Result FROM @Results ORDER BY Test;
IF EXISTS (SELECT 1 FROM @Results WHERE Result='FAIL')
    THROW 51005, 'One or more acceptance tests failed. Review the result grid.', 1;
