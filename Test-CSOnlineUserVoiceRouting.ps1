<#

.SYNOPSIS
 
    Test-CSOnlineUserVoiceRouting.ps1 - Test a user's Online Voice Routing Policy for Teams Direct Routing
 
.DESCRIPTION

    Author: Lee Ford

    Using this script you can test a user's assigned Online Voice Routing Policy - this policy is used to decide how to route Direct Routing calls. 
    Simply provide a dialed number and a user to see what Voice Routes would be used and in what order.
    
    For more information, go to https://wp.me/p97Bkx-g5
    
.LINK

    Blog: https://www.lee-ford.co.uk
    Twitter: http://www.twitter.com/lee_ford
    LinkedIn: https://www.linkedin.com/in/lee-ford/
 
.EXAMPLE 
    
    .\Test-CSOnlineUserVoiceRouting.ps1 -DialedNumber +441234567890 -User user@domain.com
    This will list any Voice Routes (in priority order) for user@domain.com calling +441234567890


#>

param(

    [Parameter(mandatory = $true)][String]$User,
    [Parameter(mandatory = $true)][String]$DialedNumber,
    [Parameter(mandatory = $false)][string]$OverrideAdminDomain

)

function Check-ModuleInstalled {
    param (

        [Parameter (mandatory = $true)][String]$module,
        [Parameter (mandatory = $true)][String]$moduleName
        
    )

    # Do you have module installed?
    Write-Host "`nChecking $moduleName installed..." -NoNewline

    if (Get-Module -ListAvailable -Name $module) {
    
        Write-Host " INSTALLED" -ForegroundColor Green

    }
    else {

        Write-Host " NOT INSTALLED" -ForegroundColor Red
        
        break

    }
    
}

function Test-TeamsConnection {
    if(-not((Get-Command Get-CsTeamsCallingPolicy -ErrorAction "SilentlyContinue") -and (Get-CsTeamsCallingPolicy -ErrorAction "SilentlyContinue"))){
        return $false
    }
    return $true
}

# Start
Write-Host "`n----------------------------------------------------------------------------------------------
            `n Test-CSOnlineUserVoiceRouting.ps1 - Lee Ford - https://www.lee-ford.co.uk
            `n----------------------------------------------------------------------------------------------" -ForegroundColor Yellow

Write-Host "`nChecking voice routing of dialed number $DialedNumber for $user" -ForegroundColor Yellow

# Check Teams module installed
Check-ModuleInstalled -module MicrosoftTeams -moduleName "Microsoft Teams module"

if (-not(Test-TeamsConnection)) {
    Write-Host "No existing PowerShell Session..."

    Connect-MicrosoftTeams
}
else {

    Write-Host "Using existing PowerShell Session..."

}

$VoiceRoutes = @()
$MatchedVoiceRoutes = @()

# Check if user exists
$UserReturned = Get-CSOnlineUser -Identity $User -ErrorAction SilentlyContinue

if ($UserReturned) {

    # Get effective dial plan for user, then test it and return normalised number (if needed) along with the matched rule
    Write-Host "`nGetting Effective Tenant Dial Plan for $user and translating number..."
    $EffectiveDialPlan = Get-CsEffectiveTenantDialPlan -Identity $user
    $NormalisedResult = $EffectiveDialPlan | Test-CsEffectiveTenantDialPlan -DialedNumber $DialedNumber

    if ($NormalisedResult.TranslatedNumber) {

        Write-Host "`r$DialedNumber translated to $($NormalisedResult.TranslatedNumber)" -ForegroundColor Green
        Write-Host "`r(Using rule:`n$($NormalisedResult.MatchingRule -replace ";", "`n"))"

        $NormalisedNumber = $NormalisedResult.TranslatedNumber

    }
    else {

        Write-Host "`rNo translation patterns matched"

        $NormalisedNumber = $DialedNumber

    }
    # Get the Online Voice Routing Policy assigned to the user
    Write-Host "`nGetting assigned Online Voice Routing Policy for $User..."
    [string]$UserOnlineVoiceRoutingPolicy = (Get-CsUserPolicyAssignment -Identity $User -PolicyType OnlineVoiceRoutingPolicy).PolicyName

    if ($UserOnlineVoiceRoutingPolicy) {

        Write-Host "`rOnline Voice Routing Policy assigned to $user is: '$UserOnlineVoiceRoutingPolicy'" -ForegroundColor Green

        # Get PSTN Usages assigned to Online Voice Routing Policy
        $PSTNUsages = (Get-CsOnlineVoiceRoutingPolicy -Identity $UserOnlineVoiceRoutingPolicy).OnlinePstnUsages

        # Loop through each PSTN Usage and get the Voice Routes
        foreach ($PSTNUsage in $PSTNUsages) {
    
            $VoiceRoutes += Get-CsOnlineVoiceRoute | Where-Object { $_.OnlinePstnUsages -contains $PSTNUsage } | Select-Object *, @{label = ”PSTNUsage”; Expression = { $PSTNUsage } }

        }

        # Find PSTN first matching PSTN Usage
        Write-Host "`nFinding the first PSTN Usage with a Voice Route that matches $NormalisedNumber..."

        $MatchedVoiceRoutes = $VoiceRoutes | Where-Object { $NormalisedNumber -match $_.NumberPattern }

        if ($MatchedVoiceRoutes) {

            $ChosenPSTNUsage = $MatchedVoiceRoutes[0].PSTNUsage

            # Find Voice Routes that match normalised number and first matching PSTN Usage
            Write-Host "`rFirst Matching PSTN Usage: '$ChosenPSTNUsage'"

            $MatchedVoiceRoutes = $MatchedVoiceRoutes | Where-Object { $_.PSTNUsage -eq $ChosenPSTNUsage }

            Write-Host "`rFound $(@($MatchedVoiceRoutes).Count) Voice Route(s) with matching pattern in PSTN Usage '$ChosenPSTNUsage', listing in priority order..." -ForegroundColor Green

            $MatchedVoiceRoutes | Select-Object Name, NumberPattern, PSTNUsage, OnlinePstnGatewayList, Priority | Format-Table

            Write-Host "Note: Once a Voice Route that matches is found in a PSTN Usage, all other Voice Routes in other PSTN Usages will be ignored." -ForegroundColor Yellow

        }
        else {

            Write-Warning -Message "No Voice Route with matching pattern found, unable to route call using Direct Routing."

        }

    }
    else {

        Write-Warning -Message "No Online Voice Routing Policy assgined to $user."

    }

}
else {

    Write-Warning -Message "$user not found on tenant."

}
