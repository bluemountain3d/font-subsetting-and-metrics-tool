# Font Subsetting & Metrics Tool

A PowerShell script for subsetting fonts and extracting font metrics. This tool allows you to create smaller, optimized font files with only the characters you need while generating metrics useful for web and print design.

## Features

- **Font Subsetting**: Create optimized subsets of font files with only the characters needed for Western languages
- **WOFF2 Conversion**: Automatically convert subsetted fonts to the modern WOFF2 format for web use
- **Metrics Extraction**: Generate detailed font metrics including cap height, x-height, character width, and more
- **Multiple Output Formats**: Export metrics as JavaScript, JSON, CSS, or SCSS
- **OpenType Features Support**: Customize which OpenType features to include in your subsetted fonts
- **Batch Processing**: Process multiple font families at once with optional configuration file

## Prerequisites

- PowerShell 5.1 or later
- Python 3.6 or later
- Required Python packages (automatically installed if missing):
  - fontTools
  - brotli

## Directory Structure

```
subset-fonts/                            # Main folder
├── run-subset-script.bat               # Script launcher
├── subset-fonts-and-metrics-multi.ps1  # Main PowerShell script
├── fontName/                           # Folder for each font family
│   ├── original-font-file.{otf,ttf}    # Original font files
│   ├── features.json                   # (Optional) OpenType features configuration
│   ├── metrics/                        # Output folder for metrics
│   │   └── metrics.{js,json,scss,css}  # Generated metrics file
│   └── subsetted/                      # Output folder for subsetted fonts
│       ├── {otf,ttf}/                  # Subsetted fonts in original format
│       └── woff2/                      # Subsetted fonts in WOFF2 format
└── font_processing.log                 # Processing log file
```

## Usage

1. Create a directory for each font family under the main folder
2. Place original font files (.ttf or .otf) in their respective font family directories
3. Run the script:

   **Windows:**

   ```
   .\run-subset-script.bat
   ```

   or

   ```
   powershell -ExecutionPolicy Bypass -File subset-fonts-and-metrics-multi.ps1
   ```

   **macOS/Linux:**

   ```
   pwsh -File subset-fonts-and-metrics-multi.ps1
   ```

   > Note: macOS/Linux users will need to install PowerShell Core (pwsh) if not already installed.

## Operation Modes

The script offers three operation modes:

1. **Full Process** (default): Subset fonts and extract metrics
2. **Metrics Only**: Only extract metrics without subsetting fonts
3. **Batch Process**: Use a configuration file for automated processing

## Font Selection Methods

When running in either Full Process or Metrics Only mode, you can select fonts to process using one of three methods:

1. Process all fonts (with confirmation for each)
2. Enter a comma-separated list of font folder names
3. Process a single font folder (selected from a menu)

## Metrics Output Formats

Choose from four different output formats for font metrics:

1. **JavaScript**: For use with JavaScript applications
2. **JSON**: Structured data format
3. **CSS**: CSS @font-face rules
4. **SCSS Map**: For use with Sass/SCSS variables

## OpenType Features

The tool allows you to specify which OpenType features to include in your subsetted fonts. Common features include:

- `kern` - Kerning (improved letter spacing)
- `liga` - Standard Ligatures (combines character pairs like 'fi' into single glyphs)
- `dlig` - Discretionary Ligatures (decorative character combinations)
- `onum` - Oldstyle Figures (numbers that align with lowercase text)
- `lnum` - Lining Figures (numbers that align with uppercase letters)
- `pnum` - Proportional Figures (variable-width numbers for text)
- `tnum` - Tabular Figures (monospaced numbers for tables and alignment)
- `smcp` - Small Capitals (smaller versions of capital letters)
- `sups` - Superscripts (properly designed superscript characters)
- `subs` - Subscripts (properly designed subscript characters)
- `frac` - Fractions (properly formatted fraction glyphs)
- `case` - Case-Sensitive Forms (adjusted punctuation for all-caps text)

### Features Management

Features can be managed in three ways:

1. **Interactive Selection**: During font processing, the script will prompt you to choose features
2. **Saved in features.json**: Features can be saved to a `features.json` file in each font folder for reuse
3. **Config File**: Features can be specified in the batch processing config file

### features.json Format

The features.json file uses a simple format:

```json
{
  "openTypeFeatures": ["kern", "liga", "sups", "frac"]
}
```

### Using OpenType Features in CSS

After subsetting fonts with specific OpenType features, you can enable them in your CSS:

```css
/* Basic feature enabling */
body {
  font-kerning: normal; /* Enable kerning */
  font-feature-settings: "liga" 1; /* Enable standard ligatures */
}

/* Specific feature applications */
.fractions {
  font-feature-settings: "frac" 1; /* Enable proper fractions */
}

.table-numbers {
  font-feature-settings: "tnum" 1; /* Enable tabular figures */
}

.superscript {
  font-feature-settings: "sups" 1; /* Enable superscripts */
}
```

## Optimization Levels

Choose from three optimization levels for subsetting:

1. **Light** (default): Basic subsetting
2. **Medium**: Removes unused glyphs and desubroutinizes
3. **Aggressive**: Keeps only basic glyphs (A-Z, a-z, 0-9)

## Batch Processing with Config File

For automated processing, create a JSON configuration file:

```json
{
  "fontFolders": ["Roboto", "OpenSans", "Lato"],
  "features": "kern,liga,sups,onum",
  "unicodeRange": "U+0020-007F,U+00A0-00FF,U+0100-017F",
  "optimizationLevel": "2"
}
```

Then select operation mode 3 and specify the path to your config file.

### Configuration File Options

The config.json file supports the following settings:

- **fontFolders** (array): List of font directories to process
- **features** (string): Comma-separated list of OpenType features to include (or "all" or "none")
- **unicodeRange** (string): Unicode range specification for subsetting
- **optimizationLevel** (string): Subsetting optimization level ("1", "2", or "3")
- **metricsFormat** (string): Format for metrics output ("js", "json", "css", or "scss")

### Example Config Files

#### Minimal Web Configuration

```json
{
  "fontFolders": ["OpenSans", "Roboto"],
  "features": "kern,liga",
  "unicodeRange": "U+0020-007F,U+00A0-00FF",
  "optimizationLevel": "2",
  "metricsFormat": "js"
}
```

#### Full Multilingual Configuration

```json
{
  "fontFolders": ["Lato", "SourceSansPro", "NotoSans"],
  "features": "kern,liga,sups,frac,onum,tnum,case",
  "unicodeRange": "U+0020-007F,U+00A0-00FF,U+0100-017F,U+0180-024F,U+0250-02AF,U+0300-036F,U+0370-03FF,U+0400-04FF,U+1E00-1EFF,U+2000-206F",
  "optimizationLevel": "1",
  "metricsFormat": "scss"
}
```

## Example Metrics Output

### JavaScript Output

```javascript
'Roboto': (
  'font-family': '"Roboto"',
  'cap-height': 0.712,
  'x-height': 0.525,
  'd-height': 0.712,
  'ch-width': 0.551,
  'line-gap': 1.2,
  'ascender': 0.928,
  'descender': 0.072,
  'lsb-adjust': 0.049,
),
```

### SCSS Map Output

```scss
'roboto': (
  'font-family': 'Roboto',
  'cap-height': 0.712,
  'x-height': 0.525,
  'd-height': 0.712,
  'ch-width': 0.551,
  'line-gap': 1.2,
  'ascender': 0.928,
  'descender': 0.072,
  'lsb-adjust': 0.049
);
```

## Unicode Ranges

The script allows you to choose from several predefined Unicode ranges or specify your own custom range:

### Predefined Unicode Range Options

1. **Minimal Western** (~192 characters)

   - Basic Latin (`U+0020-007F`)
   - Latin-1 Supplement (`U+00A0-00FF`)
   - Best for: English and basic Western European text with minimal file size

2. **Standard Western European** (~320 characters)

   - Basic Latin + Latin-1 + Latin Extended-A (`U+0100-017F`)
   - Best for: Most Western European languages (French, Spanish, German, etc.)

3. **Comprehensive European (Latin)** (~1100 characters)

   - Latin coverage for all European languages
   - Includes diacritical marks and special characters
   - Best for: Full support for all Latin-script European languages

4. **Full European** (~1500 characters)

   - Complete European language support including Cyrillic and Greek
   - Best for: Multilingual European sites needing Eastern European, Russian, and Greek support

5. **Balanced Web Optimized** (~1060 characters)

   - Carefully selected range for web performance while maintaining good European language support
   - Includes essential typographic characters and symbols
   - Best for: Modern websites targeting European audiences with balanced file size and coverage

6. **Custom**

   - Enter your own Unicode ranges
   - Best for: Specialized needs or specific language targeting

7. **Custom Characters**
   - Enter specific characters to include (e.g., 'ABCabc123')
   - The script automatically converts these to their Unicode values
   - Best for: Creating minimal fonts with only the exact characters you need
   - Always includes space character (U+0020) automatically

### Character-Based Subsetting

The new character-based subsetting option (#7) allows you to specify exactly which characters should be included in your font subset:

1. Simply enter the specific characters you want to include, such as `ABCabc123!?@`
2. The script automatically converts these to their corresponding Unicode code points
3. Each character is only included once, even if you enter it multiple times
4. The space character is always included automatically for better text rendering
5. This creates ultra-optimized fonts that contain only the exact characters you need

Example usage:

```
Select Unicode range coverage:
1. Minimal Western
2. Standard Western European
3. Comprehensive European (Latin)
4. Full European
5. Balanced Web Optimized
6. Custom Unicode Range
7. Custom Characters
Enter your choice (1-7): 7
Enter specific characters to include (e.g., 'ABCabc123'): ABCDEFGabcdefg12345!?
Generated Unicode range: U+0020,U+0021,U+003F,U+0031,U+0032,U+0033,U+0034,U+0035,U+0041,U+0042,U+0043,U+0044,U+0045,U+0046,U+0047,U+0061,U+0062,U+0063,U+0064,U+0065,U+0066,U+0067
Characters included: ABCDEFGabcdefg12345!?
```

Benefits of character-based subsetting:

- **Smallest Possible File Size**: Only includes exactly what you need
- **Ideal for Icons/Limited Text**: Perfect for logo fonts, buttons, or displays with fixed text
- **Easy to Use**: No need to know Unicode ranges - just type the characters
- **Precise Control**: You know exactly which characters will be available

### Unicode Block Reference

When creating custom ranges, you may find these common Unicode blocks useful:

- **Basic Latin** (`U+0020-007F`): Standard ASCII characters
- **Latin-1 Supplement** (`U+00A0-00FF`): Western European characters and symbols
- **Latin Extended-A** (`U+0100-017F`): Additional European characters
- **Latin Extended-B** (`U+0180-024F`): More European and historic characters
- **Latin Extended Additional** (`U+1E00-1EFF`): Historic and specialized Latin characters
- **Greek and Coptic** (`U+0370-03FF`): Greek alphabet characters
- **Cyrillic** (`U+0400-04FF`): Characters for Russian, Bulgarian, Serbian, etc.
- **General Punctuation** (`U+2000-206F`): Various punctuation marks and spaces
- **Superscripts and Subscripts** (`U+2070-209F`): Superscript/subscript digits and symbols
- **Currency Symbols** (`U+20A0-20CF`): Various currency symbols (€, £, ¥, etc.)
- **Letterlike Symbols** (`U+2100-214F`): Specialized symbols like ℃, ™, ℗, etc.
- **Number Forms** (`U+2150-218F`): Fractions and other number notations

## Troubleshooting

- **Missing Python packages**: The script attempts to install required packages automatically
- **WOFF2 conversion failures**: The script will offer to retry failed conversions
- **Font parsing errors**: Check the `font_processing.log` file for details

## Font Metrics Information

The extracted metrics provide the following information:

- **font-family**: Font family name
- **cap-height**: Height of capital letters (relative to 1em)
- **x-height**: Height of lowercase letters (relative to 1em)
- **d-height**: Height of ascenders (relative to 1em)
- **ch-width**: Average character width (relative to 1em)
- **line-gap**: Recommended line-height multiplier
- **ascender**: Distance from baseline to top of the em-box (relative to 1em)
  - Normalized from font's hhea table: `(hhea.ascender - excess) / unitsPerEm`
  - Where `excess = (ascender + |descender| - unitsPerEm) / 2`
- **descender**: Distance from baseline to bottom of the em-box (relative to 1em)
  - Calculated as `1 - ascender` to ensure they sum to 1
- **lsb-adjust**: Left side bearing adjustment (relative to 1em)
  - Average left side bearing of specific uppercase letters (B, D, E, F, H, I, K, L, P, R)
  - Useful for text alignment and optical margin adjustments

### Understanding Left Side Bearing (LSB)

Left side bearing is a crucial typographic measurement that refers to the space between the left edge of a character's bounding box and the actual beginning of the glyph itself:

- **Definition**: The horizontal distance from the left edge of a character's em-box to the leftmost point of the glyph
- **Calculation**: In this tool, LSB is calculated by averaging the left side bearing of specific uppercase letters (B, D, E, F, H, I, K, L, P, R), then normalizing to the em-box
- **Why these letters?** These specific capital letters typically have vertical stems at their left side, making them ideal for consistent LSB measurement

#### Importance for Text Flow and Alignment

The LSB adjustment value is important for several reasons:

1. **Optical Alignment**: When text is aligned to the left margin, the varying shapes of letters can make the alignment appear uneven, even when mathematically aligned. LSB helps correct this.

2. **Hanging Punctuation**: Used to calculate how far punctuation marks should "hang" outside the margin for better visual alignment.

3. **Margin Compensation**: Different fonts have different natural left side bearings. This metric helps normalize them for consistent text flow.

4. **Typography Systems**: Design systems can use LSB metrics to create consistent optical margins across different fonts.

Example application in CSS:

```css
/* Using LSB for negative margin to create optical margin alignment */
.optically-aligned {
  margin-left: calc(var(--lsb-adjust) * -1em);
}
```

### Understanding Ascender and Descender

The ascender and descender values are normalized to ensure they sum to exactly 1em and represent proportional distances from the baseline. This normalization accounts for inconsistencies between different font files:

- **Original ascender**: Raw value from the font's hhea table
- **Original descender**: Raw value from the font's hhea table (typically negative)
- **Excess calculation**: `(ascender + |descender| - unitsPerEm) / 2`
  - This represents how much the original metrics exceed the em-box
- **Normalized ascender**: `(ascender - excess) / unitsPerEm`
- **Normalized descender**: `1 - normalized ascender`

This normalization process ensures consistent vertical metrics across different fonts, making them more reliable for layout calculations.

## Credits

This tool uses:

- [fontTools](https://github.com/fonttools/fonttools) for font manipulation
- [Brotli](https://github.com/google/brotli) for WOFF2 compression

## License

MIT
