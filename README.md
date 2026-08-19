# Active Directory Bulk User Creation

Resolve mass employee-onboarding requests by generating Active Directory accounts in bulk from a Google Sheet, exported as CSV and processed with a PowerShell script.

This repo documents the exact workflow used to close a real support ticket — **"Bulk User Creation Needed For Mass Employee Onboarding"** — where HR requested ~50 new AD accounts ahead of a Monday onboarding.

## How it works

1. **Collect requirements** from the support ticket (who needs accounts, by when, which department/OU).
2. **Build the roster** in a Google Sheet, with a formula-generated username column.
3. **Export the sheet to CSV** and drop it on the domain controller / admin workstation.
4. **Run the PowerShell script**, which reads the CSV and calls `New-ADUser` for each row — skipping rows with missing usernames and skipping accounts that already exist.
5. **Verify** the new accounts landed in the correct OUs in Active Directory Users and Computers.
6. **Close the loop** by replying to the ticket and marking it solved.

## Repo contents

| Path | Purpose |
|---|---|
| [`scripts/New-BulkADUsers.ps1`](scripts/New-BulkADUsers.ps1) | The bulk-creation script |
| [`sample-data/users-template.csv`](sample-data/users-template.csv) | CSV template matching the script's expected columns |
| [`docs/setup-guide.md`](docs/setup-guide.md) | Full walk-through with screenshots |
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

See [`docs/setup-guide.md`](docs/setup-guide.md) for the full step-by-step with screenshots, including how the roster was built in Google Sheets and how the result was verified in Active Directory.

## Requirements

- Windows Server with the **Active Directory module for PowerShell** (RSAT), or a workstation with RSAT installed
- An account with permission to create users in the target OUs
- PowerShell 5.1+
