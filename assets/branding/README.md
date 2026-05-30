# Branding Assets

Centralized branding and design assets for the Chakraview portfolio.

## Directory Structure

```
branding/
├── README.md           # This file
├── logos/              # Project and organization logos
├── favicons/           # Favicon assets
├── fonts/              # Web fonts and typography
└── guidelines.md       # Brand guidelines
```

## Purpose

This directory consolidates shared branding assets used across all portfolio documentation sites, ensuring visual consistency while reducing duplication.

## Asset Types

### Logos
- Organization logo (Chakraview)
- Project-specific logos (if unique)
- Icon sets for documentation

### Favicons
- Primary favicon (org-wide)
- Project-specific favicons (optional)

### Fonts
- Web font definitions
- Typography scales
- Font pairing recommendations

## Usage

Reference these assets in mkdocs.yml or HTML:

```yaml
# mkdocs.yml
theme:
  logo: https://naren-chakraview.github.io/assets/branding/logos/chakraview.svg
  favicon: https://naren-chakraview.github.io/assets/branding/favicons/favicon.png
```

## Maintenance

When updating branding assets:
1. Update source files in the appropriate subdirectory
2. Test across all portfolio projects
3. Document changes in the git commit message

## Guidelines

See `guidelines.md` for:
- Color palette
- Typography standards
- Logo usage rules
- Design system principles
