# ============================================
# File Organizer Script - Full Version
# ============================================

# Define the main folder to organize
$sourceFolder = "C:\Users\deanschauer\Documents\PowerShell Scripts\FileOrganizer-Test"

# Define destination folders for each file type
$textFolder     = "$sourceFolder\Text"
$imageFolder    = "$sourceFolder\Images"
$documentFolder = "$sourceFolder\Documents"
$pdfFolder      = "$sourceFolder\PDFs"

# Create folders if they do not already exist
# Test-Path checks if a folder exists
# New-Item creates the folder if it does not exist

if (!(Test-Path $textFolder)) {
    New-Item -ItemType Directory -Path $textFolder
}

if (!(Test-Path $imageFolder)) {
    New-Item -ItemType Directory -Path $imageFolder
}

if (!(Test-Path $documentFolder)) {
    New-Item -ItemType Directory -Path $documentFolder
}

if (!(Test-Path $pdfFolder)) {
    New-Item -ItemType Directory -Path $pdfFolder
}

# Get all files from the source folder (ignore folders)
$files = Get-ChildItem -Path $sourceFolder -File

# Loop through each file one at a time
foreach ($file in $files) {

    # Display file information (useful for debugging and learning)
    Write-Host "Processing file:" $file.Name
    Write-Host "Extension is:" $file.Extension

    # Move text files
    if ($file.Extension -eq ".txt") {
        Move-Item -Path $file.FullName -Destination $textFolder
        Write-Host "Moved file to Text folder"
    }

    # Move image files
    elseif ($file.Extension -eq ".jpg" -or 
            $file.Extension -eq ".jpeg" -or 
            $file.Extension -eq ".png") {

        Move-Item -Path $file.FullName -Destination $imageFolder
        Write-Host "Moved file to Images folder"
    }

    # Move document-related files (Word, Excel, PowerPoint, Project)
    elseif ($file.Extension -eq ".docx" -or 
            $file.Extension -eq ".xlsx" -or 
            $file.Extension -eq ".pptx" -or 
            $file.Extension -eq ".mpp") {

        Move-Item -Path $file.FullName -Destination $documentFolder
        Write-Host "Moved file to Documents folder"
    }

    # Move PDF files
    elseif ($file.Extension -eq ".pdf") {
        Move-Item -Path $file.FullName -Destination $pdfFolder
        Write-Host "Moved file to PDFs folder"
    }

    # Catch any files that do not match a rule
    else {
        Write-Host "No matching folder rule for:" $file.Name
    }
}