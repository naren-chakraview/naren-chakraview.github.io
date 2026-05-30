# Chakraview Brand Guidelines

## Color Palette

### Primary Colors
- **Primary Blue**: `#0052CC` — Used for primary CTAs, links, and core UI elements
- **Primary Accent**: `#6E40C9` — Used for highlights and emphasis
- **Neutral Dark**: `#1F2937` — Text and foreground elements
- **Neutral Light**: `#F3F4F6` — Backgrounds and low-contrast elements

### Secondary Colors
- **Success**: `#10B981` — For positive actions, confirmations, passing tests
- **Warning**: `#F59E0B` — For alerts and cautions
- **Error**: `#EF4444` — For errors and failures

## Typography

### Font Family
- **Headers**: Inter, system sans-serif
- **Body**: Inter, system sans-serif

### Font Scales
```
h1: 48px (3rem) - Page titles
h2: 36px (2.25rem) - Section headings
h3: 28px (1.75rem) - Subsections
h4: 24px (1.5rem) - Minor headings
body: 16px (1rem) - Regular text
small: 14px (0.875rem) - Captions, metadata
```

## Logo Usage

### Primary Logo
- Full color logo with wordmark (preferred for light backgrounds)
- Minimum size: 120px width
- Clear space: 20px around all sides

### Lockup Variations
- Logo + text (full branding)
- Logo only (icon version for favicons)
- Text only (when space is limited)

### Do Not
- Distort or stretch the logo
- Rotate beyond 0° or 90° angles
- Apply filters or effects
- Change colors (except for approved grayscale/white versions)

## Design Principles

### Clarity
Documentation should be scannable and clear. Use hierarchy, whitespace, and visual breaks.

### Consistency
All portfolio projects follow the same structural patterns, naming conventions, and visual language.

### Accessibility
- Minimum contrast ratio: 4.5:1 for body text
- All images have descriptive alt text
- Icons are paired with text labels
- Color is never the only indicator of status

### Performance
- Optimize all images (use WebP where supported)
- Lazy-load images below the fold
- Minimize CSS and JavaScript
- Target Lighthouse score: 90+

## Asset Locations

All branding assets are stored in `/assets/branding/` for centralized management.

Project-specific assets (favicons, logos) can be stored locally in each project's `/assets/` directory if needed.

## Version Control

Document all changes to branding guidelines in git commit messages:

```bash
git commit -m "docs: update brand guidelines - adjust primary blue color

Changed primary blue from #003A99 to #0052CC for better WCAG AA compliance
across light backgrounds. Updated all mkdocs themes accordingly."
```
