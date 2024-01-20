#!/bin/bash

SelectedOperatingSystems=("all")
SelectedArchitectures=("all")
Help=false
CleanBuild=false
InteractiveMode=false
Verbose=false

# Define the help message
HelpMessage=$(cat <<EOF
Bitmato LLC GOLANG_BUILD v1.2
Usage: build.sh [-SelectedOperatingSystems <os1,os2,...>] [-SelectedArchitectures <arch1,arch2,...>] [-Help] [-CleanBuild] [-InteractiveMode]

Options:
  -SelectedOperatingSystems  Specify the operating systems to build for (comma-separated). Default is 'all'.
  -SelectedArchitectures     Specify the architectures to build for (comma-separated). Default is 'all'.
  -Help                      Display this help message.
  -CleanBuild                Clean the build directory before starting the build.
  -InteractiveMode           Use interactive mode to select operating systems and architectures.
  -Verbose                   Enable verbose output.
  
Valid Operating Systems: linux, darwin, windows, freebsd, android, ios
Valid Architectures: amd64, arm64, 386, arm
EOF
)

# Predefined valid operating systems and architectures
ValidOperatingSystems=("linux" "darwin" "windows" "freebsd" "android" "ios")
ValidArchitectures=("amd64" "arm64" "386" "arm")

# Check if the Help switch is provided
if [ "$Help" = true ]; then
    echo "$HelpMessage"
    exit
fi

if [! -d "./builds" ]; then
    mkdir "./builds"
fi

# Check for the CleanBuild switch and clean the build directory if specified
if [ "$CleanBuild" = true ]; then
    rm -rf "./builds"
    echo "Build directory cleaned."
    exit
fi

# Check for the InteractiveMode switch and prompt for operating systems and architectures if not specified
if [ "$InteractiveMode" = true ]; then
    echo "Valid operating systems and architectures"
    echo "${ValidOperatingSystems[@]}"
    echo "${ValidArchitectures[@]}"

    read -p "Enter operating systems (comma-separated, 'all' for all): " SelectedOperatingSystemsInput
    IFS=',' read -ra SelectedOperatingSystems <<< "$SelectedOperatingSystemsInput"
    
    read -p "Enter architectures (comma-separated, 'all' for all): " SelectedArchitecturesInput
    IFS=',' read -ra SelectedArchitectures <<< "$SelectedArchitecturesInput"
fi

# Determine operating systems to build
OperatingSystemsToBuild=()
for os in "${SelectedOperatingSystems[@]}"; do
    if [ "$os" == "all" ]; then
        OperatingSystemsToBuild=("${ValidOperatingSystems[@]}")
        break
    elif [[ " ${ValidOperatingSystems[@]} " =~ " ${os} " ]]; then
        OperatingSystemsToBuild+=("$os")
    fi
done

for arch in "${SelectedArchitectures[@]}"; do
    if [ "$arch" == "all" ]; then
        SelectedArchitectures=("${ValidArchitectures[@]}")
        break
    elif [[ " ${ValidArchitectures[@]} " =~ " ${arch} " ]]; then
        SelectedArchitectures+=("$arch")
    fi
done

# Initialize variables to track successful and failed builds
SuccessfulBuilds=0
FailedBuilds=0

TotalBuilds=$(( ${#OperatingSystemsToBuild[@]} * ${#SelectedArchitectures[@]} ))
BuildCounter=0

ProgressBarId=1  # You can choose any unique ID
ProgressStatus="Building"
ProgressPercent=0

# Loop through each OS and Architecture combination
for os in "${OperatingSystemsToBuild[@]}"; do
    for arch in "${SelectedArchitectures[@]}"; do
        # Set environment variables for cross-compilation
        BuildCounter=$((BuildCounter + 1))
        ProgressPercent=$((BuildCounter * 100 / TotalBuilds))
        
        export GOOS="$os"
        export GOARCH="$arch"
        
        echo "Building for: $GOOS $GOARCH"
        echo "Progress: $ProgressPercent% done"
        
        # Create build directory if it doesn't exist
        buildDir="./builds/$arch/$os"
        if [ ! -d "$buildDir" ]; then
            echo "Trying to create build directory"
            mkdir -p "$buildDir"
        fi
        
        # Placeholder: Determine output file name, add .exe extension for Windows
        outputName="smtkmap-$arch-$os"
        if [ "$os" == "windows" ]; then
            outputName="$outputName.exe"
        fi
        outputPath="$buildDir/$outputName"
        
        go build -o "$outputPath"
        
        # Update build counters based on success or failure
        if [ -f "$outputPath" ]; then
            SuccessfulBuilds=$((SuccessfulBuilds + 1))
        else
            FailedBuilds=$((FailedBuilds + 1))
        fi

        unset GOOS
        unset GOARCH
    done
done

# Display a build summary
echo "Build summary:"
echo "Successful builds: $SuccessfulBuilds"
echo "Failed builds: $FailedBuilds"
