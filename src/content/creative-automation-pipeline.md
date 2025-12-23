# Creative Automation Pipeline

Plugins for Figma and InDesign that generate design variants from templates and spreadsheets.

Design teams create templates. Marketing teams need hundreds of variations with different products, copy, and layouts for different markets and channels. The gap between them is usually filled with tedious manual work, or expensive production teams doing the same task over and over.

We built plugins that connect directly to asset libraries, read configuration from spreadsheets, and generate production-ready outputs automatically. A single template can produce hundreds of localised, personalised variants without a designer touching each one.

---

## Layer naming as configuration

The key insight is that layer names can encode instructions. A layer named `[text: headline]` becomes a text replacement target. `[image: product]` becomes an image slot. The template itself defines what can change.

Designers work in their normal tools without learning a new interface. They name their layers according to a simple convention, and those names tell the plugin what to replace. The spreadsheet columns match the layer names, so each row becomes a variant with different content in each slot.

This keeps the complexity where it belongs. Designers control the visual structure. Spreadsheet authors control the content. The plugin just connects them.

---

## Spreadsheet driven

The input format is a spreadsheet because that's what marketing teams already use. Each row is a variant. Columns map to layer names. Special prefixes like `text:`, `image:`, `component:`, and `visibility:` control what operation gets applied.

The same spreadsheet can drive both plugins. Figma for digital banners. InDesign for print catalogues. Different outputs, same source of truth.

---

## Output formats

The Figma plugin exports to multiple formats depending on the channel. Static images for display ads. Google Web Designer projects for animated banners with proper timeline and interaction support. The InDesign plugin outputs print-ready documents with correct colour profiles and bleed.

Production teams used to spend days generating these variants manually. Now the same work takes minutes, and the results are consistent because they all come from the same template.
