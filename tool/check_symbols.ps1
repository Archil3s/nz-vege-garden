param(
  [switch]$Fix
)

$extensions = @("*.dart", "*.yaml", "*.yml", "*.json", "*.md", "*.bat", "*.ps1")
$skipDirs = @("\build\", "\.dart_tool\", "\.git\", "\android\.gradle\")

$replacements = @{
  "→" = "->"
  "←" = "<-"
  "×" = "x"
  "•" = "-"
  "–" = "-"
  "—" = "-"
  "“" = '"'
  "”" = '"'
  "‘" = "'"
  "’" = "'"
  "…" = "..."
  "≈" = "~"
  "≤" = "<="
  "≥" = ">="
}

$files = Get-ChildItem -Recurse -File -Include $extensions | Where-Object {
  $path = $_.FullName
  -not ($skipDirs | Where-Object { $path.Contains($_) })
}

$found = $false

foreach ($file in $files) {
  $content = Get-Content $file.FullName -Raw
  $original = $content

  foreach ($key in $replacements.Keys) {
    if ($content.Contains($key)) {
      $found = $true
      Write-Host "Found '$key' in $($file.FullName)"

      if ($Fix) {
        $content = $content.Replace($key, $replacements[$key])
      }
    }
  }

  if ($Fix -and $content -ne $original) {
    Set-Content -Path $file.FullName -Value $content -Encoding utf8
    Write-Host "Fixed $($file.FullName)"
  }
}

if ($found) {
  if ($Fix) {
    Write-Host "Symbol cleanup complete."
    exit 0
  }

  Write-Host ""
  Write-Host "Non-standard symbols found."
  Write-Host "Run this to auto-fix:"
  Write-Host "powershell -ExecutionPolicy Bypass -File tool\check_symbols.ps1 -Fix"
  exit 1
}

Write-Host "No weird symbols found."
exit 0
