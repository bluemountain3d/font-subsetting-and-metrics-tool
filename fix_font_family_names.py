from fontTools.ttLib import TTFont
import sys

def fix_font_family_names(input_path, output_path, family_name_override=None):
    """
    Corrects font family names in a font file to ensure consistency.
    
    Args:
        input_path: Path to the input font file
        output_path: Path to save the modified font file
        family_name_override: Optional override for the font family name
    """
    # Load the font
    font = TTFont(input_path)
    
    # Extract the current family name if no override provided
    if not family_name_override:
        # Try to get the preferred family name first (nameID 16)
        family_name = None
        for record in font['name'].names:
            # nameID 16 is the Preferred Family name
            if record.nameID == 16:
                if record.isUnicode():
                    family_name = record.toUnicode()
                    break
                else:
                    try:
                        family_name = record.string.decode('utf-8')
                        break
                    except:
                        try:
                            family_name = record.string.decode('latin-1')
                            break
                        except:
                            pass
                            
        # If preferred name not found, try standard family name (nameID 1)
        if not family_name:
            for record in font['name'].names:
                if record.nameID == 1:
                    if record.isUnicode():
                        family_name = record.toUnicode()
                        break
                    else:
                        try:
                            family_name = record.string.decode('utf-8')
                            break
                        except:
                            try:
                                family_name = record.string.decode('latin-1')
                                break
                            except:
                                pass
        
        # Clean up the family name by removing weight indicators
        if family_name:
            # Try to extract base family name by removing weight indicators
            for weight in ['Regular', 'Bold', 'Italic', 'Medium', 'Light', 'Black', 'SemiBold', 'ExtraBold', 'ExtraLight', 'Thin']:
                if weight in family_name:
                    # Only remove the weight if it appears as a separate word or with a hyphen/space
                    family_name = family_name.replace(' ' + weight, '').replace('-' + weight, '')
                    family_name = family_name.strip()
    else:
        # Use the provided override
        family_name = family_name_override
    
    # If we found a family name or have an override, update all relevant name table entries
    if family_name:
        for nameID in [1, 16]:  # Family name (1) and Preferred Family name (16)
            for record in font['name'].names:
                if record.nameID == nameID:
                    if record.isUnicode():
                        font['name'].setName(family_name, record.nameID, record.platformID, record.platEncID, record.langID)
                    else:
                        try:
                            encoded_name = family_name.encode(record.getEncoding())
                            font['name'].setName(encoded_name, record.nameID, record.platformID, record.platEncID, record.langID)
                        except:
                            # If encoding fails, skip this record
                            pass
    
    # Save the modified font
    font.save(output_path)
    return family_name

if __name__ == "__main__":
    # Handle command-line arguments
    if len(sys.argv) < 3:
        print("Usage: python fix_font_family_names.py <input_font> <output_font> [family_name_override]")
        sys.exit(1)
        
    input_path = sys.argv[1]
    output_path = sys.argv[2]
    family_name_override = sys.argv[3] if len(sys.argv) > 3 else None
    
    try:
        family_name = fix_font_family_names(input_path, output_path, family_name_override)
        print(f"SUCCESS:{family_name}")
    except Exception as e:
        print(f"ERROR:{str(e)}")
        sys.exit(1)