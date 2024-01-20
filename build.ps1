param (
    [string[]]$SelectedOperatingSystems = @("all"),
    [string[]]$SelectedArchitectures = @("all"),
    [switch]$Help,
    [switch]$CleanBuild,
    [switch]$InteractiveMode,
    [switch]$Verbose
)

# Define the help message
$HelpMessage = @"
Bitmato LLC GOLANG_BUILD v1.2
Usage: build.ps1 [-SelectedOperatingSystems <os1,os2,...>] [-SelectedArchitectures <arch1,arch2,...>] [-Help] [-CleanBuild] [-InteractiveMode]

Options:
  -SelectedOperatingSystems  Specify the operating systems to build for (comma-separated). Default is 'all'.
  -SelectedArchitectures     Specify the architectures to build for (comma-separated). Default is 'all'.
  -Help                      Display this help message.
  -CleanBuild                Clean the build directory before starting the build.
  -InteractiveMode           Use interactive mode to select operating systems and architectures.
  -Verbose                   Enable verbose output.
  
Valid Operating Systems: linux, darwin, windows, freebsd, android, ios
Valid Architectures: amd64, arm64, 386, arm
"@

# Predefined valid operating systems and architectures
$ValidOperatingSystems = @("linux", "darwin", "windows", "freebsd", "android", "ios")
$ValidArchitectures = @("amd64", "arm64", "386", "arm")

# Check if the Help switch is provided
if ($Help) {
    Write-Host $HelpMessage
    exit
}


# Check for the CleanBuild switch and clean the build directory if specified
if ($CleanBuild) {
    Remove-Item -Recurse -Path "./builds" -Force
    Write-Host "Build directory cleaned."
    exit
}

# Check for the InteractiveMode switch and prompt for operating systems and architectures if not specified
if ($InteractiveMode) {
    Write-Host "Valid operating systems and architectures"
    Write-Host $ValidOperatingSystems
    Write-Host $ValidArchitectures

    $SelectedOperatingSystems = Read-Host "Enter operating systems (comma-separated, 'all' for all):"
    $SelectedOperatingSystems = $SelectedOperatingSystems -split ","
    
    $SelectedArchitectures = Read-Host "Enter architectures (comma-separated, 'all' for all):"
    $SelectedArchitectures = $SelectedArchitectures -split ","
}

# Register the Ctrl+C event handler
$Host.UI.RawUI.WindowTitle = "Building OctoCore3!"

# Determine operating systems to build
$OperatingSystemsToBuild = if ($SelectedOperatingSystems -contains "all") { 
    $ValidOperatingSystems 
} else { 
    $SelectedOperatingSystems | Where-Object { $ValidOperatingSystems -contains $_ }
}

$SelectedArchitectures = if ($SelectedArchitectures -contains "all") {
    $ValidArchitectures
} else {
    $SelectedArchitectures | Where-Object { $ValidArchitectures -contains $_ }
}


# Initialize variables to track successful and failed builds
$SuccessfulBuilds = 0
$FailedBuilds = 0

$TotalBuilds = $OperatingSystemsToBuild.Count * $SelectedArchitectures.Count
$BuildCounter = 0

$ProgressBarId = 1  # You can choose any unique ID
$ProgressStatus = "Building"
$ProgressPercent = 0

# Loop through each OS and Architecture combination
foreach ($os in $OperatingSystemsToBuild) {
    foreach ($arch in $SelectedArchitectures) {
        # Set environment variables for cross-compilation
        $BuildCounter++ 

        $ProgressPercent = ($BuildCounter / $TotalBuilds) * 100
        
        $env:GOOS = $os
        $env:GOARCH = $arch
        
        Write-Host "Building for: $env:GOOS $env:GOARCH"
        Write-Progress -Activity "Building for: $env:GOOS $env:GOARCH" -Status "$ProgressPercent% done" -PercentComplete $ProgressPercent
        
        $Host.UI.RawUI.WindowTitle = "Building for: $env:GOOS $env:GOARCH"

        ## write the current location
        Write-Host "Current directory: $pwd"

        # Create build directory if it doesn't exist
        $buildDir = "./builds/$arch/$os"
        if (-not (Test-Path $buildDir)) {
            Write-Host "Trying to create build directory"
            New-Item -ItemType Directory -Path $buildDir -Force
        }
        
        # Placeholder: Determine output file name, add .exe extension for Windows
        $outputName = "smtkmap-$arch-$os"
        if ($os -eq "windows") {
            $outputName += ".exe"
        }
        $outputPath = "$buildDir/$outputName"
        
        # Build the Go program and capture both stdout and stderr
        $output = go build -o $outputPath 2>&1

        # Check if there were any errors
        if ($LASTEXITCODE -ne 0) {
            Write-Host -Object "Error occurred while building the Go program:" -ForegroundColor Red -BackgroundColor Black
            Write-Host $output  # Output the captured errors
            $FailedBuilds++
            exit
        } else {
            Write-Host "Go program built successfully."
            $SuccessfulBuilds++
            # No need to output anything in case of successful build
        }


        Remove-Item Env:\GOOS
        Remove-Item Env:\GOARCH
    }
}

# Display a build summary
Write-Host "Build summary:"
Write-Host "Successful builds: $SuccessfulBuilds"
Write-Host "Failed builds: $FailedBuilds"
