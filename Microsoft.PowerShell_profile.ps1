function Test-Administrator {  
  $user = [Security.Principal.WindowsIdentity]::GetCurrent();
  $role = [Security.Principal.WindowsBuiltinRole]::Administrator
  (New-Object Security.Principal.WindowsPrincipal $user).IsInRole($role)  
}

# From: https://adsecurity.org/?p=478
function ConvertTo-Base64 {
  param(
    [Parameter(Mandatory = $True)]
    [string]$String
  )
  $Bytes = [System.Text.Encoding]::Unicode.GetBytes($String)
  $EncodedText = [Convert]::ToBase64String($Bytes)
  return $EncodedText
}

function ConvertFrom-Base64 {
  param(
    [Parameter(Mandatory = $True)]
    [string]$String
  )
  $DecodedText = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($String))
  $DecodedText
}

# From: https://blogs.msdn.microsoft.com/luc/2011/01/21/powershell-getting-the-hash-value-for-a-string/
function Get-StringHash {
  param(
    [string]$String,
    [string]$Hash = "SHA256"
  )

  $hasher = switch ($Hash) {
    "SHA512" { new-object System.Security.Cryptography.SHA512Managed }
    "SHA256" { new-object System.Security.Cryptography.SHA256Managed }
    "SHA1" { new-object System.Security.Cryptography.SHA1Managed }
    "MD5" { new-object System.Security.Cryptography.MD5CryptoServiceProvider }
  }

  $toHash = [System.Text.Encoding]::UTF8.GetBytes($string)
  $hashByteArray = $hasher.ComputeHash($toHash)
  foreach ($byte in $hashByteArray) {
    $res += $byte.ToString("x2")
  }
  return $res;
}

function Get-ExternalIPAddress {
  return (New-Object Net.WebClient).DownloadString('http://ifconfig.io/ip').Replace("`n", "")
}

function ConvertTo-ShortPath ($path) {
  $firstSlash = $path.IndexOf("\")
  $drive = $path.Substring(0, $firstSlash)
  $lastSlash = $path.LastIndexOf("\")
  $secondToLastSlash = $path.LastIndexOf("\", $lastSlash - 1)
  $thirdToLastSlash = $path.LastIndexOf("\", $secondToLastSlash - 1)
  $tail = $path.Substring($thirdToLastSlash)
  $shortPath = "$drive\..$tail"
  $shortPath
}

function Split-String {
  param (
    [Parameter(Mandatory = $true)]
    [string]$String,
    [int]$MinLength = 50,
    [int]$MaxLength = 120,
    [string]$VariableName = "data",
    [ValidateSet("PowerShell", "CSharp")]
    $Format = "PowerShell"
  )

  $index = 0
  $length = $String.length

  if ($Format -eq "CSharp") {
    Write-Output "string $VariableName = `"`";"
  }

  while ($index -lt $length) {
    $substringSize = Get-Random -Minimum $MinLength -Maximum $MaxLength
    if (($index + $substringSize) -gt $length) {
      $substringSize = $length - $index
    }
    $subString = $string.substring($index, $substringSize)
    if ($Format -eq "PowerShell") {
      Write-Output "`$$VariableName += `"$subString`""
    }
    if ($Format -eq "CSharp") {
      Write-Output "$VariableName += `"$subString`";"
    }
    $index += $substringSize
  }
}

function Test-GitRepo {
  $pwd = Get-Location
  $isGitDir = Test-Path $(Join-Path $pwd ".git")
  $parentDir = (Get-Item $pwd).Parent
  while ((![string]::IsNullOrEmpty($parentDir.ToString()) -and ($isGitDir -eq $false))) {
    $gitPath = Join-Path $parentDir.FullName ".git"
    $isGitDir = Test-Path $gitPath
    $parentDir = $parentDir.Parent
  }
  $isGitDir
}

# Check if git is installed
try {
  Get-Command git.exe -ErrorAction Stop | Out-Null
  $gitInstalled = $true
}
catch {
  $gitInstalled = $false
}

function prompt { 
  Write-Host "" 
  $pwd = $(Get-Location).path
  if ($pwd.Length -gt 80) {
    $pwd = ConvertTo-ShortPath $pwd
  }
  Write-Host ("[" + ($(Get-Date).toString("MM/dd/yyyy hh:mm:ss")) + "] [" + $pwd + "]") -NoNewline
  # Check if we're in a git repo
  if ($gitInstalled -and (Test-GitRepo)) {
    $output = &git status
    $branch = $output[0].Replace('On branch ', '')
    if ($output[3] -like '*clean') {
      Write-Host -NoNewline -ForegroundColor Green " [$branch]"
    }
    else {
      Write-Host -NoNewLine -ForegroundColor Red " [$branch]"
    }
  }

  $prompt_text = "PS>"
  Write-Host ""
  if (Test-Administrator) {
    Write-Host -ForegroundColor Red "[ADMIN]" -NoNewline
    $prompt_text = " PS#"
  }
  Write-Host $prompt_text -NoNewLine
  Return " "
}
