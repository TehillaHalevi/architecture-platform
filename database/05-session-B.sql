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
-- MODE: 1 = approval vs correction. 2 = outbox lease.
-- Set the same mode in A and B. Run the full file in its own SSMS connection.
DECLARE @Mode tinyint = 1;
IF @Mode NOT IN (1,2) OR @Mode IS NULL
    THROW 51011, 'Mode must be 1 or 2.', 1;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET LOCK_TIMEOUT 45000;
SET XACT_ABORT ON;

-- The fixture lookup reads only immutable IDs so B can find its target while A holds locks.
DECLARE @request int, @member int, @sketch int, @actor int, @mail int, @changed int;
DECLARE @resource nvarchar(255)=CONCAT(N'ArchitecturePilot.Acceptance.Mode.',@Mode);
SELECT @request=ApprovalRequestId,@member=ApproverProjectMemberId,@sketch=SketchId
FROM dbo.ApprovalRequests WITH (READUNCOMMITTED) WHERE Instructions=N'pilot-fixture-race';
SELECT @actor=UserId FROM dbo.ProjectMembers WHERE ProjectMemberId=@member;
SELECT @mail=EmailOutboxId FROM dbo.EmailOutbox WITH (READUNCOMMITTED)
WHERE OperationKey=N'51E22000-0000-4000-8000-000000000001';
IF @request IS NULL OR @actor IS NULL OR @mail IS NULL
    THROW 51011, 'Run the seed script before opening the race.', 1;
DECLARE @oldLease uniqueidentifier=N'51E22000-0000-4000-8000-000000000002',
        @newLease uniqueidentifier=N'51E22000-0000-4000-8000-000000000003';

IF ISNULL(APPLOCK_TEST('public',@resource,'Exclusive','Session'),-1)<>0
    THROW 51013, 'A is not holding the test signal. Start B when A prints the prompt.', 1;
DECLARE @started datetime2(3)=SYSUTCDATETIME(), @firstClaimEnded datetime2(3);
BEGIN TRY
    BEGIN TRANSACTION;
    IF @Mode=1
    BEGIN
        -- Demonstration of the server write path. Authorization and response share this transaction.
        IF NOT EXISTS (
            SELECT 1 FROM dbo.ProjectMembers AS m WITH (HOLDLOCK)
            JOIN dbo.Sketches AS s ON s.ProjectId=m.ProjectId
            WHERE m.ProjectMemberId=@member AND m.UserId=@actor
              AND m.AccessStatus=1 AND m.CanApprove=1 AND s.SketchId=@sketch
        )
            THROW 51010, 'Fixture actor lacks approval access.', 1;
        UPDATE dbo.ApprovalRequests
        SET Status=3
        WHERE ApprovalRequestId=@request AND SketchId=@sketch
          AND ApproverProjectMemberId=@member AND Status=1;
        SET @changed=@@ROWCOUNT;
        IF @changed=1
        BEGIN
            INSERT dbo.CorrectionRequests (ApprovalRequestId,RequestedByUserId,RequestedAt,Description)
            VALUES (@request,@actor,SYSUTCDATETIME(),N'Demo correction');
        END;
    END
    ELSE
    BEGIN
        UPDATE dbo.EmailOutbox
        SET LeaseId=@newLease, LeaseUntil=DATEADD(second,45,SYSUTCDATETIME()),
            LastAttemptAt=SYSUTCDATETIME(), AttemptCount=AttemptCount+1
        WHERE EmailOutboxId=@mail AND Status=1 AND LeaseId IS NULL AND LeaseUntil IS NULL;
        SET @changed=@@ROWCOUNT;
    END;
    SET @firstClaimEnded=SYSUTCDATETIME();
    IF @changed<>0
        THROW 51014, 'B unexpectedly changed the row after A began the write.', 1;
    COMMIT;
    SELECT @@SPID AS SessionId,@Mode AS TestMode,DATEDIFF(ms,@started,@firstClaimEnded) AS FirstWriteElapsedMs,
           @changed AS RowsChanged,'PASS: B lost the competing write' AS Result;

    IF @Mode=1
    BEGIN
        DECLARE @approvalCount int=(SELECT COUNT(*) FROM dbo.Approvals WHERE ApprovalRequestId=@request),
                @correctionCount int=(SELECT COUNT(*) FROM dbo.CorrectionRequests WHERE ApprovalRequestId=@request),
                @requestStatus tinyint=(SELECT Status FROM dbo.ApprovalRequests WHERE ApprovalRequestId=@request);
        IF @approvalCount<>1 OR @correctionCount<>0 OR @requestStatus<>2
            THROW 51015, 'Final approval counts or status do not match the winning response.', 1;
        SELECT @requestStatus AS RequestStatus,@approvalCount AS Approvals,@correctionCount AS Corrections,
               'PASS: exactly one response across both tables' AS Result;
    END
    ELSE
    BEGIN
        DECLARE @expires datetime2(3);
        SELECT @expires=LeaseUntil FROM dbo.EmailOutbox
        WHERE EmailOutboxId=@mail AND Status=1 AND LeaseId=@oldLease
          AND AttemptCount=1 AND LastAttemptAt IS NOT NULL;
        IF @expires IS NULL THROW 51016, 'Only A should own the first claim.', 1;
        WHILE SYSUTCDATETIME()<@expires
            WAITFOR DELAY '00:00:01';

        BEGIN TRANSACTION;
        -- Replay a late completion from A while its own token is still stored.
        UPDATE dbo.EmailOutbox
        SET Status=2, SentAt=SYSUTCDATETIME(), LeaseId=NULL, LeaseUntil=NULL,
            EncryptedInvitationPayload=NULL
        WHERE EmailOutboxId=@mail AND LeaseId=@oldLease AND LeaseUntil>SYSUTCDATETIME();
        IF @@ROWCOUNT<>0 THROW 51017, 'An expired lease was allowed to complete.', 1;

        UPDATE dbo.EmailOutbox
        SET Status=5, LeaseId=NULL, LeaseUntil=NULL, LastErrorCode=N'fixture_lease_expired'
        WHERE EmailOutboxId=@mail AND Status=1 AND LeaseId=@oldLease
          AND LeaseUntil<=SYSUTCDATETIME() AND LastAttemptAt IS NOT NULL;
        IF @@ROWCOUNT<>1 THROW 51018, 'Expired in-flight attempt did not become uncertain.', 1;

        -- A test-only provider deduplication assumption permits retrying status 5.
        -- No provider is contacted. The stable OperationKey is verified at the end.
        UPDATE dbo.EmailOutbox
        SET LeaseId=@newLease, LeaseUntil=DATEADD(second,45,SYSUTCDATETIME()),
            LastAttemptAt=SYSUTCDATETIME(), AttemptCount=AttemptCount+1
        WHERE EmailOutboxId=@mail AND Status=5 AND LeaseId IS NULL AND LeaseUntil IS NULL;
        SET @changed=@@ROWCOUNT;
        IF @changed<>1 THROW 51019, 'B could not claim the reconciled record.', 1;
        COMMIT;
        SELECT @expires AS ExpiredAtUtc,'PASS: expired owner rejected and B took ownership' AS Result;

        BEGIN TRANSACTION;
        -- Replay A again while B holds a live lease. A must not write using its old token.
        UPDATE dbo.EmailOutbox
        SET Status=2, SentAt=SYSUTCDATETIME(), LeaseId=NULL, LeaseUntil=NULL,
            EncryptedInvitationPayload=NULL
        WHERE EmailOutboxId=@mail AND LeaseId=@oldLease AND LeaseUntil>SYSUTCDATETIME();
        IF @@ROWCOUNT<>0 THROW 51020, 'An old lease token was allowed to complete.', 1;

        UPDATE dbo.EmailOutbox
        SET Status=2, SentAt=SYSUTCDATETIME(), LeaseId=NULL, LeaseUntil=NULL,
            EncryptedInvitationPayload=NULL, LastErrorCode=NULL
        WHERE EmailOutboxId=@mail AND Status=5 AND LeaseId=@newLease AND LeaseUntil>SYSUTCDATETIME();
        IF @@ROWCOUNT<>1 THROW 51021, 'B could not record simulated provider acceptance.', 1;
        IF NOT EXISTS (
            SELECT 1 FROM dbo.EmailOutbox
            WHERE EmailOutboxId=@mail AND OperationKey=N'51E22000-0000-4000-8000-000000000001'
              AND Status=2 AND AttemptCount=2 AND SentAt IS NOT NULL
              AND EncryptedInvitationPayload IS NULL AND LeaseId IS NULL AND LeaseUntil IS NULL
        ) THROW 51022, 'Final outbox row does not match the expected result.', 1;
        COMMIT;
        SELECT Status,AttemptCount,SentAt,LeaseId,LeaseUntil,EncryptedInvitationPayload,OperationKey,
               'PASS: superseded owner rejected and simulated acceptance cleared payload' AS Result
        FROM dbo.EmailOutbox WHERE EmailOutboxId=@mail;
    END;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    THROW;
END CATCH;
