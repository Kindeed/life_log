param(
  [switch]$SkipBuild
)

$ErrorActionPreference = 'Continue'

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

$RunStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$RunRoot = Join-Path $RepoRoot "build\quality-gate\$RunStamp"
$LogRoot = Join-Path $RunRoot 'logs'
New-Item -ItemType Directory -Force -Path $LogRoot | Out-Null

$Summary = New-Object System.Collections.Generic.List[string]

function Add-Summary {
  param([string]$Line)
  $Summary.Add($Line) | Out-Null
  Write-Host $Line
}

function Format-CommandText {
  param([string[]]$Command)
  return ($Command -join ' ')
}

function Invoke-CapturedProcess {
  param(
    [string]$Name,
    [string[]]$Command,
    [string]$LogPath
  )

  $Executable = $Command[0]
  $Arguments = @()
  if ($Command.Count -gt 1) {
    $Arguments = $Command[1..($Command.Count - 1)]
  }

  $CommandInfo = Get-Command $Executable -ErrorAction Stop
  $StdOutPath = Join-Path $LogRoot "$Name.stdout.tmp"
  $StdErrPath = Join-Path $LogRoot "$Name.stderr.tmp"
  Remove-Item -LiteralPath $StdOutPath, $StdErrPath -ErrorAction SilentlyContinue

  $Process = Start-Process `
    -FilePath $CommandInfo.Source `
    -ArgumentList $Arguments `
    -Wait `
    -PassThru `
    -NoNewWindow `
    -RedirectStandardOutput $StdOutPath `
    -RedirectStandardError $StdErrPath

  $OutputParts = New-Object System.Collections.Generic.List[string]
  if (Test-Path $StdOutPath) {
    $StdOut = Get-Content -Path $StdOutPath -Raw
    if (-not [string]::IsNullOrWhiteSpace($StdOut)) {
      $OutputParts.Add($StdOut.TrimEnd()) | Out-Null
    }
  }
  if (Test-Path $StdErrPath) {
    $StdErr = Get-Content -Path $StdErrPath -Raw
    if (-not [string]::IsNullOrWhiteSpace($StdErr)) {
      $OutputParts.Add($StdErr.TrimEnd()) | Out-Null
    }
  }

  $Output = $OutputParts -join [Environment]::NewLine
  Set-Content -Path $LogPath -Value $Output -Encoding UTF8
  if (-not [string]::IsNullOrWhiteSpace($Output)) {
    Write-Host $Output
  }

  Remove-Item -LiteralPath $StdOutPath, $StdErrPath -ErrorAction SilentlyContinue
  return $Process.ExitCode
}

function Invoke-GateCommand {
  param(
    [string]$Name,
    [string[]]$Command,
    [switch]$Informational
  )

  $LogPath = Join-Path $LogRoot "$Name.log"
  $CommandText = Format-CommandText $Command
  Add-Summary "START $Name :: $CommandText"

  $StartedAt = Get-Date
  $ExitCode = Invoke-CapturedProcess `
    -Name $Name `
    -Command $Command `
    -LogPath $LogPath
  $Elapsed = [Math]::Round(((Get-Date) - $StartedAt).TotalSeconds, 1)

  if ($Informational) {
    Add-Summary "INFO $Name exit=$ExitCode seconds=$Elapsed log=$LogPath"
    return
  }

  if ($ExitCode -ne 0) {
    Add-Summary "FAIL $Name exit=$ExitCode seconds=$Elapsed log=$LogPath"
    throw "Quality gate failed at $Name. See $LogPath"
  }

  Add-Summary "PASS $Name seconds=$Elapsed log=$LogPath"
}

function Invoke-NoMatchScan {
  param(
    [string]$Name,
    [string]$Pattern,
    [string[]]$Paths
  )

  $LogPath = Join-Path $LogRoot "$Name.log"
  Add-Summary "START $Name :: rg -n $Pattern $($Paths -join ' ')"
  & rg -n $Pattern @Paths 2>&1 | Tee-Object -FilePath $LogPath
  $ExitCode = $LASTEXITCODE

  if ($ExitCode -eq 0) {
    Add-Summary "FAIL $Name found forbidden matches log=$LogPath"
    throw "Forbidden matches found during $Name. See $LogPath"
  }

  if ($ExitCode -eq 1) {
    Add-Summary "PASS $Name no matches log=$LogPath"
    return
  }

  Add-Summary "FAIL $Name rg exit=$ExitCode log=$LogPath"
  throw "Search failed during $Name. See $LogPath"
}

function Invoke-RequiredMatchScan {
  param(
    [string]$Name,
    [string]$Pattern,
    [string[]]$Paths
  )

  $LogPath = Join-Path $LogRoot "$Name.log"
  Add-Summary "START $Name :: rg -n $Pattern $($Paths -join ' ')"
  & rg -n $Pattern @Paths 2>&1 | Tee-Object -FilePath $LogPath
  $ExitCode = $LASTEXITCODE

  if ($ExitCode -eq 0) {
    Add-Summary "PASS $Name required match found log=$LogPath"
    return
  }

  Add-Summary "FAIL $Name missing required match log=$LogPath"
  throw "Required match missing during $Name. See $LogPath"
}

try {
  Invoke-GateCommand `
    -Name 'flutter-analyze' `
    -Command @('flutter', 'analyze', '--no-fatal-infos')

  Invoke-GateCommand `
    -Name 'flutter-test' `
    -Command @('flutter', 'test')

  Invoke-GateCommand `
    -Name 'git-diff-check' `
    -Command @('git', 'diff', '--check')

  Invoke-NoMatchScan `
    -Name 'legacy-module-and-getx-scan' `
    -Pattern 'package:life_log/modules|lib/modules|package:get/get.dart|\bGet\.|\bGetx|LegacyGet|Obx\(|\.obs\b' `
    -Paths @('lib')

  Invoke-RequiredMatchScan `
    -Name 'photo-model-inventory' `
    -Pattern '\bclass PhotoItem\b' `
    -Paths @('lib/features/photo/data/photo_model.dart')

  Invoke-NoMatchScan `
    -Name 'photo-sync-field-scan' `
    -Pattern '\b(syncId|remoteId|isDirty|remoteVersion|deletedAt|pendingDelete)\b' `
    -Paths @(
      'lib/features/photo/data/photo_model.dart',
      'lib/features/photo/domain',
      'lib/features/photo/application'
    )

  if (-not $SkipBuild) {
    Invoke-GateCommand `
      -Name 'flutter-build-apk-debug' `
      -Command @('flutter', 'build', 'apk', '--debug')
  } else {
    Add-Summary 'SKIP flutter-build-apk-debug requested by -SkipBuild'
  }

  Invoke-GateCommand `
    -Name 'flutter-devices' `
    -Command @('flutter', 'devices') `
    -Informational

  Add-Summary "DONE quality-gate logs=$LogRoot"
} finally {
  $SummaryPath = Join-Path $RunRoot 'summary.txt'
  $Summary | Set-Content -Path $SummaryPath -Encoding UTF8
  Write-Host "Summary: $SummaryPath"
}
