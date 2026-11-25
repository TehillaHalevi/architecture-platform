-- 00-create-test-database.sql
-- מטרה: ליצור מסד בדיקה לפיילוט האדריכלות.
-- להרצה ב־SSMS: בחרי master בראש חלון השאילתה והריצי את הקובץ כולו.

-- ודאי שהחיבור נמצא ב־master ושאין טרנזקציה פתוחה.
IF DB_NAME() <> N'master' OR @@TRANCOUNT <> 0
    THROW 51000, 'Select master in a clean query connection.', 1;

-- עצרי אם כבר יש מסד בשם הזה כדי להגן על המסד הקיים.
IF DB_ID(N'ArchitecturePilot_Acceptance_5E22') IS NOT NULL
    THROW 51000, 'Pilot database already exists. This script will not change it.', 1;

-- כבי טרנזקציות אוטומטיות בחיבור לקראת יצירת המסד.
SET IMPLICIT_TRANSACTIONS OFF;

BEGIN TRY
    -- צרי את מסד הבדיקה.
    EXEC(N'CREATE DATABASE [ArchitecturePilot_Acceptance_5E22]');

    -- הוסיפי סימון שקובצי ההמשך משתמשים בו כדי לזהות את מסד הבדיקה.
    EXEC [ArchitecturePilot_Acceptance_5E22].sys.sp_addextendedproperty
        @name = N'ArchitecturePilot.Acceptance.5E22', @value = N'1';
END TRY
BEGIN CATCH
    -- העבירי את שגיאת ההרצה המקורית ל־SSMS.
    THROW;
END CATCH;

-- הציגי ב־Results את הגרסה והמהדורה של שרת SQL Server.
SELECT CONVERT(nvarchar(128), SERVERPROPERTY('ProductVersion')) AS ProductVersion,
       CONVERT(nvarchar(128), SERVERPROPERTY('Edition')) AS Edition,
       @@VERSION AS VersionDetails;