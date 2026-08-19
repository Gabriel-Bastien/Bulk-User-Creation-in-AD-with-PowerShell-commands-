# Setup Guide: Bulk AD User Creation Walkthrough

This walkthrough documents, step by step, how a real onboarding ticket was resolved using a Google Sheet roster, a CSV export, and a PowerShell bulk-creation script.

## 1. Start from the ticket

The request came in through the helpdesk: HR needed roughly 50 AD accounts created before Monday's onboarding.

![Support ticket requesting bulk user creation](screenshots/01-support-ticket.png)

Key details to pull out of any ticket like this before you start:
- How many accounts, and by when
- Which departments/OUs they belong to
- Whether temporary passwords need to be pre-set or reset at first logon

## 2. Build the roster in Google Sheets

A shared Google Sheet ("User Creation CSV Sheet") acts as the single source of truth that HR and IT both edit. Start with a header row for the fields the script will need.

![Blank Google Sheet with column headers](screenshots/02-sheet-setup.png)

To keep usernames consistent, generate them with a formula instead of typing them by hand — this sheet uses first initial + last name, lowercased:

```
=LOWER(LEFT(A2,1) & B2)
```

![Username generated with a formula](screenshots/03-username-formula.png)

Once every row has a first name, last name, username, target OU (as a full distinguished name), description, and temporary password, the sheet is ready to export.

![Fully populated sheet with OU distinguished names](screenshots/04-sheet-populated-with-ou.png)

> **Note:** the `OU` column must be the full distinguished name AD expects, e.g. `OU=HR,DC=yourdomain,DC=com` — not just the department name.

## 3. Export to CSV

Use **File → Download → Comma Separated Values (.csv)** in Google Sheets, then move the file to the machine you'll run the script from (in this case, straight to `Downloads`).

![CSV exported to the Downloads folder](screenshots/05-export-csv-download.png)

## 4. Review the PowerShell script

The script (`scripts/New-BulkADUsers.ps1` in this repo) imports the CSV, builds a UPN and display name per row, checks whether the account already exists, and creates it with `New-ADUser`.

![PowerShell script contents](screenshots/06-powershell-script.png)

Before running it, update the two variables at the top:

```powershell
$CSVPath      = "C:\path\to\users.csv"
$DomainSuffix = "yourdomain.com"
```

## 5. Run the script

From an elevated PowerShell session with the Active Directory module loaded (`Import-Module ActiveDirectory`), execute the script against the exported CSV.

![Script running in the PowerShell console](screenshots/07-script-execution.png)

Each successfully created account is printed to the console in green:

![Console output confirming each user was created](screenshots/08-successful-output.png)

If a row is missing a username, or an account with that SamAccountName already exists, the script logs a warning and moves on to the next row instead of stopping the whole batch.

## 6. Verify in Active Directory Users and Computers

Spot-check a few of the target OUs to confirm accounts landed in the right place with the right description.

![New user visible in the correct OU in ADUC](screenshots/09-ad-verification-hr-ou.png)

## 7. Close the loop on the ticket

Reply to the original ticket to confirm the accounts are ready, including any follow-up notes (e.g. default passwords, forced password change at first logon).

![Reply to the ticket confirming completion](screenshots/10-ticket-resolved-reply.png)

Mark the ticket solved once the requester confirms there's nothing else needed.

![Ticket marked as solved](screenshots/11-ticket-solved.png)

## Troubleshooting notes

- **"User already exists" warnings** are expected if the script is re-run against the same CSV — it's a safety check, not an error.
- **Failed creations** print the underlying AD error via `Write-Error`, which usually points to an invalid `OU` distinguished name or a password that doesn't meet the domain's complexity policy.
- Passwords in the CSV are cleartext until the moment the script converts them with `ConvertTo-SecureString` — treat the exported CSV as sensitive and delete it once the run is complete.
