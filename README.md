# LoftLights

## What does it do?
Manages three Hive TWGU10Bulb03UK lights through Home Assistant's REST API. Now available as a PowerShell module or the original script.

## Why?
Because i wanted to control the loft lights from my console window. Nothing more. 

## How do I use it?
**As a module (recommended):**
```powershell
Import-Module .\LoftLights.psd1
Set-LoftLights -On -Dim 75
```

**As the original script:**
```powershell
.\set-loftlights.ps1 -On -Dim 75
```

## Did you write it?
I architected it, but Claude Code wrote it. It's part of me learning how to use Claude but write useful stuff and practice command line stuff.

## Yeah but... 
Don't overthink it. Its not that deep. Its a script (now module) that turns on\off or dim's three lights in a room. 
