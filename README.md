# Test-CSOnlineUserVoiceRouting
Test a user's Online Voice Routing Policy for Teams Direct Routing

Using this script you can test a user's assigned Online Voice Routing Policy - this policy is used to decide how to route calls using Direct Routing. 
    
Simply provide a dialed number and a user to see what Voice Routes would be used and in what order.
    
For more information, go to https://wp.me/p97Bkx-g5
    
Example:

`.\Test-CSOnlineUserVoiceRouting.ps1 -DialedNumber +441234567890 -User user@domain.com`

*This will list any Voice Routes (in priority order) for user@domain.com calling +441234567890*
