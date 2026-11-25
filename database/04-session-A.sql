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

-- The app lock is a test signal only. The competing writes use normal row locks.
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
        SET Status=2
        WHERE ApprovalRequestId=@request AND SketchId=@sketch
          AND ApproverProjectMemberId=@member AND Status=1;
        SET @changed=@@ROWCOUNT;
        IF @changed=1
        BEGIN
            INSERT dbo.Approvals (ApprovalRequestId,ApprovedByUserId,ApprovedAt)
            VALUES (@request,@actor,SYSUTCDATETIME());
        END;
    END
    ELSE
    BEGIN
        UPDATE dbo.EmailOutbox
        SET LeaseId=@oldLease, LeaseUntil=DATEADD(second,45,SYSUTCDATETIME()),
            LastAttemptAt=SYSUTCDATETIME(), AttemptCount=AttemptCount+1
        WHERE EmailOutboxId=@mail AND Status=1 AND LeaseId IS NULL AND LeaseUntil IS NULL;
        SET @changed=@@ROWCOUNT;
    END;
    IF @changed<>1 THROW 51012, 'A must win on a fresh fixture.', 1;

    DECLARE @lockResult int;
    EXEC @lockResult=sys.sp_getapplock @Resource=@resource, @LockMode='Exclusive',
        @LockOwner='Transaction', @LockTimeout=0;
    IF @lockResult<0 THROW 51012, 'Could not signal the A window.', 1;
    RAISERROR(N'A holds the write lock. Execute B now in a separate window.',10,1) WITH NOWAIT;
    WAITFOR DELAY '00:00:20';
    COMMIT;
    SELECT @@SPID AS SessionId,@Mode AS TestMode,'A committed' AS Result;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK;
    THROW;
END CATCH;
