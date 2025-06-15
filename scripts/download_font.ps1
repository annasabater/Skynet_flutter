$fontUrl = "https://fonts.google.com/download?family=Press+Start+2P"
$outputPath = "assets/fonts/PressStart2P-Regular.ttf"

# Create directory if it doesn't exist
New-Item -ItemType Directory -Force -Path "assets/fonts"

# Download the font
Invoke-WebRequest -Uri $fontUrl -OutFile $outputPath

Write-Host "Font downloaded successfully to $outputPath" 