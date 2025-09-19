#!/bin/bash

set -e

CONFIGURATION="Release"
PACK=false
PUBLISH=false
READY_TO_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --configuration)
            CONFIGURATION="$2"
            shift 2
            ;;
        --pack)
            PACK=true
            shift
            ;;
        --publish)
            PUBLISH=true
            shift
            ;;
        --ready-to-run)
            READY_TO_RUN=true
            shift
            ;;
        *)
            echo "Unknown option $1"
            exit 1
            ;;
    esac
done

echo -e "\033[32mBuilding Schedule Editor...\033[0m"

# Navigate to the source directory
cd Source

# Clean previous builds
echo -e "\033[33mCleaning previous builds...\033[0m"
dotnet clean ScheduleEditor.csproj -c "$CONFIGURATION"

# Restore packages
echo -e "\033[33mRestoring packages...\033[0m"
dotnet restore ScheduleEditor.csproj

# Build for all target platforms
declare -a platforms=(
    "win-x64:Windows x64"
    "osx-x64:macOS x64"
    "osx-arm64:macOS ARM64"
    "linux-x64:Linux x64"
)

for platform_info in "${platforms[@]}"; do
    IFS=':' read -r rid name <<< "$platform_info"
    echo -e "\033[36mBuilding for $name...\033[0m"

    # Build publish command with conditional ready-to-run
    publish_args=(
        "publish"
        "ScheduleEditor.csproj"
        "-c" "$CONFIGURATION"
        "-r" "$rid"
        "--self-contained" "true"
        "-p:PublishSingleFile=true"
        "-p:PublishTrimmed=false"
        "-o" "bin/publish/$rid"
    )

    if [ "$READY_TO_RUN" = true ]; then
        echo -e "\033[33m  Enabling Ready-to-Run compilation...\033[0m"
        publish_args+=("-p:PublishReadyToRun=true")
    fi

    # Publish the application
    dotnet "${publish_args[@]}"

    if [ $? -ne 0 ]; then
        echo -e "\033[31mBuild failed for $name\033[0m"
        exit 1
    fi
done

if [ "$PACK" = true ]; then
    echo -e "\033[32mCreating Velopack packages...\033[0m"

    # Install vpk tool if not present
    if ! command -v vpk &> /dev/null; then
        echo -e "\033[33mInstalling Velopack CLI...\033[0m"
        dotnet tool install -g vpk
    fi

    for platform_info in "${platforms[@]}"; do
        IFS=':' read -r rid name <<< "$platform_info"
        echo -e "\033[36mPackaging for $name...\033[0m"

        publish_dir="bin/publish/$rid"
        release_dir="bin/releases/$rid"

        # Create release directory
        mkdir -p "$release_dir"

        # Create Velopack package
        vpk pack --packId ScheduleEditor --packVersion "1.0.3" --packDir "$publish_dir" --outputDir "$release_dir" --framework net8 --runtime "$rid"

        if [ $? -ne 0 ]; then
            echo -e "\033[33mPackaging failed for $name\033[0m"
        fi
    done
fi

echo -e "\033[32mBuild completed successfully!\033[0m"