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
BEGIN TRY
    BEGIN TRANSACTION;
    IF EXISTS (SELECT 1 FROM sys.objects WHERE is_ms_shipped = 0 AND type IN ('U','V','P','FN','IF','TF','SN'))
        THROW 51002, 'Schema installation requires an empty test database.', 1;

CREATE TABLE dbo.Users (
    UserId int IDENTITY(1,1) NOT NULL,
    DisplayName nvarchar(150) NOT NULL,
    Email nvarchar(254) NOT NULL,
    GoogleSubject nvarchar(255) NOT NULL,
    CONSTRAINT PK_Users PRIMARY KEY CLUSTERED (UserId),
    CONSTRAINT UQ_Users_GoogleSubject UNIQUE (GoogleSubject)
);

CREATE TABLE dbo.Projects (
    ProjectId int IDENTITY(1,1) NOT NULL,
    ArchitectUserId int NOT NULL,
    CurrentStageId int NULL,
    CreationOperationId uniqueidentifier NOT NULL,
    ProjectName nvarchar(200) NOT NULL,
    ClientName nvarchar(150) NOT NULL,
    ClientEmail nvarchar(254) NOT NULL,
    ClientPhone nvarchar(32) NOT NULL,
    LocationOrNote nvarchar(250) NULL,
    CreatedAt datetime2(3) NOT NULL,
    CONSTRAINT PK_Projects PRIMARY KEY CLUSTERED (ProjectId),
    CONSTRAINT UQ_Projects_ArchitectUserId_CreationOperationId UNIQUE (ArchitectUserId, CreationOperationId)
);

CREATE TABLE dbo.ProjectMembers (
    ProjectMemberId int IDENTITY(1,1) NOT NULL,
    ProjectId int NOT NULL,
    UserId int NOT NULL,
    AccessStatus tinyint NOT NULL CONSTRAINT DF_ProjectMembers_AccessStatus DEFAULT (1),
    CanApprove bit NOT NULL CONSTRAINT DF_ProjectMembers_CanApprove DEFAULT (0),
    CONSTRAINT PK_ProjectMembers PRIMARY KEY CLUSTERED (ProjectMemberId),
    CONSTRAINT UQ_ProjectMembers_ProjectId_UserId UNIQUE (ProjectId, UserId),
    CONSTRAINT UQ_ProjectMembers_ProjectId_ProjectMemberId UNIQUE (ProjectId, ProjectMemberId),
    CONSTRAINT CK_ProjectMembers_AccessStatus CHECK (AccessStatus IN (1, 2))
);

CREATE TABLE dbo.ProjectInvitations (
    InvitationId int IDENTITY(1,1) NOT NULL,
    ProjectId int NOT NULL,
    InvitedEmail nvarchar(254) NOT NULL,
    CanApprove bit NOT NULL CONSTRAINT DF_ProjectInvitations_CanApprove DEFAULT (0),
    Status tinyint NOT NULL CONSTRAINT DF_ProjectInvitations_Status DEFAULT (1),
    ExpiresAt datetime2(3) NOT NULL,
    IssuedAt datetime2(3) NOT NULL,
    TokenHash binary(32) NOT NULL,
    AcceptedByProjectMemberId int NULL,
    CONSTRAINT PK_ProjectInvitations PRIMARY KEY CLUSTERED (InvitationId),
    CONSTRAINT UQ_ProjectInvitations_TokenHash UNIQUE (TokenHash),
    CONSTRAINT CK_ProjectInvitations_Status CHECK (Status IN (1, 2, 3, 4)),
    CONSTRAINT CK_ProjectInvitations_Expiry CHECK (ExpiresAt > IssuedAt),
    CONSTRAINT CK_ProjectInvitations_AcceptedMember CHECK ((Status = 2 AND AcceptedByProjectMemberId IS NOT NULL) OR (Status <> 2 AND AcceptedByProjectMemberId IS NULL))
);

CREATE TABLE dbo.ProjectStages (
    ProjectStageId int IDENTITY(1,1) NOT NULL,
    ProjectId int NOT NULL,
    StageName nvarchar(150) NOT NULL,
    SortOrder int NOT NULL,
    Status tinyint NOT NULL CONSTRAINT DF_ProjectStages_Status DEFAULT (1),
    DueAt datetime2(3) NULL,
    CONSTRAINT PK_ProjectStages PRIMARY KEY CLUSTERED (ProjectStageId),
    CONSTRAINT UQ_ProjectStages_ProjectId_ProjectStageId UNIQUE (ProjectId, ProjectStageId),
    CONSTRAINT CK_ProjectStages_Status CHECK (Status IN (1, 2, 3))
);

CREATE TABLE dbo.Inquiries (
    InquiryId int IDENTITY(1,1) NOT NULL,
    SubmissionOperationId uniqueidentifier NOT NULL,
    InquiryType tinyint NOT NULL,
    ProjectName nvarchar(200) NULL,
    ContactName nvarchar(150) NOT NULL,
    Email nvarchar(254) NOT NULL,
    Description nvarchar(2000) NOT NULL,
    Phone nvarchar(32) NULL,
    City nvarchar(100) NULL,
    ExpectedStart nvarchar(100) NULL,
    Status tinyint NOT NULL CONSTRAINT DF_Inquiries_Status DEFAULT (1),
    CreatedAt datetime2(3) NOT NULL,
    CONSTRAINT PK_Inquiries PRIMARY KEY CLUSTERED (InquiryId),
    CONSTRAINT UQ_Inquiries_SubmissionOperationId UNIQUE (SubmissionOperationId),
    CONSTRAINT CK_Inquiries_Status CHECK (Status IN (1, 2)),
    CONSTRAINT CK_Inquiries_InquiryType CHECK (InquiryType IN (1, 2))
);

CREATE TABLE dbo.Sketches (
    SketchId int IDENTITY(1,1) NOT NULL,
    ProjectId int NOT NULL,
    CurrentVersionId int NULL,
    SketchName nvarchar(200) NOT NULL,
    CONSTRAINT PK_Sketches PRIMARY KEY CLUSTERED (SketchId)
);

CREATE TABLE dbo.SketchVersions (
    SketchVersionId int IDENTITY(1,1) NOT NULL,
    SketchId int NOT NULL,
    VersionNumber int NOT NULL,
    PdfStorageKey nvarchar(512) NOT NULL,
    Status tinyint NOT NULL CONSTRAINT DF_SketchVersions_Status DEFAULT (1),
    PublishedAt datetime2(3) NULL,
    CONSTRAINT PK_SketchVersions PRIMARY KEY CLUSTERED (SketchVersionId),
    CONSTRAINT UQ_SketchVersions_SketchId_VersionNumber UNIQUE (SketchId, VersionNumber),
    CONSTRAINT UQ_SketchVersions_SketchId_SketchVersionId UNIQUE (SketchId, SketchVersionId),
    CONSTRAINT CK_SketchVersions_Status CHECK (Status IN (1, 2, 3)),
    CONSTRAINT CK_SketchVersions_VersionNumber CHECK (VersionNumber > 0),
    CONSTRAINT CK_SketchVersions_Publication CHECK (Status NOT IN (1, 2, 3) OR (Status = 1 AND PublishedAt IS NULL) OR (Status IN (2, 3) AND PublishedAt IS NOT NULL))
);

CREATE TABLE dbo.ApprovalRequests (
    ApprovalRequestId int IDENTITY(1,1) NOT NULL,
    SketchVersionId int NOT NULL,
    SketchId int NOT NULL,
    ApproverProjectMemberId int NOT NULL,
    AlternativeLabel nvarchar(150) NULL,
    Status tinyint NOT NULL CONSTRAINT DF_ApprovalRequests_Status DEFAULT (1),
    ClosedReason tinyint NULL,
    DueAt datetime2(3) NULL,
    Instructions nvarchar(2000) NULL,
    CreatedAt datetime2(3) NOT NULL,
    CONSTRAINT PK_ApprovalRequests PRIMARY KEY CLUSTERED (ApprovalRequestId),
    CONSTRAINT CK_ApprovalRequests_Status CHECK (Status IN (1, 2, 3, 4)),
    CONSTRAINT CK_ApprovalRequests_Closure CHECK ((Status = 4 AND ClosedReason IS NOT NULL AND ClosedReason IN (1, 2, 3, 4)) OR (Status <> 4 AND ClosedReason IS NULL))
);

CREATE TABLE dbo.Approvals (
    ApprovalId int IDENTITY(1,1) NOT NULL,
    ApprovalRequestId int NOT NULL,
    ApprovedByUserId int NOT NULL,
    ApprovedAt datetime2(3) NOT NULL,
    CONSTRAINT PK_Approvals PRIMARY KEY CLUSTERED (ApprovalId),
    CONSTRAINT UQ_Approvals_ApprovalRequestId UNIQUE (ApprovalRequestId)
);

CREATE TABLE dbo.CorrectionRequests (
    CorrectionRequestId int IDENTITY(1,1) NOT NULL,
    ApprovalRequestId int NOT NULL,
    RequestedByUserId int NOT NULL,
    RequestedAt datetime2(3) NOT NULL,
    ResolvedInVersionId int NULL,
    Description nvarchar(4000) NOT NULL,
    Status tinyint NOT NULL CONSTRAINT DF_CorrectionRequests_Status DEFAULT (1),
    CONSTRAINT PK_CorrectionRequests PRIMARY KEY CLUSTERED (CorrectionRequestId),
    CONSTRAINT UQ_CorrectionRequests_ApprovalRequestId UNIQUE (ApprovalRequestId),
    CONSTRAINT CK_CorrectionRequests_Status CHECK (Status IN (1, 2)),
    CONSTRAINT CK_CorrectionRequests_Resolution CHECK (Status NOT IN (1, 2) OR (Status = 2 AND ResolvedInVersionId IS NOT NULL) OR (Status = 1 AND ResolvedInVersionId IS NULL))
);

CREATE TABLE dbo.SketchThreads (
    SketchThreadId int IDENTITY(1,1) NOT NULL,
    SketchVersionId int NOT NULL,
    ResolvedInVersionId int NULL,
    Status tinyint NOT NULL CONSTRAINT DF_SketchThreads_Status DEFAULT (1),
    CONSTRAINT PK_SketchThreads PRIMARY KEY CLUSTERED (SketchThreadId),
    CONSTRAINT CK_SketchThreads_Status CHECK (Status IN (1, 2))
);

CREATE TABLE dbo.SketchMessages (
    SketchMessageId int IDENTITY(1,1) NOT NULL,
    SketchThreadId int NOT NULL,
    AuthorUserId int NOT NULL,
    Body nvarchar(4000) NOT NULL,
    CreatedAt datetime2(3) NOT NULL,
    CONSTRAINT PK_SketchMessages PRIMARY KEY CLUSTERED (SketchMessageId)
);

CREATE TABLE dbo.EmailOutbox (
    EmailOutboxId int IDENTITY(1,1) NOT NULL,
    OperationKey uniqueidentifier NOT NULL,
    EmailType tinyint NOT NULL,
    RecipientEmail nvarchar(254) NOT NULL,
    InquiryId int NULL,
    InvitationId int NULL,
    ApprovalRequestId int NULL,
    Status tinyint NOT NULL CONSTRAINT DF_EmailOutbox_Status DEFAULT (1),
    AttemptCount int NOT NULL CONSTRAINT DF_EmailOutbox_AttemptCount DEFAULT (0),
    CreatedAt datetime2(3) NOT NULL,
    LastAttemptAt datetime2(3) NULL,
    SentAt datetime2(3) NULL,
    EncryptedInvitationPayload varbinary(max) NULL,
    LeaseId uniqueidentifier NULL,
    LeaseUntil datetime2(3) NULL,
    LastErrorCode nvarchar(100) NULL,
    CONSTRAINT PK_EmailOutbox PRIMARY KEY CLUSTERED (EmailOutboxId),
    CONSTRAINT UQ_EmailOutbox_OperationKey UNIQUE (OperationKey),
    CONSTRAINT CK_EmailOutbox_Status CHECK (Status IN (1, 2, 3, 4, 5)),
    CONSTRAINT CK_EmailOutbox_EmailType CHECK (EmailType IN (1, 2, 3, 4)),
    CONSTRAINT CK_EmailOutbox_AttemptCount CHECK (AttemptCount >= 0),
    CONSTRAINT CK_EmailOutbox_Sent CHECK ((Status = 2 AND SentAt IS NOT NULL) OR (Status <> 2 AND SentAt IS NULL)),
    CONSTRAINT CK_EmailOutbox_Lease CHECK ((LeaseId IS NULL AND LeaseUntil IS NULL) OR (LeaseId IS NOT NULL AND LeaseUntil IS NOT NULL)),
    CONSTRAINT CK_EmailOutbox_Payload CHECK (EncryptedInvitationPayload IS NULL OR (EmailType = 2 AND EncryptedInvitationPayload IS NOT NULL)),
    CONSTRAINT CK_EmailOutbox_Source CHECK (EmailType NOT IN (1, 2, 3, 4)
        OR (EmailType = 1 AND InquiryId IS NOT NULL AND InvitationId IS NULL AND ApprovalRequestId IS NULL)
        OR (EmailType = 2 AND InquiryId IS NULL AND InvitationId IS NOT NULL AND ApprovalRequestId IS NULL)
        OR (EmailType IN (3, 4) AND InquiryId IS NULL AND InvitationId IS NULL AND ApprovalRequestId IS NOT NULL))
);

ALTER TABLE dbo.Projects WITH CHECK ADD CONSTRAINT FK_Projects_ArchitectUserId
    FOREIGN KEY (ArchitectUserId) REFERENCES dbo.Users (UserId);

ALTER TABLE dbo.ProjectMembers WITH CHECK ADD CONSTRAINT FK_ProjectMembers_ProjectId
    FOREIGN KEY (ProjectId) REFERENCES dbo.Projects (ProjectId);

ALTER TABLE dbo.ProjectMembers WITH CHECK ADD CONSTRAINT FK_ProjectMembers_UserId
    FOREIGN KEY (UserId) REFERENCES dbo.Users (UserId);

ALTER TABLE dbo.ProjectInvitations WITH CHECK ADD CONSTRAINT FK_ProjectInvitations_ProjectId
    FOREIGN KEY (ProjectId) REFERENCES dbo.Projects (ProjectId);

ALTER TABLE dbo.ProjectInvitations WITH CHECK ADD CONSTRAINT FK_ProjectInvitations_AcceptedByProjectMemberId
    FOREIGN KEY (ProjectId, AcceptedByProjectMemberId) REFERENCES dbo.ProjectMembers (ProjectId, ProjectMemberId);

ALTER TABLE dbo.ProjectStages WITH CHECK ADD CONSTRAINT FK_ProjectStages_ProjectId
    FOREIGN KEY (ProjectId) REFERENCES dbo.Projects (ProjectId);

ALTER TABLE dbo.Sketches WITH CHECK ADD CONSTRAINT FK_Sketches_ProjectId
    FOREIGN KEY (ProjectId) REFERENCES dbo.Projects (ProjectId);

ALTER TABLE dbo.SketchVersions WITH CHECK ADD CONSTRAINT FK_SketchVersions_SketchId
    FOREIGN KEY (SketchId) REFERENCES dbo.Sketches (SketchId);

ALTER TABLE dbo.ApprovalRequests WITH CHECK ADD CONSTRAINT FK_ApprovalRequests_SketchVersionId
    FOREIGN KEY (SketchVersionId) REFERENCES dbo.SketchVersions (SketchVersionId);

ALTER TABLE dbo.ApprovalRequests WITH CHECK ADD CONSTRAINT FK_ApprovalRequests_SketchId
    FOREIGN KEY (SketchId, SketchVersionId) REFERENCES dbo.SketchVersions (SketchId, SketchVersionId);

ALTER TABLE dbo.ApprovalRequests WITH CHECK ADD CONSTRAINT FK_ApprovalRequests_ApproverProjectMemberId
    FOREIGN KEY (ApproverProjectMemberId) REFERENCES dbo.ProjectMembers (ProjectMemberId);

ALTER TABLE dbo.Approvals WITH CHECK ADD CONSTRAINT FK_Approvals_ApprovalRequestId
    FOREIGN KEY (ApprovalRequestId) REFERENCES dbo.ApprovalRequests (ApprovalRequestId);

ALTER TABLE dbo.Approvals WITH CHECK ADD CONSTRAINT FK_Approvals_ApprovedByUserId
    FOREIGN KEY (ApprovedByUserId) REFERENCES dbo.Users (UserId);

ALTER TABLE dbo.CorrectionRequests WITH CHECK ADD CONSTRAINT FK_CorrectionRequests_ApprovalRequestId
    FOREIGN KEY (ApprovalRequestId) REFERENCES dbo.ApprovalRequests (ApprovalRequestId);

ALTER TABLE dbo.CorrectionRequests WITH CHECK ADD CONSTRAINT FK_CorrectionRequests_RequestedByUserId
    FOREIGN KEY (RequestedByUserId) REFERENCES dbo.Users (UserId);

ALTER TABLE dbo.CorrectionRequests WITH CHECK ADD CONSTRAINT FK_CorrectionRequests_ResolvedInVersionId
    FOREIGN KEY (ResolvedInVersionId) REFERENCES dbo.SketchVersions (SketchVersionId);

ALTER TABLE dbo.SketchThreads WITH CHECK ADD CONSTRAINT FK_SketchThreads_SketchVersionId
    FOREIGN KEY (SketchVersionId) REFERENCES dbo.SketchVersions (SketchVersionId);

ALTER TABLE dbo.SketchThreads WITH CHECK ADD CONSTRAINT FK_SketchThreads_ResolvedInVersionId
    FOREIGN KEY (ResolvedInVersionId) REFERENCES dbo.SketchVersions (SketchVersionId);

ALTER TABLE dbo.SketchMessages WITH CHECK ADD CONSTRAINT FK_SketchMessages_SketchThreadId
    FOREIGN KEY (SketchThreadId) REFERENCES dbo.SketchThreads (SketchThreadId);

ALTER TABLE dbo.SketchMessages WITH CHECK ADD CONSTRAINT FK_SketchMessages_AuthorUserId
    FOREIGN KEY (AuthorUserId) REFERENCES dbo.Users (UserId);

ALTER TABLE dbo.EmailOutbox WITH CHECK ADD CONSTRAINT FK_EmailOutbox_InquiryId
    FOREIGN KEY (InquiryId) REFERENCES dbo.Inquiries (InquiryId);

ALTER TABLE dbo.EmailOutbox WITH CHECK ADD CONSTRAINT FK_EmailOutbox_InvitationId
    FOREIGN KEY (InvitationId) REFERENCES dbo.ProjectInvitations (InvitationId);

ALTER TABLE dbo.EmailOutbox WITH CHECK ADD CONSTRAINT FK_EmailOutbox_ApprovalRequestId
    FOREIGN KEY (ApprovalRequestId) REFERENCES dbo.ApprovalRequests (ApprovalRequestId);

ALTER TABLE dbo.Projects WITH CHECK ADD CONSTRAINT FK_Projects_CurrentStageId
    FOREIGN KEY (ProjectId, CurrentStageId) REFERENCES dbo.ProjectStages (ProjectId, ProjectStageId);

ALTER TABLE dbo.Sketches WITH CHECK ADD CONSTRAINT FK_Sketches_CurrentVersionId
    FOREIGN KEY (SketchId, CurrentVersionId) REFERENCES dbo.SketchVersions (SketchId, SketchVersionId);

CREATE UNIQUE INDEX UX_SketchVersions_OneDraft ON dbo.SketchVersions (SketchId) WHERE Status = 1;

CREATE UNIQUE INDEX UX_ApprovalRequests_OneOpen ON dbo.ApprovalRequests (SketchId) WHERE Status = 1;

CREATE UNIQUE INDEX UX_ProjectMembers_OneActiveApprover ON dbo.ProjectMembers (ProjectId) WHERE AccessStatus = 1 AND CanApprove = 1;

CREATE INDEX IX_Projects_Architect ON dbo.Projects (ArchitectUserId, CreatedAt, ProjectId);

CREATE INDEX IX_ProjectMembers_User ON dbo.ProjectMembers (UserId, AccessStatus, ProjectId);

CREATE INDEX IX_SketchMessages_Thread ON dbo.SketchMessages (SketchThreadId, CreatedAt, SketchMessageId);

CREATE INDEX IX_EmailOutbox_Queue ON dbo.EmailOutbox (Status, LeaseUntil, CreatedAt, EmailOutboxId);
    COMMIT;
    SELECT 'Schema installed' AS Result;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK;
    THROW;
END CATCH;
