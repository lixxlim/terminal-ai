# For windows powershell

$global:UserArrays = @()
$global:ModelArrays = @()
$global:CurrentModel = "gemini-2.0-flash"

function Ask-AI {
    param(
        [switch]$Clear,
        [string]$Model
    )

    # Handle model switching
    if ($Model) {
        $global:CurrentModel = $Model
    }

    # Clear history if requested
    if ($Clear) {
        $global:UserArrays = @()
        $global:ModelArrays = @()
        Write-Host "Conversation history cleared." -ForegroundColor Yellow
        return
    }

    $prompt = ">> "
    $userInput = ""

    while ($true) {
        $line = Read-Host $prompt

        # Model switching inline
        if ($line -match "#flash") {
            $global:CurrentModel = "gemini-2.0-flash"
            $line = $line -replace "#flash", ""
        }
        elseif ($line -match "#pro") {
            $global:CurrentModel = "gemini-2.0-pro-exp-02-05"
            $line = $line -replace "#pro", ""
        }
        elseif ($line -match "#think") {
            $global:CurrentModel = "gemini-2.0-flash-thinking-exp-01-21"
            $line = $line -replace "#think", ""
        }

        $userInput += "$line`n"

        if ($line -match ";;") {
            $userInput = $userInput -replace ";;", ""
            break
        }
    }

    $userInput = $userInput.Trim()
    $global:UserArrays += $userInput

    $content = @{
        contents = @()
    }

    # Build conversation context
    for ($i = 0; $i -lt $global:UserArrays.Count; $i++) {
        $content.contents += @{
            role = "user"
            parts = @(@{
                text = $global:UserArrays[$i]
            })
        }

        if ($i -lt $global:ModelArrays.Count) {
            $content.contents += @{
                role = "model"
                parts = @(@{
                    text = $global:ModelArrays[$i]
                })
            }
        }
    }

    $uri = "https://generativelanguage.googleapis.com/v1beta/models/$global:CurrentModel`:generateContent?key=$env:GOOGLE_AI_API_KEY"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body ($content | ConvertTo-Json -Depth 10) -ContentType "application/json; charset=utf-8"

        $width = $Host.UI.RawUI.WindowSize.Width
        $separator = "*" * $width

        Write-Host "`e[93m$separator`e[0m"

        if ($response.candidates) {
            $res = $response.candidates[0].content.parts[0].text
            Write-Host "`e[93m$res`e[0m"

            $global:ModelArrays += $res
        }
        else {
            Write-Error "API Error: No candidates in response"
        }

        Write-Host "`e[93mby $global:CurrentModel`e[0m"
        Write-Host "`e[93m$separator`e[0m"
    }
    catch {
        Write-Error "API Error: $($_.Exception.Message)"
    }
}

function Show-AIHistory {
    Write-Host "`n=== Conversation History ===`n" -ForegroundColor Green
    for ($i = 0; $i -lt $global:UserArrays.Count; $i++) {
        Write-Host "User: $($global:UserArrays[$i])" -ForegroundColor Cyan
        if ($i -lt $global:ModelArrays.Count) {
            Write-Host "AI: $($global:ModelArrays[$i])" -ForegroundColor Yellow
        }
        Write-Host ""
    }
}

if (-not $env:GOOGLE_AI_API_KEY) {
    Write-Warning "Google AI API Key is not set. Please set the GOOGLE_AI_API_KEY environment variable."
}