$ErrorActionPreference = "Stop"

$ProjectDir = "C:\Users\Danie\Desktop\nz-vege-garden"
$Branch = "feature/pest-spray-only"
$ApkPath = Join-Path $ProjectDir "build\app\outputs\flutter-apk\app-release.apk"

function Stop-ProcessTreeById {
    param([int]$ProcessId)

    $children = Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $ProcessId }
    foreach ($child in $children) {
        Stop-ProcessTreeById -ProcessId $child.ProcessId
    }

    Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
}

function Stop-OldProjectBuilds {
    Write-Host "`n=== Closing old Flutter / Gradle build processes ===" -ForegroundColor Cyan

    Push-Location $ProjectDir
    try {
        if (Test-Path ".\android\gradlew.bat") {
            & ".\android\gradlew.bat" --stop | Out-Host
        }
    } catch {
        Write-Host "Gradle stop warning: $($_.Exception.Message)" -ForegroundColor Yellow
    } finally {
        Pop-Location
    }

    $escapedProjectDir = [regex]::Escape($ProjectDir)
    $candidateNames = @("dart.exe", "flutter.exe", "java.exe", "javaw.exe", "gradle.exe", "adb.exe")

    $projectProcesses = Get-CimInstance Win32_Process |
        Where-Object {
            $candidateNames -contains $_.Name -and
            $_.CommandLine -and
            $_.CommandLine -match $escapedProjectDir
        }

    foreach ($process in $projectProcesses) {
        Write-Host "Stopping $($process.Name) PID $($process.ProcessId)" -ForegroundColor Yellow
        Stop-ProcessTreeById -ProcessId $process.ProcessId
    }

    Start-Sleep -Seconds 2
}

function Remove-BuildFolderSafely {
    Write-Host "`n=== Removing old build folder ===" -ForegroundColor Cyan

    $BuildDir = Join-Path $ProjectDir "build"

    if (!(Test-Path $BuildDir)) {
        Write-Host "No build folder found." -ForegroundColor DarkGray
        return
    }

    try {
        Remove-Item $BuildDir -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Host "First build folder delete failed. Closing old build tools and trying again..." -ForegroundColor Yellow
        Stop-OldProjectBuilds
        Start-Sleep -Seconds 2
        Remove-Item $BuildDir -Recurse -Force -ErrorAction Stop
    }
}

function Get-AaptPath {
    $SdkPath = $env:ANDROID_HOME
    if ([string]::IsNullOrWhiteSpace($SdkPath)) {
        $SdkPath = $env:ANDROID_SDK_ROOT
    }
    if ([string]::IsNullOrWhiteSpace($SdkPath)) {
        $SdkPath = "$env:LOCALAPPDATA\Android\Sdk"
    }

    $Aapt = Get-ChildItem "$SdkPath\build-tools" -Filter "aapt.exe" -Recurse -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending |
        Select-Object -First 1

    if ($null -eq $Aapt) {
        throw "Could not find aapt.exe. Install Android SDK Build Tools in Android Studio."
    }

    return $Aapt.FullName
}

function Get-PackageNameFromApk {
    param([string]$ApkFile)

    $AaptPath = Get-AaptPath
    $Badging = & $AaptPath dump badging $ApkFile
    $PackageName = [regex]::Match($Badging, "package: name='([^']+)'").Groups[1].Value

    if ([string]::IsNullOrWhiteSpace($PackageName)) {
        throw "Could not detect Android package name from APK."
    }

    return $PackageName
}

Write-Host "`n=== Preparing project ===" -ForegroundColor Cyan
Set-Location $ProjectDir

git fetch origin
git checkout $Branch
git pull origin $Branch

Stop-OldProjectBuilds
Remove-BuildFolderSafely

Write-Host "`n=== Getting packages ===" -ForegroundColor Cyan
flutter pub get

Write-Host "`n=== Building release APK ===" -ForegroundColor Cyan
flutter build apk --release

if (!(Test-Path $ApkPath)) {
    throw "Build failed. APK was not created: $ApkPath"
}

Write-Host "`n=== Installing APK ===" -ForegroundColor Cyan
adb devices
adb install -r $ApkPath

$PackageName = Get-PackageNameFromApk -ApkFile $ApkPath

Write-Host "`n=== Relaunching app ===" -ForegroundColor Cyan
adb shell am force-stop $PackageName
adb shell monkey -p $PackageName -c android.intent.category.LAUNCHER 1

Write-Host "`nDone. Rebuilt, installed, and launched:" -ForegroundColor Green
Write-Host $PackageName
Write-Host $ApkPath
