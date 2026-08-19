<#
.SYNOPSIS
    Bulk-creates Active Directory user accounts from a CSV export.

.DESCRIPTION
    Reads a CSV file (exported from the "User Creation CSV Sheet" Google Sheet)
    and creates one AD user per row using New-ADUser. Each row is validated,
    checked for an existing account with the same SamAccountName, and reported
    back to the console (green = success, red = failure).

.NOTES
    Author  : IT Support / Sherri Jones
    Source  : Built to resolve "Bulk User Creation Needed For Mass Employee
              Onboarding" support ticket.
    Requires: RSAT Active Directory PowerShell module (Import-Module ActiveDirectory)
              and permissions to create users in the target OUs.
#>

# Import the Active Directory Module
Import-Module ActiveDirectory

# Define path to the CSV file
$CSVPath = "C:\path\to\users.csv"

# Define your organization's UPN suffix (Domain name)
$DomainSuffix = "yourdomain.com"

# Import the CSV contents into a variable
$Users = Import-Csv -Path $CSVPath

foreach ($User in $Users) {
    # Check if the username field is empty in the row
    if ([string]::IsNullOrEmpty($User.Username)) {
        Write-Warning "Skipping row: Username is missing."
        continue
    }

    # Construct the full User Principal Name (UPN)
    $UPN = "$($User.Username)@$DomainSuffix"

    # Construct full display name
    $DisplayName = "$($User.Firstname) $($User.Lastname)"

    # Verify if the user already exists in AD to prevent errors
    if (Get-ADUser -Filter "SamAccountName -eq '$($User.Username)'") {
        Write-Warning "User '$($User.Username)' already exists in Active Directory. Skipping creation."
    }
    else {
        try {
            # Convert the cleartext password into a Secure String required by AD
            $SecurePassword = ConvertTo-SecureString $User.Password -AsPlainText -Force

            # Define parameters using splatting for readability
            $UserParams = @{
                SamAccountName        = $User.Username
                UserPrincipalName     = $UPN
                Name                  = $DisplayName
                GivenName             = $User.Firstname
                Surname               = $User.Lastname
                DisplayName           = $DisplayName
                Description           = $User.Description
                AccountPassword       = $SecurePassword
                Path                  = $User.OU
                Enabled               = $true
                ChangePasswordAtLogon = $true
            }

            # Create the new user object
            New-ADUser @UserParams
            Write-Host "Successfully created user: $DisplayName ($($User.Username))" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to create user '$($User.Username)'. Reason: $_"
        }
    }
}
