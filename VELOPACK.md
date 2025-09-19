# Velopack Build and Release Setup

This document explains how to build and release the Schedule Editor application using Velopack for cross-platform distribution.

## Prerequisites

- .NET 8.0 SDK
- Velopack CLI (`vpk`) - automatically installed by build scripts

## Building Locally

### Using PowerShell (Windows/Cross-platform)

```powershell
# Build only
./build.ps1

# Build and create packages
./build.ps1 -Pack

# Build with Ready-to-Run (faster startup, larger files)
./build.ps1 -ReadyToRun -Pack

# Specify configuration
./build.ps1 -Configuration Debug -Pack
```

### Using Bash (Linux/macOS)

```bash
# Build only
./build.sh

# Build and create packages
./build.sh --pack

# Build with Ready-to-Run (faster startup, larger files)
./build.sh --ready-to-run --pack

# Specify configuration
./build.sh --configuration Debug --pack
```

## Build Outputs

- **Published applications**: `Source/bin/publish/{platform}/`
- **Velopack packages**: `Source/bin/releases/{platform}/`

### Supported Platforms

- **Windows x64**: `win-x64`
- **macOS x64**: `osx-x64` (Intel Macs)
- **macOS ARM64**: `osx-arm64` (Apple Silicon)
- **Linux x64**: `linux-x64`

## GitHub Actions Release Process

### Automatic Releases (Git Tags)

1. Create and push a git tag:
   ```bash
   git tag v1.0.4
   git push origin v1.0.4
   ```

2. GitHub Actions will automatically:
   - Build for all platforms
   - Create Velopack packages
   - Create a GitHub release with all installers

### Manual Releases

1. Go to Actions tab in GitHub
2. Select "Build and Release" workflow
3. Click "Run workflow"
4. Enter the version number (e.g., `1.0.4`)
5. Optionally enable "Ready-to-Run compilation" for faster startup
6. Click "Run workflow"

## Velopack Configuration

The Velopack configuration is stored in `Source/velopack.json`:

```json
{
  "version": "1.0.3",
  "title": "Schedule Editor",
  "icon": "Assets/icon.png",
  "owners": [ "Wilderness Labs" ],
  "authors": [ "Wilderness Labs" ],
  "description": "A desktop app for configuring a Meadow schedule",
  "splashImage": "Assets/icon.png",
  "mainExe": "ScheduleEditor.exe",
  "packId": "ScheduleEditor"
}
```

## Update Management

Velopack provides automatic update functionality:

- Users will be notified when new versions are available
- Updates download and install automatically
- The application can check for updates programmatically

## Ready-to-Run Compilation

Ready-to-Run (R2R) is an ahead-of-time compilation technology that:

### Benefits
- **Faster startup**: Reduces JIT compilation time
- **Improved performance**: Native code execution
- **Better cold-start**: Especially beneficial for desktop apps

### Trade-offs
- **Larger file size**: ~20-30% increase in application size
- **Longer build time**: Additional compilation during build
- **Platform-specific**: R2R images are platform-specific

### When to Use
- **Production releases**: Better user experience
- **Desktop applications**: Noticeable startup improvement
- **When file size is not critical**: Network/storage allows larger files

### File Size Comparison
- **Normal build**: ~95MB
- **Ready-to-Run**: ~123MB (+28MB / +29%)

## Installation Packages

Each platform creates different installer types:

- **Windows**: `.exe` installer
- **macOS**: `.dmg` disk image
- **Linux**: `.AppImage` portable application

## Troubleshooting

### Build Issues

1. **Missing vpk tool**: The build scripts automatically install the Velopack CLI
2. **Restore issues**: Run `dotnet restore Source/ScheduleEditor.csproj` manually
3. **Platform-specific issues**: Check that all dependencies support the target platform

### Release Issues

1. **GitHub Actions permissions**: Ensure the repository has appropriate permissions for creating releases
2. **Missing assets**: Check that the build completed successfully for all platforms
3. **Version conflicts**: Ensure the version number hasn't been used before

## Manual Velopack Commands

If you need to run Velopack commands manually:

```bash
# Install Velopack CLI
dotnet tool install -g vpk

# Create a package manually
vpk pack --packId ScheduleEditor --packVersion 1.0.3 --packDir ./bin/publish/win-x64 --outputDir ./bin/releases/win-x64 --framework net8 --runtime win-x64

# Upload releases (requires additional setup)
vpk upload --url https://api.github.com/releases --token <your-token>
```

## Version Management

To update the version:

1. Update `Source/ScheduleEditor.csproj` `<Version>` element
2. Update `Source/velopack.json` `version` field
3. Commit changes and create a new git tag
4. Push tag to trigger automatic release