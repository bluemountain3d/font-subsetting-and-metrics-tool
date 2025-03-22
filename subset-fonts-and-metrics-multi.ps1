License Section for Font Script

<#
===============================================================
Font Subsetting and Metrics Extraction Tool
===============================================================
Author: Egil Eskilsson (bluemountain3d)
License: Creative Commons Attribution 4.0 International (CC BY 4.0)
Version: 1.0 beta

This script provides functionality for subsetting fonts and 
extracting font metrics for web development and optimization.

This work is licensed under the Creative Commons Attribution 4.0
International License. To view a copy of this license, visit:
"http://creativecommons.org/licenses/by/4.0/"

You are free to:
- Share: copy and redistribute the material in any medium or format
- Adapt: remix, transform, and build upon the material for any purpose

Under the following terms:
- Attribution: You must give appropriate credit to Egil Eskilsson
  (bluemountain3d), provide a link to the license, and indicate if
  changes were made.

IMPORTANT FONT LICENSE NOTICE:
This tool processes font files that may be subject to their own
licensing terms. Users are solely responsible for ensuring they
have the appropriate rights to subset, modify, or use any fonts
processed with this tool.
The author assumes no responsibility for any font license
violations resulting from the use of this tool.
===============================================================
#>

# Get the directory where the script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Initialize summary and log
$summary = @()
$logPath = Join-Path -Path $scriptDir -ChildPath "font_processing.log"
"Starting font processing - $(Get-Date)" | Out-File -FilePath $logPath

# Ask the user what operation mode they want
Write-Host "`nWhat would you like to do?" -ForegroundColor Cyan
Write-Host "1. Subset fonts and extract metrics (full process)" -ForegroundColor White
Write-Host "2. Extract metrics only (no font subsetting)" -ForegroundColor White
Write-Host "3. Batch process with config file" -ForegroundColor White
$operationMode = Read-Host "Enter your choice (1-3)"

# Validate the choice
if ($operationMode -notin "1", "2", "3") {
  Write-Host "Invalid choice. Defaulting to full process (option 1)." -ForegroundColor Yellow
  $operationMode = "1"
}

# Output the selected mode
if ($operationMode -eq "1") {
  Write-Host "Mode: Full process - will subset fonts and extract metrics" -ForegroundColor Green
}
elseif ($operationMode -eq "2") {
  Write-Host "Mode: Metrics only - will only extract metrics without subsetting fonts" -ForegroundColor Green
}
else {
  Write-Host "Mode: Batch process - will use config file" -ForegroundColor Green
}

# Font Directory Selection Section
# This section determines which font directories to process based on user input or config file

# Initialize variables
$fontDirsToProcess = @()  # Will hold the directories to process
$config = $null           # Will hold config data if using batch mode

# Batch mode (option 3) - Use config file
if ($operationMode -eq "3") {
  # Prompt for config file path
  $configPath = Read-Host "Enter path to config file (e.g., config.json)"
  
  # Verify config file exists
  if (Test-Path $configPath) {
    # Load and parse JSON config
    $config = Get-Content $configPath | ConvertFrom-Json
    
    # Find directories that match the font folders specified in config
    $fontDirsToProcess = Get-ChildItem -Path $scriptDir -Directory | 
    Where-Object { $config.fontFolders -contains $_.Name }
    
    # Verify we found at least one valid font folder
    if ($fontDirsToProcess.Count -eq 0) {
      Write-Host "No valid font folders found in config. Exiting." -ForegroundColor Red
      "ERROR: No valid font folders in config - $(Get-Date)" | Out-File -FilePath $logPath -Append
      exit
    }
  }
  else {
    # Config file not found - exit with error
    Write-Host "Config file not found. Exiting." -ForegroundColor Red
    "ERROR: Config file not found - $(Get-Date)" | Out-File -FilePath $logPath -Append
    exit
  }
}
else {
  # Interactive mode (options 1 or 2)
  # Ask user how they want to select fonts
  Write-Host "How would you like to select fonts to process?" -ForegroundColor Cyan
  Write-Host "1. Process all fonts (prompting for each)" -ForegroundColor White
  Write-Host "2. Enter a comma-separated list of font folder names" -ForegroundColor White
  Write-Host "3. Process a single font folder" -ForegroundColor White
  $selectionMode = Read-Host "Enter your choice (1-3)"

  # Option 1: Process all fonts in the script directory
  if ($selectionMode -eq "1") {
    # Get all directories except the "subsetted" directory (which is used for output)
    $fontDirsToProcess = Get-ChildItem -Path $scriptDir -Directory | 
    Where-Object { $_.Name -ne "subsetted" }
  }
  # Option 2: Process fonts from a comma-separated list
  elseif ($selectionMode -eq "2") {
    # Get list of font names from user
    $fontList = Read-Host "Enter comma-separated list of font folder names (e.g. 'Roboto,OpenSans,Lato')"
    
    # Split the input into individual font names and trim whitespace
    $fontNames = $fontList -split ',' | ForEach-Object { $_.Trim() }
    
    # Find each requested font directory
    foreach ($fontName in $fontNames) {
      $fontDir = Get-ChildItem -Path $scriptDir -Directory | 
      Where-Object { $_.Name -eq $fontName }
      
      if ($fontDir) {
        # Add valid directory to the list
        $fontDirsToProcess += $fontDir
      }
      else {
        # Warn about missing directories
        Write-Host "Warning: Font folder '$fontName' not found" -ForegroundColor Yellow
      }
    }
    
    # Verify at least one valid font directory was found
    if ($fontDirsToProcess.Count -eq 0) {
      Write-Host "No valid font folders found. Exiting." -ForegroundColor Red
      exit
    }
    
    # Show which fonts will be processed
    Write-Host "Will process these font folders:" -ForegroundColor Green
    $fontDirsToProcess | ForEach-Object { Write-Host " - $($_.Name)" -ForegroundColor Cyan }
  }
  # Option 3: Process a single font folder selected by number
  elseif ($selectionMode -eq "3") {
    # Get all potential font directories
    $allFontDirs = Get-ChildItem -Path $scriptDir -Directory | 
    Where-Object { $_.Name -ne "subsetted" }
    
    # Display available font folders with numbers
    Write-Host "Available font folders:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $allFontDirs.Count; $i++) {
      Write-Host "$($i+1). $($allFontDirs[$i].Name)" -ForegroundColor White
    }
    
    # Get user selection by number
    $fontIndex = [int](Read-Host "Enter the number of the font to process (1-$($allFontDirs.Count))")
    
    # Validate selection is in range
    if ($fontIndex -ge 1 -and $fontIndex -le $allFontDirs.Count) {
      # Convert to 0-based index and get the selected directory
      $fontDirsToProcess = @($allFontDirs[$fontIndex - 1])
    }
    else {
      # Invalid selection - exit
      Write-Host "Invalid selection. Exiting." -ForegroundColor Red
      exit
    }
  }
  else {
    # Invalid selection mode - exit
    Write-Host "Invalid selection. Exiting." -ForegroundColor Red
    exit
  }
}

# Unicode Range Options Definition
# This hashtable defines the available Unicode character ranges for font subsetting
# Each option contains a name, description, Unicode range specification, and approximate character count
$unicodeRangeOptions = @{
  # Option 1: Minimal Western - Basic coverage for English and simple Western European text
  "1" = @{
    "Name"        = "Minimal Western"; # Display name
    "Description" = "Basic Latin + Latin-1 (English, Western European basics)"; # What languages it covers
    "Range"       = "U+0020-007F,U+00A0-00FF"; # Unicode ranges in hexadecimal
    "CharCount"   = "~192 characters"; # Approximate number of glyphs
  };
  
  # Option 2: Standard Western European - Adds Latin Extended-A for more Western European language support
  "2" = @{
    "Name"        = "Standard Western European";
    "Description" = "Western European languages (adds Latin Extended-A)";
    "Range"       = "U+0020-007F,U+00A0-00FF,U+0100-017F"; # Adds Latin Extended-A block
    "CharCount"   = "~320 characters";
  };
  
  # Option 3: Comprehensive European (Latin) - Full support for all Latin-based European languages
  "3" = @{
    "Name"        = "Comprehensive European (Latin)";
    "Description" = "All Latin-based European languages with special characters";
    # Includes Latin Extended-B, IPA Extensions, Combining Diacritical Marks, Latin Extended Additional, General Punctuation
    "Range"       = "U+0020-007F,U+00A0-00FF,U+0100-017F,U+0180-024F,U+0250-02AF,U+0300-036F,U+1E00-1EFF,U+2000-206F";
    "CharCount"   = "~1100 characters";
  };
  
  # Option 4: Full European - Adds Cyrillic and Greek for complete European language coverage
  "4" = @{
    "Name"        = "Full European";
    "Description" = "All European languages including Cyrillic and Greek";
    # Adds Greek and Cyrillic blocks to the Comprehensive European range
    "Range"       = "U+0020-007F,U+00A0-00FF,U+0100-017F,U+0180-024F,U+0250-02AF,U+0300-036F,U+0370-03FF,U+0400-04FF,U+1E00-1EFF,U+2000-206F";
    "CharCount"   = "~1500 characters";
  };
  
  # Option 5: Balanced Web Optimized - Carefully selected set balancing coverage and file size
  "5" = @{
    "Name"        = "Balanced Web Optimized";
    "Description" = "Optimized for web: Good coverage with reasonable file size";
    # Similar to Comprehensive European but adds superscripts/subscripts and trademark
    # Also includes the schwa character (U+0259) used in many languages
    "Range"       = "U+0020-007F,U+00A0-00FF,U+0100-017F,U+0180-024F,U+0259,U+0300-036F,U+1E00-1EFF,U+2000-206F,U+2070-209F,U+2122";
    "CharCount"   = "~1060 characters";
  };
  
  # Option 6: Custom - For users to enter their own Unicode range
  "6" = @{
    "Name"        = "Custom";
    "Description" = "Enter a custom Unicode range";
    "Range"       = ""; # Empty by default - will be filled by user input
    "CharCount"   = "Varies"; # Depends on user input
  };
  
  # Option 7: Custom Characters - For users to specify exact characters to include
  "7" = @{
    "Name"        = "Custom Characters";
    "Description" = "Enter specific characters to include (e.g., 'ABCabc123')";
    "Range"       = ""; # Empty by default - will be calculated from user input
    "CharCount"   = "Based on character count"; # Depends on user input
  };
}

# Function: Convert-CharactersToUnicodeRange
# Converts a string of characters to their Unicode code points in the format expected by fontTools
# This is used for option 7 (Custom Characters) to convert user input to proper Unicode ranges
# Parameters:
#   $characters - String of characters to include in the font subset
# Returns:
#   A comma-separated list of Unicode code points in the format "U+XXXX"
function Convert-CharactersToUnicodeRange {
  param ([string]$characters)
  
  # If no characters are provided, default to Basic Latin range
  if ([string]::IsNullOrWhiteSpace($characters)) {
    return "U+0020-007F" # Default to Basic Latin if empty
  }
  
  # Remove duplicate characters to avoid redundant entries
  $uniqueChars = $characters.ToCharArray() | Select-Object -Unique
  
  # Convert each character to its Unicode code point in "U+XXXX" format
  $unicodePoints = $uniqueChars | ForEach-Object { 
    $codePoint = [int][char]$_  # Get the Unicode code point as an integer
    "U+{0:X4}" -f $codePoint    # Format as "U+XXXX" with padded zeros
  }
  
  # Always ensure space character is included (important for text rendering)
  if (-not ($unicodePoints -contains "U+0020")) {
    $unicodePoints += "U+0020"
  }
  
  # Join all code points with commas to create the final range string
  return $unicodePoints -join ','
}

# Unicode Range Selection Section
# This section handles the selection of which Unicode character ranges to include in the subset fonts.
# The character selection directly impacts the final file size and language support of the font.

if ($operationMode -eq "1" -or $operationMode -eq "3") {
  # Only needed for full process or batch mode (not for metrics-only mode)
  
  # Skip Unicode range selection if we're in batch mode AND have a config file with a range specified
  if ($operationMode -ne "3" -or -not $config -or -not $config.unicodeRange) {
    # Display Unicode range options to the user
    Write-Host "`nSelect Unicode range coverage:" -ForegroundColor Cyan
    
    # Show all available options with their descriptions
    foreach ($key in $unicodeRangeOptions.Keys | Sort-Object) {
      Write-Host "$key. $($unicodeRangeOptions[$key].Name)" -ForegroundColor White
      Write-Host "   $($unicodeRangeOptions[$key].Description)" -ForegroundColor Gray
      Write-Host "   $($unicodeRangeOptions[$key].CharCount)" -ForegroundColor Gray
    }
    
    # Get user's choice    
    $rangeChoice = Read-Host "Enter your choice (1-7)"
    
    # Validate user input and handle invalid selections
    if ($rangeChoice -notin $unicodeRangeOptions.Keys) {
      Write-Host "Invalid choice. Defaulting to Balanced Web Optimized (5)." -ForegroundColor Yellow
      $rangeChoice = "5"  # Default to a good balance of coverage vs. file size
    }
    
    # Handle custom Unicode range input (option 6)
    if ($rangeChoice -eq "6") {
      $unicodeRanges = Read-Host "Enter custom Unicode range (e.g., 'U+0020-007F,U+00A0-00FF')"
      # Provide a fallback if the input is empty
      if ([string]::IsNullOrWhiteSpace($unicodeRanges)) {
        Write-Host "No range specified. Defaulting to Balanced Web Optimized." -ForegroundColor Yellow
        $unicodeRanges = $unicodeRangeOptions["5"].Range
      }
    }
    # Handle custom character list input (option 7)
    elseif ($rangeChoice -eq "7") {
      # Get specific characters from user
      $customChars = Read-Host "Enter specific characters to include (e.g., 'ABCabc123')"
      # Convert the characters to their Unicode code points
      $unicodeRanges = Convert-CharactersToUnicodeRange -characters $customChars
      # Show feedback on what was generated
      Write-Host "Generated Unicode range: $unicodeRanges" -ForegroundColor Green
      Write-Host "Characters included: $customChars" -ForegroundColor Green
    }
    # Handle predefined range selections (options 1-5)
    else {
      $unicodeRanges = $unicodeRangeOptions[$rangeChoice].Range
      Write-Host "Selected: $($unicodeRangeOptions[$rangeChoice].Name)" -ForegroundColor Green
    }
  }
  else {
    # In batch mode with a config file, use the range from the config
    $unicodeRanges = $config.unicodeRange
    Write-Host "Using Unicode range from config file: $unicodeRanges" -ForegroundColor Green
  }
}
else {
  # For metrics-only mode, we don't need to subset fonts, so no Unicode ranges needed
  $unicodeRanges = ""
}

# Check and install dependencies
python -c "import brotli" 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Brotli not installed. Installing..." -ForegroundColor Yellow
  python -m pip install brotli
}

# Python script for Brotli compression
# This creates a separate Python script file that handles the Brotli compression
# to avoid syntax issues with escaping paths in inline Python commands.
# The script takes two arguments: input file path and output file path.
$pythonBrotliCompress = @"
import brotli
import sys

input_file = sys.argv[1]
output_file = sys.argv[2]

try:
    with open(input_file, 'rb') as f:
        data = f.read()
    
    compressed = brotli.compress(data)
    
    with open(output_file, 'wb') as f:
        f.write(compressed)
    
    print(f"Successfully compressed {input_file} to {output_file}")
except Exception as e:
    print(f"Error: {str(e)}")
    sys.exit(1)
"@

$pythonBrotliCompressPath = Join-Path -Path $scriptDir -ChildPath "brotli_compress.py"
$pythonBrotliCompress | Out-File -FilePath $pythonBrotliCompressPath -Encoding utf8


# Python script to extract font metrics (with x-height and SCSS support)
# Python script for extracting font metrics
# This script analyzes font files and extracts key typography metrics
# for use in web design and layout calculations
$pythonExtractMetrics = @"
from fontTools.ttLib import TTFont  # Library for working with font files
import sys  # For command line arguments
import os   # For file path operations
import json # For JSON output format

# Get command line arguments
font_path = sys.argv[1]      # Path to the font file
output_path = sys.argv[2]    # Path where metrics will be saved
format_type = sys.argv[3] if len(sys.argv) > 3 else 'js'  # Output format (js, json, css, scss)

# Extract the filename without extension
filename = os.path.basename(font_path).split('.')[0]
font = TTFont(font_path)  # Load the font file

# Extract font family name from the font's name table
# We try both nameID 1 (Font Family name) and nameID 16 (Preferred Family name)
family_name = None
preferred_family_name = None
for record in font['name'].names:
    # nameID 1 is the Font Family name
    if record.nameID == 1 and not family_name:
        if record.isUnicode():
            family_name = record.toUnicode()
        else:
            # Try different encodings if not Unicode
            try:
                family_name = record.string.decode('utf-8')
            except:
                try:
                    family_name = record.string.decode('latin-1')
                except:
                    pass
    # nameID 16 is the Preferred Family name (often used in newer fonts)
    if record.nameID == 16 and not preferred_family_name:
        if record.isUnicode():
            preferred_family_name = record.toUnicode()
        else:
            try:
                preferred_family_name = record.string.decode('utf-8')
            except:
                try:
                    preferred_family_name = record.string.decode('latin-1')
                except:
                    pass

# Use preferred name if available, otherwise family name, otherwise filename
base_font_name = preferred_family_name or family_name or filename
# If we still only have the filename, try to clean it by removing weight indicators
if base_font_name == filename:
    for weight in ['Regular', 'Bold', 'Italic', 'Medium', 'Light', 'Black']:
        if weight in base_font_name:
            base_font_name = base_font_name.replace(weight, '').strip('-_ ')

# Re-load font (redundant, but ensures clean state)
font = TTFont(font_path)
# Get units per em - this is needed to normalize all measurements
units_per_em = font['head'].unitsPerEm
# Get OS/2 and horizontal header tables which contain key metrics
os2 = font['OS/2']
hhea = font['hhea']

# Calculate average character width
x_avg_width = os2.xAvgCharWidth / units_per_em

# Calculate cap height (height of capital letters)
cap_height = 0.0
if hasattr(os2, 'sCapHeight'):
    # Use OS/2 table if available
    cap_height = os2.sCapHeight / units_per_em
else:
    # Otherwise estimate from the 'H' character
    if 'H' in font.getBestCmap():
        glyph_name = font.getBestCmap()[ord('H')]
        if glyph_name in font['glyf'].glyphs:
            cap_height = font['glyf'][glyph_name].yMax / units_per_em

# Calculate x-height (height of lowercase letters)
x_height = 0.0
if hasattr(os2, 'sxHeight'):
    # Use OS/2 table if available
    x_height = os2.sxHeight / units_per_em
else:
    # Otherwise estimate from the 'x' character
    if 'x' in font.getBestCmap():
        glyph_name = font.getBestCmap()[ord('x')]
        if glyph_name in font['glyf'].glyphs:
            x_height = font['glyf'][glyph_name].yMax / units_per_em

# Calculate d-height (height of ascenders in lowercase)
d_height = 0.0
if 'd' in font.getBestCmap():
    glyph_name = font.getBestCmap()[ord('d')]
    if glyph_name in font['glyf'].glyphs:
        d_height = font['glyf'][glyph_name].yMax / units_per_em

# Calculate adjusted ascender and descender values
# These account for any mismatch between the font's total height and unitsPerEm
ascender = hhea.ascent
descender = hhea.descent
adjustment = (ascender + abs(descender) - units_per_em) / 2
adjusted_ascender = (ascender - adjustment) / units_per_em
adjusted_descender = 1 - adjusted_ascender

# Calculate average left side bearing for common straight-sided letters
# This helps with fine-tuning alignment in designs
lsb_letters = ['B', 'D', 'E', 'F', 'H', 'I', 'K', 'L', 'P', 'R']
lsb_values = []
cmap = font.getBestCmap()
for letter in lsb_letters:
    if ord(letter) in cmap:
        glyph_name = cmap[ord(letter)]
        if 'hmtx' in font and glyph_name in font['hmtx'].metrics:
            lsb = font['hmtx'].metrics[glyph_name][1]
            lsb_normalized = lsb / units_per_em
            lsb_values.append(lsb_normalized)

# Calculate average left side bearing
avg_lsb = 0.0
if lsb_values:
    avg_lsb = sum(lsb_values) / len(lsb_values)

# Set recommended line height multiplier
line_height = 1.2  # Standard recommendation: 1.2x the font size

# Format output based on the requested format type
if format_type == 'js':
    # JavaScript object format
    metrics_text = f"'{base_font_name}': {{\n"
    metrics_text += f"  'font-family': '\"{base_font_name}\"',\n"
    metrics_text += f"  'cap-height': {cap_height:.3f},\n"
    metrics_text += f"  'x-height': {x_height:.3f},\n"
    metrics_text += f"  'd-height': {d_height:.3f},\n"
    metrics_text += f"  'ch-width': {x_avg_width:.3f},\n"
    metrics_text += f"  'line-gap': {line_height:.3f},\n"
    metrics_text += f"  'ascender': {adjusted_ascender:.3f},\n"
    metrics_text += f"  'descender': {adjusted_descender:.3f},\n"
    metrics_text += f"  'lsb-adjust': {avg_lsb:.3f},\n"
    metrics_text += "  }},"
elif format_type == 'json':
    # JSON format
    metrics_json = json.dumps({
        "font-family": base_font_name,
        "cap-height": cap_height,
        "x-height": x_height,
        "d-height": d_height,
        "ch-width": x_avg_width,
        "line-gap": line_height,
        "ascender": adjusted_ascender,
        "descender": adjusted_descender,
        "lsb-adjust": avg_lsb        
    }, indent=2)
    with open(output_path.replace('.js', '.json'), 'w') as f:
        f.write(metrics_json)
    print(metrics_json)
elif format_type == 'css':
    # CSS @font-face rule with metrics in custom properties
    metrics_text = f"@font-face {{ font-family: '{base_font_name}'; src: url('{base_font_name.lower()}.woff2') format('woff2'); }}"
elif format_type == 'scss':
    # SCSS map format for use in Sass
    # Create a clean variable name for SCSS
    scss_var_name = base_font_name.lower().replace(' ', '-')
    
    # No comment line here - it will be added by PowerShell
    metrics_text = f"'{scss_var_name}': (\n"
    metrics_text += f"  'font-family': '{base_font_name}',\n"
    metrics_text += f"  'cap-height': {cap_height:.3f},\n"
    metrics_text += f"  'x-height': {x_height:.3f},\n"
    metrics_text += f"  'd-height': {d_height:.3f},\n"
    metrics_text += f"  'ch-width': {x_avg_width:.3f},\n"
    metrics_text += f"  'line-gap': {line_height:.3f},\n"
    metrics_text += f"  'ascender': {adjusted_ascender:.3f},\n"
    metrics_text += f"  'descender': {adjusted_descender:.3f},\n"
    metrics_text += f"  'lsb-adjust': {avg_lsb:.3f}\n"
    metrics_text += ");"

if format_type != 'json':
    # Write output to file with correct extension
    # Make sure we use the correct file extension
    correct_path = output_path.replace('.js', '.' + format_type)
    with open(correct_path, 'w') as f:
        f.write(metrics_text)
        
# Print metrics to console (captured by PowerShell)
print(metrics_text)
"@

$pythonExtractMetricsPath = Join-Path -Path $scriptDir -ChildPath "extract_metrics.py"
$pythonExtractMetrics | Out-File -FilePath $pythonExtractMetricsPath -Encoding utf8

# Python script to parse and create features.json
# This helper script manages the OpenType feature settings stored in features.json
# It supports two operations:
#   1. Reading features from an existing features.json file
#   2. Writing user-selected features to a new features.json file
$pythonParseFeatures = @"
import sys
import json
import os

# Get command line arguments
command = sys.argv[1]  # Operation to perform: "read" or "write"
features_file = sys.argv[2]  # Path to the features.json file

if command == "read":
    # Read operation: Extract features from existing features.json
    try:
        # Check if the file exists
        if os.path.exists(features_file):
            with open(features_file, 'r') as f:
                try:
                    # Parse JSON content
                    data = json.load(f)
                    # Verify expected structure: should have "openTypeFeatures" as a list
                    if 'openTypeFeatures' in data and isinstance(data['openTypeFeatures'], list):
                        # Convert list of features to comma-separated string
                        features_str = ','.join(data['openTypeFeatures'])
                        print(features_str)  # Output for PowerShell to capture
                    else:
                        print("ERROR: Invalid format in features.json")
                except json.JSONDecodeError:
                    # Handle malformed JSON
                    print("ERROR: Invalid JSON in features.json")
        else:
            print("ERROR: features.json not found")
    except Exception as e:
        # Handle any unexpected errors
        print(f"ERROR: {str(e)}")
elif command == "write":
    # Write operation: Create a new features.json with provided features
    try:
        # Get the features from command line
        features_input = sys.argv[3]  # Comma-separated feature list
        
        # Handle special values
        if features_input in ["none", "all"]:
            # No need to create file for these special values
            print(f"INFO: Not creating features.json for special value: {features_input}")
            exit(0)
            
        # Split the comma-separated list and clean up any whitespace
        features_list = [f.strip() for f in features_input.split(',')]
        
        # Create the JSON object with proper structure
        features_obj = {"openTypeFeatures": features_list}
        
        # Write to file with pretty formatting (indentation)
        with open(features_file, 'w') as f:
            json.dump(features_obj, f, indent=2)
            
        print(f"INFO: Created features.json with {len(features_list)} features")
    except Exception as e:
        # Handle any errors during writing
        print(f"ERROR: {str(e)}")
"@

# Save the Python script to a file
$pythonParseFeaturesPath = Join-Path -Path $scriptDir -ChildPath "parse_features.py"
$pythonParseFeatures | Out-File -FilePath $pythonParseFeaturesPath -Encoding utf8

# Functions section
# These functions handle various aspects of font processing and OpenType feature management

#region Font Name Processing

# Function: Is-RegularFont
# Determines if a font is a "Regular" variant (as opposed to Bold, Italic, etc.)
# This is important because we typically extract metrics only from regular fonts
# Parameters:
#   $fontName - The name of the font file (without extension)
# Returns:
#   $true if the font is considered "regular", $false otherwise
function Is-RegularFont {
  param ([string]$fontName)
  # If "Regular" is explicitly in the name, it's a regular font
  if ($fontName -match 'Regular') { return $true }
  # If none of the common weight/style indicators are in the name, assume it's regular
  if (-not ($fontName -match 'Bold|Italic|Medium|Light|ExtraLight|Black|Thin|ExtraBold|SemiBold|Oblique|Condensed')) { return $true }
  # Otherwise, it's not a regular font
  return $false
}

# Function: Get-BaseFontName
# Extracts the base font family name by removing weight/style indicators
# Example: "Roboto-Bold" becomes "Roboto"
# Parameters:
#   $fontName - The name of the font file (without extension)
# Returns:
#   The cleaned base font family name
function Get-BaseFontName {
  param ([string]$fontName)
  $baseName = $fontName
  # Remove all common weight and style indicators
  foreach ($weight in @('Regular', 'Bold', 'Italic', 'Medium', 'Light', 'ExtraLight', 'Black', 'Thin', 'ExtraBold', 'SemiBold', 'Oblique', 'Condensed')) {
    $baseName = $baseName -replace $weight, ''
  }
  # Clean up any remaining separators
  return $baseName.Trim('-_ ')
}
#endregion

#region OpenType Feature Management

# Function: Get-JsonFeatures
# Reads OpenType feature settings from features.json if it exists
# Parameters:
#   $fontDirPath - Path to the font directory
# Returns:
#   String containing comma-separated OpenType features, or $null if not found
function Get-JsonFeatures {
  param ([string]$fontDirPath)
  # Construct path to features.json
  $featuresJsonPath = Join-Path -Path $fontDirPath -ChildPath "features.json"
  # Check if file exists
  if (Test-Path $featuresJsonPath) {
    # Use the Python helper script to read and parse the features file
    $pythonCmd = "python `"$pythonParseFeaturesPath`" read `"$featuresJsonPath`""
    $result = Invoke-Expression $pythonCmd
    # Only return valid results (non-error output)
    if ($result -and -not $result.StartsWith("ERROR:")) {
      return $result.Trim()
    }
  }
  return $null
}

# Function: Save-JsonFeatures
# Saves OpenType feature settings to features.json
# Parameters:
#   $fontDirPath - Path to the font directory
#   $features - Comma-separated string of OpenType features
# Returns:
#   $true if saved successfully, $false otherwise
function Save-JsonFeatures {
  param ([string]$fontDirPath, [string]$features)
  # Construct path to features.json
  $featuresJsonPath = Join-Path -Path $fontDirPath -ChildPath "features.json"
  # Use the Python helper script to write the features file
  $pythonCmd = "python `"$pythonParseFeaturesPath`" write `"$featuresJsonPath`" `"$features`""
  $result = Invoke-Expression $pythonCmd
  # Check if operation was successful based on output
  if ($result -and $result.StartsWith("INFO:")) {
    Write-Host "    $result" -ForegroundColor Green
    return $true
  }
  else {
    # Handle failure cases with appropriate error messaging
    if ($result) { Write-Host "    $result" -ForegroundColor Red }
    else { Write-Host "    Failed to create features.json" -ForegroundColor Red }
    return $false
  }
}

# Function: Prompt-OpenTypeFeatures
# Interactive function to get OpenType features from the user or features.json
# Provides information about common OpenType features and handles saving preferences
# Parameters:
#   $fontDirName - Name of the font directory (for display purposes)
#   $jsonFeatures - Features already loaded from features.json, if any
#   $fontDirPath - Path to the font directory
# Returns:
#   Array with two elements: 
#     [0] The fontTools command line parameter for features
#     [1] The raw feature string for other uses
function Prompt-OpenTypeFeatures {
  param ([string]$fontDirName, [string]$jsonFeatures, [string]$fontDirPath)
  
  # If features.json exists, offer to use those settings
  if ($jsonFeatures) {
    Write-Host "Found features.json with features: $jsonFeatures" -ForegroundColor Green
    $useJsonFeatures = Read-Host "Use these features from features.json? (Y/n)"
    if ($useJsonFeatures -ne "n" -and $useJsonFeatures -ne "N") {
      return "--layout-features=`"$jsonFeatures`"", $jsonFeatures
    }
  }
  
  # Otherwise prompt for features with helpful information
  Write-Host "`nEnter OpenType features for $fontDirName (comma separated, e.g. 'kern,liga,onum')" -ForegroundColor Cyan
  Write-Host "Common features:" -ForegroundColor Yellow
  Write-Host "  kern - Kerning" -ForegroundColor Gray
  Write-Host "  liga - Standard Ligatures" -ForegroundColor Gray
  Write-Host "  dlig - Discretionary Ligatures" -ForegroundColor Gray
  Write-Host "  onum - Oldstyle Figures" -ForegroundColor Gray
  Write-Host "  lnum - Lining Figures" -ForegroundColor Gray
  Write-Host "  pnum - Proportional Figures" -ForegroundColor Gray
  Write-Host "  tnum - Tabular Figures" -ForegroundColor Gray
  Write-Host "  smcp - Small Capitals" -ForegroundColor Gray
  Write-Host "  c2sc - Capitals to Small Capitals" -ForegroundColor Gray
  Write-Host "  sups - Superscript" -ForegroundColor Gray
  Write-Host "  subs - Subscript" -ForegroundColor Gray
  Write-Host "  frac - Fractions" -ForegroundColor Gray
  Write-Host "  numr - Numerators" -ForegroundColor Gray
  Write-Host "  dnom - Denominators" -ForegroundColor Gray
  Write-Host "  case - Case-Sensitive Forms" -ForegroundColor Gray
  Write-Host "  zero - Slashed Zero" -ForegroundColor Gray
  Write-Host "Enter '*' for all features, or leave empty for none" -ForegroundColor Yellow
  
  # Get user input
  $featuresInput = Read-Host "Features for $fontDirName"
  
  # Process the input
  if ([string]::IsNullOrWhiteSpace($featuresInput)) {
    # No features
    $featuresParam = ""
    $featuresString = "none"
  }
  elseif ($featuresInput -eq "*") {
    # All features
    $featuresParam = "--layout-features+=*"
    $featuresString = "all"
  }
  else {
    # Specific features
    $featuresParam = "--layout-features=`"$featuresInput`""
    $featuresString = $featuresInput
  }
  
  # Offer to save to features.json for future use
  # Only prompt if the features are different from what's already saved
  if (-not $jsonFeatures -or ($jsonFeatures -ne $featuresString -and $featuresString -ne "none")) {
    $createJson = Read-Host "Save these features to features.json? (Y/n)"
    if ($createJson -ne "n" -and $createJson -ne "N") {
      Save-JsonFeatures -fontDirPath $fontDirPath -features $featuresString
    }
  }
  
  return $featuresParam, $featuresString
}
#endregion

# Get metrics format (once, before processing)
$metricsFormat = "1"
if ($operationMode -ne "3") {
  Write-Host "Select metrics output format:" -ForegroundColor Cyan
  Write-Host "1. JavaScript (default)" -ForegroundColor White
  Write-Host "2. JSON" -ForegroundColor White
  Write-Host "3. CSS" -ForegroundColor White
  Write-Host "4. SCSS Map" -ForegroundColor White
  $metricsFormat = Read-Host "Enter your choice (1-4)"
}
if ($metricsFormat -notin "1", "2", "3", "4") {
  Write-Host "Invalid choice. Defaulting to JavaScript." -ForegroundColor Yellow
  $metricsFormat = "1"
}
$formatType = switch ($metricsFormat) {
  "1" { "js" }
  "2" { "json" }
  "3" { "css" }
  "4" { "scss" }
}

# Main processing loop - processes each font directory
# This is the heart of the script that handles the font subsetting and metrics extraction
foreach ($fontDir in $fontDirsToProcess) {
  # Get full path and name of the current font directory
  $fontDirPath = $fontDir.FullName
  $fontDirName = $fontDir.Name
  
  # Display header for current font directory
  Write-Host "`n===============================================" -ForegroundColor Blue
  Write-Host "Font directory: $fontDirName" -ForegroundColor Cyan
  Write-Host "===============================================" -ForegroundColor Blue

  # Prompt user to confirm processing (skip in batch mode)
  $processFont = "Y"
  if ($operationMode -ne "3") {
    $processFont = Read-Host "Do you want to process this font? (Y/n)"
  }
  
  # Skip this font if user chose not to process it
  if ($processFont -eq "n" -or $processFont -eq "N") {
    Write-Host "Skipping $fontDirName..." -ForegroundColor Yellow
    $summary += [PSCustomObject]@{ FontName = $fontDirName; Status = "Skipped"; MetricsExtracted = $false; WOFF2Size = 0; Features = "none" }
    continue
  }

  # Begin processing the font directory
  Write-Host "Processing font directory: $fontDirName" -ForegroundColor Cyan
  
  # Create directory structure for outputs
  $metricsDir = Join-Path -Path $fontDirPath -ChildPath "metrics"
  $subsettedDir = Join-Path -Path $fontDirPath -ChildPath "subsetted"
  New-Item -ItemType Directory -Force -Path $metricsDir | Out-Null
  New-Item -ItemType Directory -Force -Path $subsettedDir | Out-Null
  
  # Initialize metrics file with a header comment
  $metricsFilePath = Join-Path -Path $metricsDir -ChildPath "metrics.$formatType"
  "// Font metrics for $fontDirName" | Out-File -FilePath $metricsFilePath

  # Get OpenType features for subsetting (in full and batch modes)
  if ($operationMode -eq "1" -or $operationMode -eq "3") {
    # Get features either from config file or from features.json
    $jsonFeatures = if ($config) { $config.features } else { Get-JsonFeatures -fontDirPath $fontDirPath }
    
    # Get features parameter and raw string - either from config or user input
    $featuresResult = if ($config) { 
      @("--layout-features=`"$jsonFeatures`"", $jsonFeatures) 
    }
    else { 
      Prompt-OpenTypeFeatures -fontDirName $fontDirName -jsonFeatures $jsonFeatures -fontDirPath $fontDirPath 
    }
    $featuresParam = $featuresResult[0]  # Command-line parameter format
    $featuresString = $featuresResult[1] # Raw string format

    # Get optimization level from user (except in batch mode)
    $optimizationLevel = "1"
    if ($operationMode -ne "3") {
      Write-Host "Optimization level?" -ForegroundColor Cyan
      Write-Host "1. Light (default)" -ForegroundColor White
      Write-Host "2. Medium (remove unused glyphs)" -ForegroundColor White
      Write-Host "3. Aggressive (basic glyphs only)" -ForegroundColor White
      $optimizationLevel = Read-Host "Enter your choice (1-3)"
    }
    # Default to level 1 if invalid input
    if ($optimizationLevel -notin "1", "2", "3") { $optimizationLevel = "1" }

    # Create directory for WOFF2 output files
    $woff2Dir = Join-Path -Path $subsettedDir -ChildPath "woff2"
    New-Item -ItemType Directory -Force -Path $woff2Dir | Out-Null

    # Check which font formats exist in the directory
    $hasTTF = (Get-ChildItem -Path $fontDirPath -Filter "*.ttf" -File).Count -gt 0
    $hasOTF = (Get-ChildItem -Path $fontDirPath -Filter "*.otf" -File).Count -gt 0
    $hasWOFF = (Get-ChildItem -Path $fontDirPath -Filter "*.woff" -File).Count -gt 0
    $hasWOFF2 = (Get-ChildItem -Path $fontDirPath -Filter "*.woff2" -File).Count -gt 0

    # Create format-specific output directories only if needed
    $ttfDir = if ($hasTTF) { 
      $dir = Join-Path -Path $subsettedDir -ChildPath "ttf"
      New-Item -ItemType Directory -Force -Path $dir | Out-Null
      $dir
    }
    else { $null }
    
    $otfDir = if ($hasOTF) { 
      $dir = Join-Path -Path $subsettedDir -ChildPath "otf"
      New-Item -ItemType Directory -Force -Path $dir | Out-Null
      $dir
    }
    else { $null }
  }
  else {
    # In metrics-only mode, don't worry about OpenType features
    $featuresString = "none"
  }

  # Track which font families we've already processed metrics for (to avoid duplicates)
  $processedFontFamilies = @{}
  
  # Get all font files in the directory
  $fontFiles = Get-ChildItem -Path $fontDirPath -Filter "*.*" | Where-Object { $_.Extension -in ".ttf", ".otf", ".woff", ".woff2" }
  
  # Process each font file individually
  foreach ($fontFile in $fontFiles) {
    $fontFileName = $fontFile.Name
    $fontName = [System.IO.Path]::GetFileNameWithoutExtension($fontFileName)
    Write-Host "  Processing $fontFileName..." -ForegroundColor Cyan

    # For WOFF/WOFF2 formats, convert to TTF first (since fontTools works better with TTF)
    $tempTTF = $fontFile.FullName
    if ($fontFile.Extension -in ".woff", ".woff2") {
      $tempTTF = Join-Path -Path $fontDirPath -ChildPath "$fontName-temp.ttf"
      python -c "from fontTools.ttLib import TTFont; f = TTFont('$($fontFile.FullName)'); f.flavor = None; f.save('$tempTTF')"
    }

    # Font subsetting section (for full process and batch modes)
    $woff2OutputPath = $null
    if ($operationMode -eq "1" -or $operationMode -eq "3") {
      # Build common arguments for the fontTools subsetter
      $commonArgs = "--unicodes=`"$unicodeRanges`" " +
      "$featuresParam " +
      # Optimization: remove unnecessary tables
      "--drop-tables+=DSIG " +
      "--drop-tables+=FFTM " +
      # Optimization: remove unnecessary name records
      "--name-IDs-=0 " +
      "--name-IDs-=5 " +
      "--name-IDs-=7 " +
      "--name-IDs-=8 " +
      "--name-IDs-=9 " +
      "--name-IDs-=11 " +
      "--name-IDs-=13 " +
      "--name-IDs-=14 " +
      "--name-legacy " +
      "--name-languages=`"*`" " +
      # Optimization: reduce file size
      "--no-notdef-outline " +
      "--ignore-missing-glyphs"
      
      # Apply additional optimizations based on selected level
      if ($optimizationLevel -eq "2") { 
        # Medium optimization: remove hinting and subroutines
        $commonArgs += " --desubroutinize --no-hinting" 
      }
      if ($optimizationLevel -eq "3") { 
        # Aggressive optimization: keep only basic glyphs, remove hinting and subroutines
        $commonArgs += " --glyphs-to-keep=`"A-Za-z0-9`" --desubroutinize --no-hinting" 
      }

      try {
        # Process TTF files
        if ($fontFile.Extension -eq ".ttf" -and $hasTTF) {
          $ttfOutputPath = Join-Path -Path $ttfDir -ChildPath "$fontName-subset.ttf"
          $ttfCommand = "python -m fontTools.subset `"$tempTTF`" --output-file=`"$ttfOutputPath`" $commonArgs"
          Invoke-Expression $ttfCommand
          if (Test-Path $ttfOutputPath) { 
            Write-Host "    TTF created successfully." -ForegroundColor Green 
          }
          else { 
            Write-Host "    Failed to create TTF!" -ForegroundColor Red 
          }
        }
        # Process OTF files
        elseif ($fontFile.Extension -eq ".otf" -and $hasOTF) {
          $otfOutputPath = Join-Path -Path $otfDir -ChildPath "$fontName-subset.otf"
          $otfCommand = "python -m fontTools.subset `"$tempTTF`" --output-file=`"$otfOutputPath`" $commonArgs"
          Invoke-Expression $otfCommand
          if (Test-Path $otfOutputPath) { 
            Write-Host "    OTF created successfully." -ForegroundColor Green 
          }
          else { 
            Write-Host "    Failed to create OTF!" -ForegroundColor Red 
          }
        }

        # Create WOFF2 file (from subset TTF/OTF if available, otherwise from original)
        $lowercaseFontName = $fontName.ToLower()
        $woff2OutputPath = Join-Path -Path $woff2Dir -ChildPath "$lowercaseFontName.woff2"
        
        # Determine input file for WOFF2 conversion
        $inputForWoff2 = if ($fontFile.Extension -eq ".ttf" -and $hasTTF -and (Test-Path $ttfOutputPath)) { 
          $ttfOutputPath  # Use subsetted TTF if available
        }
        elseif ($fontFile.Extension -eq ".otf" -and $hasOTF -and (Test-Path $otfOutputPath)) { 
          $otfOutputPath  # Use subsetted OTF if available 
        }
        else { 
          $tempTTF  # Use the original or temporary TTF otherwise
        }
        
        # Convert to WOFF2 format
        python -m fontTools.ttLib.woff2 compress `"$inputForWoff2`" -o `"$woff2OutputPath`"
        
        if (Test-Path $woff2OutputPath) {
          Write-Host "    WOFF2 created successfully." -ForegroundColor Green
          
          # Compress with Brotli for additional file size reduction
          $woff2Compressed = "$woff2OutputPath.br"
          $pythonBrotliCmd = "python `"$pythonBrotliCompressPath`" `"$woff2OutputPath`" `"$woff2Compressed`""
          Invoke-Expression $pythonBrotliCmd
          
          if (Test-Path $woff2Compressed) { 
            Write-Host "    WOFF2 Brotli compressed." -ForegroundColor Green 
          }
        }
        else {
          # Handle WOFF2 conversion failure
          Write-Host "    Failed to create WOFF2!" -ForegroundColor Red
          "ERROR: WOFF2 creation failed for $fontFileName - $(Get-Date)" | Out-File -FilePath $logPath -Append
          
          # Offer retry (except in batch mode)
          $retry = if ($operationMode -eq "3") { "n" } else { Read-Host "Retry WOFF2 conversion? (Y/n)" }
          if ($retry -ne "n" -and $retry -ne "N") {
            python -m fontTools.ttLib.woff2 compress `"$inputForWoff2`" -o `"$woff2OutputPath`"
            if (Test-Path $woff2OutputPath) { 
              Write-Host "    WOFF2 created successfully on retry." -ForegroundColor Green 
            }
            else { 
              Write-Host "    Retry failed!" -ForegroundColor Red 
            }
          }
        }
      }
      catch {
        # Log any errors during processing
        Write-Host "    Error processing font: $_" -ForegroundColor Red
        "ERROR: $_ - $(Get-Date)" | Out-File -FilePath $logPath -Append
      }
    }

    # Metrics extraction section - Only extract metrics for regular font variants
    if (Is-RegularFont -fontName $fontName) {
      $baseFontName = Get-BaseFontName -fontName $fontName
      
      # Skip if we've already processed metrics for this font family
      if (-not $processedFontFamilies.ContainsKey($baseFontName)) {
        Write-Host "    Extracting font metrics for $baseFontName..." -ForegroundColor Cyan
        
        # Set up temporary path for individual metrics
        $singleMetricsPath = Join-Path -Path $subsettedDir -ChildPath "$fontName-metrics.$formatType"
        $pythonCmd = "python `"$pythonExtractMetricsPath`" `"$tempTTF`" `"$singleMetricsPath`" $formatType"
        
        try {
          # Run metrics extraction
          Invoke-Expression $pythonCmd
          
          if (Test-Path $singleMetricsPath) {
            $metricsContent = Get-Content -Path $singleMetricsPath -Raw
            
            try {
              # Use Out-File instead of Add-Content to avoid file locking issues
              $existingContent = if (Test-Path $metricsFilePath) { 
                Get-Content -Path $metricsFilePath -Raw -ErrorAction SilentlyContinue 
              }
              else { 
                "" 
              }
              
              # Append new metrics to existing file
              $newContent = $existingContent + $metricsContent
              $newContent | Out-File -FilePath $metricsFilePath -Force
    
              # Clean up temporary file and mark as processed
              Remove-Item -Path $singleMetricsPath
              $processedFontFamilies[$baseFontName] = $true
              Write-Host "    Metrics saved for $baseFontName" -ForegroundColor Green
    
              # Add OpenType features information to metrics file if applicable
              if ($operationMode -eq "1" -or $operationMode -eq "3") {
                if ($featuresString -ne "none" -and $featuresString -ne "") {
                  $featuresComment = "// $baseFontName open type features: $featuresString`r`n"
                  $existingContent = Get-Content -Path $metricsFilePath -Raw -ErrorAction SilentlyContinue
                  $newContent = $existingContent + $featuresComment
                  $newContent | Out-File -FilePath $metricsFilePath -Force
                }
              }
            }
            catch {
              # Handle errors when writing to metrics file
              Write-Host "    Error writing metrics file: $_" -ForegroundColor Red
              "ERROR: Failed to write metrics file for $fontFileName - $_ - $(Get-Date)" | Out-File -FilePath $logPath -Append
            }
          }
          else {
            Write-Host "    Failed to extract metrics!" -ForegroundColor Red
          }
        }
        catch {
          # Handle errors during metrics extraction
          Write-Host "    Error extracting metrics: $_" -ForegroundColor Red
          "ERROR: Metrics extraction failed for $fontFileName - $_ - $(Get-Date)" | Out-File -FilePath $logPath -Append
        }
      }
      else {
        # Skip duplicate metrics extraction
        Write-Host "    Skipping duplicate metrics for $baseFontName" -ForegroundColor Yellow
      }
    }
    else {
      # Skip metrics extraction for non-regular fonts
      Write-Host "    Skipping metrics extraction for non-regular font" -ForegroundColor Gray
    }

    # Clean up temporary files
    if ($fontFile.Extension -in ".woff", ".woff2" -and (Test-Path $tempTTF)) {
      Remove-Item $tempTTF
    }

    # Add processing summary for this font
    $summary += [PSCustomObject]@{
      FontFolder       = $fontDirName
      FontName         = $baseFontName
      Status           = "Success"
      MetricsExtracted = (Test-Path $metricsFilePath)
      WOFF2Size        = if ($woff2OutputPath -and (Test-Path $woff2OutputPath)) { (Get-Item $woff2OutputPath).Length / 1KB } else { 0 }
      # BrotliSize      = if ($woff2Compressed -and (Test-Path $woff2Compressed)) { (Get-Item $woff2Compressed).Length / 1KB } else { 0 }
      Features         = $featuresString
    }
  }
}

Write-Host "`n===============================================" -ForegroundColor Green
if ($operationMode -eq "1" -or $operationMode -eq "3") {
  Write-Host "All fonts processed successfully!" -ForegroundColor Green
  Write-Host "Font metrics generated only for regular fonts" -ForegroundColor Green
}
else {
  Write-Host "Font metrics extracted successfully!" -ForegroundColor Green
}
Write-Host "===============================================" -ForegroundColor Green

# Save summary
$summary | Format-Table -AutoSize | Out-File (Join-Path -Path $scriptDir -ChildPath "summary.txt")
Write-Host "Summary report saved to summary.txt" -ForegroundColor Green

# Clean up .br compressed files if they exist
$woff2BrFiles = Get-ChildItem -Path $scriptDir -Filter "*.woff2.br" -Recurse -File
if ($woff2BrFiles.Count -gt 0) {
  Write-Host "Cleaning up Brotli compressed files..." -ForegroundColor Gray
  foreach ($brFile in $woff2BrFiles) {
    Remove-Item -Path $brFile.FullName -Force
  }
}

# Clean up
Remove-Item $pythonExtractMetricsPath
Remove-Item $pythonParseFeaturesPath
Remove-Item $pythonBrotliCompressPath
"Finished processing - $(Get-Date)" | Out-File -FilePath $logPath -Append