# Test-CSOnlineUserVoiceRouting

_**Disclaimer:** This script is provided ‘as-is’ without any warranty or support. Use of this script is at your own risk and I accept no responsibility for any damage caused._

## Introduction

Test a user's Online Voice Routing Policy for Teams Direct Routing

Using this script you can test a user's assigned Online Voice Routing Policy - this policy is used to decide how to route calls using Direct Routing.

Simply provide a dialed number and a user to see what Voice Routes would be used and in what order.

For more information, go to <https://www.lee-ford.co.uk/test-csonlineuservoicerouting-test-a-users-online-voice-routing-policy-for-teams-direct-routing/>

## Usage

> Before you can use this tool you need to ensure you have the Microsoft Teams PowerShell module installed - <https://docs.microsoft.com/en-us/microsoftteams/teams-powershell-install>

```.\Test-CSOnlineUserVoiceRouting.ps1 -DialedNumber +441234567890 -User user@domain.com```

This will list any Voice Routes (in priority order) for user@domain.com calling +441234567890
