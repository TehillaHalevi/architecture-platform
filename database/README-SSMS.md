# הקמת מסד בדיקה לפיילוט האדריכלות

המסד הייעודי הוא `ArchitecturePilot_Acceptance_5E22`. הקבצים כתובים ל־SQL Server ומיועדים לפתיחה ישירה ב־SSMS. כל קובץ הוא אצווה אחת. הריצי את כל הקובץ עם F5. בחירת טקסט חלקית מדלגת על הגנות ההרצה.

**מצב נוכחי** — בוצעה סקירה סטטית. לא היה מופע SQL Server זמין להרצה, ולכן אין תוצאות ממנוע SQL Server או גרסת שרת מדווחת. קובצי 00 ו־02 ידפיסו את הגרסה בפועל. הרכיבים הזמינים למשימה היו שני מסמכי הסכמה, ללא קוד השרת או עובד התור.

## סדר הרצה

| סדר | קובץ | מסד ופעולה | מה צפוי להופיע |
|---|---|---|---|
| 1 | `00-create-test-database.sql` | התחברי למופע **בדיקה** ובחרי `master`. הריצי בחיבור בעל הרשאה ליצור מסד ולהגדיר את מאפיין הסימון. אם ההרשאה נפרדת, מנהל המסד מריץ קובץ זה ומעניק למריץ הבדיקות הרשאות מתאימות במסד הייעודי. | שם המסד החדש מופיע ב־Object Explorer לאחר רענון. מתקבלת שורת גרסה ומהדורה. אם כבר קיים מסד באותו שם, הקובץ עוצר. |
| 2 | `01-create-schema.sql` | בחרי `ArchitecturePilot_Acceptance_5E22` בתיבת המסד והריצי כמשתמש בעל הרשאות DDL מתאימות, למשל `db_owner` במסד הבדיקה בלבד. | `Schema installed`. |
| 3 | `02-verify-catalog.sql` | אותו מסד. הריצי בחיבור בעל גישה למטא־דאטה של כל הטבלאות. | גרסת המנוע ושישה פלטי `PASS`, ולאחריהם הגדרות ה־CHECK. במקרה של פער יופיעו השורות השונות לפני השגיאה. |
| 4 | `03-seed-and-test.sql` | אותו מסד. הריצי פעם אחת בחיבור בעל הרשאות קריאה וכתיבה לנתוני הדמה. | `PASS` על המסלול החיובי ועל כל שורה בגריד הבדיקות. הודעת `FAIL` מציגה את השגיאה בפועל. נתוני הבסיס נשמרים לבדיקות A/B. |
| 5 | `04-session-A.sql` ו־`05-session-B.sql` | פתחי שני חלונות שאילתה בחיבורים נפרדים לאותו מופע, בחרי את מסד הבדיקה בשניהם ובצעי את שני המצבים לפי ההוראות הבאות. | מזהי `SessionId` שונים. A מדווח על Commit ו־B מדווח על תוצאות המירוץ. |

## שני חיבורים ב־SSMS

1. פתחי את קובץ 04 בחלון A ואת קובץ 05 בחלון B. ודאי ששניהם מחוברים למסד הייעודי וש־`@Mode = 1` בשניהם.
2. הריצי את A. ברגע שההודעה `A holds the write lock` מופיעה תחת **Messages**, הריצי את B בחלון השני, בתוך חלון ההמתנה של 20 שניות. B יכול להמתין לסיום הטרנזקציה של A. לאחר מכן B אמור להציג `RowsChanged = 0`, ‏`RequestStatus = 2`, ‏`Approvals = 1`, ‏`Corrections = 0`.
3. אחרי ששני החלונות סיימו, שני את `@Mode` ל־2 בשני הקבצים. הריצי A ושוב הריצי B מיד לאחר ההודעה. B דוחה תפיסה כפולה, ממתין עד פקיעת הבעלות של A, בודק ניסיון השלמה עם האסימון שפג, תופס את הרשומה לאחר סימונה כתוצאה לא ודאית ובודק שוב את האסימון הישן כשהאסימון של B כבר בתוקף.
4. בסוף מצב 2, הצפי הוא לשורה עם `Status = 2`, ‏`AttemptCount = 2`, ‏`SentAt` מלא, מטען ושדות בעלות ריקים, ומפתח פעולה זהה למפתח המקורי. ההשלמה מדמה אישור קבלה אצל ספק. זמן הריצה של שני החלונות במצב זה יחד הוא כ־45 שניות מתחילת התפיסה של A.
5. אם B נעצר כי האות של A כבר שוחרר, או שבדיקה נכשלה אחרי Commit, הסתמכי על מסד בדיקה טרי להרצה מלאה נוספת. שמרי את המסד הקודם לבדיקה, בחרי סיומת חדשה ועדכני באופן עקבי את שם המסד בקובץ 00 ובחמשת קובצי ההרצה האחרים. הקבצים אינם כוללים מחיקת מסד או ניקוי של נתונים קיימים.

החיבור שמריץ את A/B משתמש במנעול יישומי רק כדי לאותת שהכתיבה של A כבר התחילה. שתי פעולות הכתיבה המתחרות מותנות במצב הרשומה. B משחזר גם ניסיונות עדכון ישנים באמצעות אסימון הדמה של A. כל הכתובות הן תחת `example.invalid`. אין חיבור לספק מייל או לאחסון בקבצים.

## סקירת DBA והחלטות מימוש

- **הצלבת מסמכים** — 14 הטבלאות ו־102 העמודות תואמות בשמות, טיפוסים, אורכים ו־NULL. ב־PDF מוצגות ההפניות המורכבות, אך הכותרת מציינת 24 מפתחות זרים. ב־MD, `ApprovalRequests.SketchVersionId` מסומן גם כ־FK ישיר ל־`SketchVersions.SketchVersionId`. שמרתי אותו לצד המפתח המורכב, כך שנוצרו 25 אילוצים. ההפניה הישירה עודפת לוגית, כי ההפניה המורכבת מאמתת את אותו מזהה יחד עם מזהה הסקיצה.
- **במסד** — PK מסוג `int IDENTITY(1,1)`, מפתחות תומכים מורכבים לפני יצירת ה־FK, ברירות מחדל לפי הטבלה במילון, אינדקסים, טווחי מצבים, ייחודיות, עקביות NULL, בדיוק מקור אחד לכל מייל, הגבלת מטען להזמנות וצמד שדות בעלות. קשרים משמרים היסטוריה באמצעות `NO ACTION` ללא מחיקה בשרשרת. האינדקסים המפורשים ממוינים בסדר עולה. המסד יורש את ה־collation של המופע. שדות הזמן נכתבים במפורש בנתיב המתאים. השאילתות משתמשות בהגדרות חיבור הנדרשות לאינדקסים מסוננים. [Microsoft Learn](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-index-transact-sql#required-set-options-for-filtered-indexes)
- **בקוד השרת** — הרשאות ופעולות מעבר, שיוך המאשר לפרויקט, סטטוס הגרסה העדכנית, שיוך וסטטוס גרסת תיקון, תנאי החלופה, תקפות ו־7 ימי תוקף להזמנה, השוואת כתובת מאומתת, יצירה אטומית של האירוע ורשומת התור, ויצירת מייל פנייה לסוג 1 בלבד. ה־DDL בודק שבתור מייל מסוג 1 מצביע על פנייה, והשרת קובע את סוג הפנייה המותרת. ה־DB אוכף תשובה אחת **בכל טבלת תשובה בנפרד**. נתיב הכתיבה בודק הרשאה ומעדכן בקשה פתוחה ומוסיף את התשובה באותה טרנזקציה כדי לקבל תוצאה יחידה גם בין הטבלאות. אין טריגרים או פרוצדורות יישום בסכמה.
- **תור המיילים** — בדיקת SQL מדגימה תפיסה, כתיבה מותנית בבעלות ותוצאה מדומה. סביבת הבדיקה מניחה תמיכת ספק במניעת כפילויות כדי להדגים תפיסה לאחר תוצאה לא ודאית. הבחירה של ספק ומדיניות התאוששות בפועל נותרו באחריות היישום. נדרש אימות תוכניות ביצוע ונפחים עם שאילתות ונתונים מייצגים לפני החלטה על אינדקסים נוספים.
- **אימות קטלוג** — הקובץ משווה עמודות, זהויות, ברירות מחדל, FK ואינדקסים לשורות צפויות, כולל עמודות וסדר במפתחות ופילטרים. לגבי CHECK נבדקים שמות ומצב אכיפה, מודפסות ההגדרות לעיון, וקובץ 03 מפעיל אותן באמצעות ניסיונות כתיבה. מזהי שגיאה ושמות האילוצים מופיעים בפלט כדי להבחין בין דחייה צפויה לכשל אחר.

## דוח בדיקות

עמודת התוצאה בפועל תתמלא בהרצה על SQL Server. בפלט של קובץ 03 כל בדיקה שלילית מפיקה שורה עם האילוץ שציפינו שידחה את הפעולה ותיאור השגיאה שהמנוע החזיר.

| בדיקה | תוצאה צפויה | בפועל | מצב |
|---|---|---|---|
| 00 / יצירת מסד | מסד חדש מסומן ושורת גרסת SQL Server | — | לא הורצה |
| 01 / הקמת סכמה | הקמה אטומית של 14 טבלאות | — | לא הורצה |
| 02 / Columns | 102 עמודות עם טיפוס, אורך, דיוק, NULL ו־IDENTITY צפויים | — | לא הורצה |
| 02 / Identity | 14 עמודות עם seed ו־increment של 1 | — | לא הורצה |
| 02 / Defaults | 12 ברירות מחדל עם ערכים צפויים | — | לא הורצה |
| 02 / ForeignKeys | 25 אילוצים פעילים ומהימנים, סדר עמודות ויעדים נכונים | — | לא הורצה |
| 02 / Checks | 22 אילוצים פעילים ומהימנים והדפסת ההגדרות לעיון | — | לא הורצה |
| 02 / Indexes | 14 PK, ‏12 UQ ו־7 אינדקסים מפורשים, מהם 3 מסוננים | — | לא הורצה |
| 03 / מסלול חיובי | פרויקט עד בקשה פתוחה, הפניות אופציונליות וערכי ברירת מחדל | — | לא הורצה |
| 03 / rollback | שגיאה 515 בעמודת Description לאחר שינוי שורה אחת, הבקשה נשארת פתוחה ואין תשובה | — | לא הורצה |
| Users duplicate GoogleSubject | `2627 / UQ_Users_GoogleSubject` | — | לא הורצה |
| Projects duplicate ArchitectUserId_CreationOperationId | `2627 / UQ_Projects_ArchitectUserId_CreationOperationId` | — | לא הורצה |
| ProjectMembers duplicate ProjectId_UserId | `2627 / UQ_ProjectMembers_ProjectId_UserId` | — | לא הורצה |
| ProjectMembers duplicate OneActiveApprover | `2601 / UX_ProjectMembers_OneActiveApprover` | — | לא הורצה |
| ProjectInvitations duplicate TokenHash | `2627 / UQ_ProjectInvitations_TokenHash` | — | לא הורצה |
| Inquiries duplicate SubmissionOperationId | `2627 / UQ_Inquiries_SubmissionOperationId` | — | לא הורצה |
| SketchVersions duplicate SketchId_VersionNumber | `2627 / UQ_SketchVersions_SketchId_VersionNumber` | — | לא הורצה |
| SketchVersions duplicate OneDraft | `2601 / UX_SketchVersions_OneDraft` | — | לא הורצה |
| ApprovalRequests duplicate OneOpen | `2601 / UX_ApprovalRequests_OneOpen` | — | לא הורצה |
| EmailOutbox duplicate OperationKey | `2627 / UQ_EmailOutbox_OperationKey` | — | לא הורצה |
| Projects cross-parent CurrentStageId | `547 / FK_Projects_CurrentStageId` | — | לא הורצה |
| Sketches cross-parent CurrentVersionId | `547 / FK_Sketches_CurrentVersionId` | — | לא הורצה |
| ProjectInvitations cross-parent AcceptedByProjectMemberId | `547 / FK_ProjectInvitations_AcceptedByProjectMemberId` | — | לא הורצה |
| ApprovalRequests cross-parent SketchId | `547 / FK_ApprovalRequests_SketchId` | — | לא הורצה |
| ProjectMembers AccessStatus | `547 / CK_ProjectMembers_AccessStatus` | — | לא הורצה |
| ProjectInvitations Status | `547 / CK_ProjectInvitations_Status` | — | לא הורצה |
| ProjectStages Status | `547 / CK_ProjectStages_Status` | — | לא הורצה |
| Inquiries Status | `547 / CK_Inquiries_Status` | — | לא הורצה |
| Inquiries InquiryType | `547 / CK_Inquiries_InquiryType` | — | לא הורצה |
| SketchVersions Status | `547 / CK_SketchVersions_Status` | — | לא הורצה |
| ApprovalRequests Status | `547 / CK_ApprovalRequests_Status` | — | לא הורצה |
| SketchThreads Status | `547 / CK_SketchThreads_Status` | — | לא הורצה |
| EmailOutbox Status | `547 / CK_EmailOutbox_Status` | — | לא הורצה |
| EmailOutbox EmailType | `547 / CK_EmailOutbox_EmailType` | — | לא הורצה |
| CorrectionRequests Status | `547 / CK_CorrectionRequests_Status` | — | לא הורצה |
| ProjectInvitations Expiry | `547 / CK_ProjectInvitations_Expiry` | — | לא הורצה |
| Invitation accepted without member | `547 / CK_ProjectInvitations_AcceptedMember` | — | לא הורצה |
| Pending invitation with accepted member | `547 / CK_ProjectInvitations_AcceptedMember` | — | לא הורצה |
| SketchVersions VersionNumber | `547 / CK_SketchVersions_VersionNumber` | — | לא הורצה |
| Published version without timestamp | `547 / CK_SketchVersions_Publication` | — | לא הורצה |
| Draft with publication timestamp | `547 / CK_SketchVersions_Publication` | — | לא הורצה |
| Removed version without publication history | `547 / CK_SketchVersions_Publication` | — | לא הורצה |
| Closed request without reason | `547 / CK_ApprovalRequests_Closure` | — | לא הורצה |
| Closed request with illegal reason | `547 / CK_ApprovalRequests_Closure` | — | לא הורצה |
| Open request with closure reason | `547 / CK_ApprovalRequests_Closure` | — | לא הורצה |
| Resolved correction without version | `547 / CK_CorrectionRequests_Resolution` | — | לא הורצה |
| Open correction with resolved version | `547 / CK_CorrectionRequests_Resolution` | — | לא הורצה |
| EmailOutbox AttemptCount | `547 / CK_EmailOutbox_AttemptCount` | — | לא הורצה |
| Sent mail without provider timestamp | `547 / CK_EmailOutbox_Sent` | — | לא הורצה |
| Pending mail with provider timestamp | `547 / CK_EmailOutbox_Sent` | — | לא הורצה |
| Only LeaseId | `547 / CK_EmailOutbox_Lease` | — | לא הורצה |
| Only LeaseUntil | `547 / CK_EmailOutbox_Lease` | — | לא הורצה |
| Missing mail source | `547 / CK_EmailOutbox_Source` | — | לא הורצה |
| Multiple mail sources | `547 / CK_EmailOutbox_Source` | — | לא הורצה |
| Single mail source of wrong type | `547 / CK_EmailOutbox_Source` | — | לא הורצה |
| Invitation payload on inquiry mail | `547 / CK_EmailOutbox_Payload` | — | לא הורצה |
| Approvals duplicate ApprovalRequestId | `2627 / UQ_Approvals_ApprovalRequestId` | — | לא הורצה |
| CorrectionRequests duplicate ApprovalRequestId | `2627 / UQ_CorrectionRequests_ApprovalRequestId` | — | לא הורצה |
| 04–05 / Mode 1, התנגשות | A מאשר, B משנה אפס שורות למרות ניסיון לבקש תיקון, מצב 2 ותשובה אחת בדיוק | — | לא הורצה |
| 04–05 / Mode 2, תפיסה ראשונה | A תופס את הרשומה, B משנה אפס שורות בניסיון המקביל, מונה הניסיונות הוא 1 | — | לא הורצה |
| 04–05 / Mode 2, בעלות שפגה | עדכון באסימון שפג משנה אפס שורות, מעבר למצב 5 ותפיסה חוזרת בידי B | — | לא הורצה |
| 04–05 / Mode 2, בעלות שהוחלפה | עדכון באסימון הישן משנה אפס שורות | — | לא הורצה |
| 04–05 / Mode 2, קבלה מדומה | סטטוס 2, שני ניסיונות באותה שורה, OperationKey נשמר, SentAt מלא, בעלות ומטען ריקים | — | לא הורצה |
| אינטגרציה | תוצאה צפויה | בפועל | מצב |
|---|---|---|---|
| פרסום גרסה מול אישור, בשני סדרי ההשלמה | אישור ראשון נשאר בהיסטוריה. פרסום ראשון סוגר את הבקשה הישנה והמענה נדחה. | — | לא הורצה |
| הסרת גישה מול כתיבת תגובה, אישור או קבלת PDF | כל כתיבה ובקשת PDF חדשה לאחר ההסרה נדחות. | — | לא הורצה |
| קבלת הזמנה מול החלפתה | קבלה ראשונה שומרת שיוך תקין, או שהחלפה ראשונה פוסלת את הקישור הקודם. | — | לא הורצה |
| חשבון מאומת, הזמנה שפגה וסוג פנייה | התאמת כתובת לפי המילון, הזמנה פגה נדחית, ורק פנייה מסוג 1 מפיקה מייל. | — | לא הורצה |
| עובד תור לאחר הפעלה מחדש | הרשומה והמטען נשארים זמינים לעובד מורשה. שחזור ניסיון משתמש במפתח הפעולה המקורי ובהתנהגות הספק בפועל. | — | לא הורצה |
| עיבוד עם ספק מדומה וניקוי מטען | אישור קבלה, ביטול, החלפה או פקיעה מנקים את המטען בנתיב השרת. מייל שממתין ומקורו בוטל מפסיק להיות זמין לשליחה. | — | לא הורצה |
| מועד יעד בשעון ישראל | תאריך בלבד מסתיים ב־23:59:59.999 מקומי, איחור מתחיל בחצות, והמרת שעה חסרה או כפולה ממתינה לבחירה חד־משמעית. | — | לא הורצה |
| העלאה, החלפה, קיבוע ושחזור PDF פרטי | כתיבת מסד לאחר העלאה, שמירת ההפניה הקודמת בכשל, ניקוי קובץ יתום, הגשה בהרשאה ופתיחת PDF משחזור משולב. | — | לא הורצה |
| החלפת טיוטה במקביל ושמירת טקסט מקומי | החלפה מותנית בסטטוס ובמפתח הקודם. תגובה על גרסה שהתיישנה נדחית והטקסט נשמר בדפדפן. | — | לא הורצה |
