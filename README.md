# Active Directory Bulk User Creation

Resolve mass employee-onboarding requests by generating Active Directory accounts in bulk from a Google Sheet, exported as CSV and processed with a PowerShell script.

This repo documents the exact workflow used to close a real support ticket — **"Bulk User Creation Needed For Mass Employee Onboarding"** — where HR requested ~50 new AD accounts ahead of a Monday onboarding.

## Repo contents

| Path | Purpose |
|---|---|
| [`scripts/New-BulkADUsers.ps1`](scripts/New-BulkADUsers.ps1) | The bulk-creation script |
| [`sample-data/users-template.csv`](sample-data/users-template.csv) | CSV template matching the script's expected columns |
| `docs/screenshots/` | Screenshots captured from the resolution |

## CSV schema

The script expects these columns (header row required):

| Column | Description |
|---|---|
| `Firstname` | User's first name |
| `Lastname` | User's last name |
| `Username` | SamAccountName / login (e.g. generated as first initial + last name) |
| `OU` | Full distinguished name of the target OU, e.g. `OU=HR,DC=yourdomain,DC=com` |
| `Description` | Account description field |
| `Password` | Initial cleartext password (converted to a secure string at runtime; user is forced to change it at next logon) |

## Quick start

```powershell
# 1. Edit the two variables at the top of the script
$CSVPath      = "C:\path\to\users.csv"
$DomainSuffix = "yourdomain.com"

# 2. Run it from an elevated PowerShell session on a machine with the
#    Active Directory module (RSAT) installed
.\scripts\New-BulkADUsers.ps1
```

Each row prints a green **"Successfully created user..."** line on success, a yellow warning if the username is missing or the account already exists, and a red error with the exception reason if creation fails.

## Requirements

- Windows Server with the **Active Directory module for PowerShell** (RSAT), or a workstation with RSAT installed
- An account with permission to create users in the target OUs
- PowerShell 5.1+

---

## Walkthrough

### 1. Start from the ticket

The request came in through the helpdesk: HR needed roughly 50 AD accounts created before Monday's onboarding.

![Support ticket requesting bulk user creation](docs/screenshots/01-support-ticket.png)

Key details to pull out of any ticket like this before you start:
- How many accounts, and by when
- Which departments/OUs they belong to
- Whether temporary passwords need to be pre-set or reset at first logon

### 2. Build the roster in Google Sheets

A shared Google Sheet ("User Creation CSV Sheet") acts as the single source of truth that HR and IT both edit. Start with a header row for the fields the script will need.

![Blank Google Sheet with column headers](docs/screenshots/02-sheet-setup.png)

To keep usernames consistent, generate them with a formula instead of typing them by hand — this sheet uses first initial + last name, lowercased:

```
=LOWER(LEFT(A2,1) & B2)
```

![Username generated with a formula](docs/screenshots/03-username-formula.png)

Once every row has a first name, last name, username, target OU (as a full distinguished name), description, and temporary password, the sheet is ready to export.

![Fully populated sheet with OU distinguished names](docs/screenshots/04-sheet-populated-with-ou.png)

> **Note:** the `OU` column must be the full distinguished name AD expects, e.g. `OU=HR,DC=yourdomain,DC=com` — not just the department name.

### 3. Export to CSV

Use **File → Download → Comma Separated Values (.csv)** in Google Sheets, then move the file to the machine you'll run the script from (in this case, straight to `Downloads`).

![CSV exported to the Downloads folder](docs/screenshots/05-export-csv-download.png)

### 4. Review the PowerShell script

The script ([`scripts/New-BulkADUsers.ps1`](scripts/New-BulkADUsers.ps1)) imports the CSV, builds a UPN and display name per row, checks whether the account already exists, and creates it with `New-ADUser`.

![PowerShell script contents](docs/screenshots/06-powershell-script.png)

Before running it, update the two variables at the top:

```powershell
$CSVPath      = "C:\path\to\users.csv"
$DomainSuffix = "yourdomain.com"
```

### 5. Run the script

From an elevated PowerShell session with the Active Directory module loaded (`Import-Module ActiveDirectory`), execute the script against the exported CSV.

![Script running in the PowerShell console](docs/screenshots/07-script-execution.png)

Each successfully created account is printed to the console in green:

![Console output confirming each user was created](docs/screenshots/08-successful-output.png)

If a row is missing a username, or an account with that SamAccountName already exists, the script logs a warning and moves on to the next row instead of stopping the whole batch.

### 6. Verify in Active Directory Users and Computers

Spot-check a few of the target OUs to confirm accounts landed in the right place with the right description.

![New user visible in the correct OU in ADUC](docs/screenshots/09-ad-verification-hr-ou.png)

### 7. Close the loop on the ticket

Reply to the original ticket to confirm the accounts are ready, including any follow-up notes (e.g. default passwords, forced password change at first logon).

![Reply to the ticket confirming completion](docs/screenshots/10-ticket-resolved-reply.png)

Mark the ticket solved once the requester confirms there's nothing else needed.

![Ticket marked as solved](docs/screenshots/11-ticket-solved.png)

## Troubleshooting notes

- **"User already exists" warnings** are expected if the script is re-run against the same CSV — it's a safety check, not an error.
- **Failed creations** print the underlying AD error via `Write-Error`, which usually points to an invalid `OU` distinguished name or a password that doesn't meet the domain's complexity policy.
- Passwords in the CSV are cleartext until the moment the script converts them with `ConvertTo-SecureString` — treat the exported CSV as sensitive and delete it once the run is complete.
