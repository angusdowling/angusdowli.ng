# Content Intelligence

A platform for extracting product data from retail catalogue PDFs and generating copy with AI.

Retail brands produce seasonal catalogues as CAD sheets. These are layout PDFs showing product images alongside minimal text like SKU, product name, colour, and price. No descriptions, no marketing copy. Just enough information to identify each product. Getting images and metadata out of these PDFs manually means hours of cutting and transcribing.

I built a platform that extracts this data automatically, then uses AI to generate full product descriptions from the images. Users configure brand voice, tone, and style requirements. The system looks at each product image alongside its metadata and writes copy that matches what it sees.

---

## Colour conversion

Catalogue PDFs use CMYK colour spaces because they're designed for print. Extract the images naively and you get muddy, shifted colours that don't match the original.

Most PDF libraries let you pull out raw image data, but they leave colour conversion to you. The problem is that CMYK to RGB conversion depends on the colour profile embedded in the PDF, and getting it wrong produces noticeable differences. Blues shift purple, reds turn orange.

I used PyMuPDF's native conversion instead of doing the maths myself. It reads the embedded profile and handles the conversion correctly. The output images match what you see when you open the PDF in a viewer.

---

## Matching images to text

A product image on its own isn't useful without knowing what product it is. The SKU, name, and price sit somewhere nearby on the page, but "nearby" varies between catalogues and even between pages.

I tried a few approaches. Using an LLM to identify products looked promising, but SKUs need to be exact. A single wrong character means the wrong product, and OCR kept confusing 0's with O's and 5's with S's. We needed to read text directly from the PDF rather than interpreting rendered pixels.

_Note: There are definitely ways around this with OCR, but time on this job was finite and a code based solution guaranteed determinism._

Bounding box overlap didn't work because text rarely overlaps with images. Nearest-neighbour matching seemed obvious but broke down in grid layouts. When products sit in rows, the nearest text to one image might actually belong to its neighbour. And variant images that should share the same description would each grab their own nearest block instead.

What worked was zone-based assignment. For each image, I create a zone extending downward and slightly to the sides. Characters that fall within the zone get grouped into text blocks, and those blocks get matched to the image. Images that overlap spatially get grouped together first, so variant grids share whatever text falls in their combined zone.

---

## Extraction order

PDFs don't store images in visual order. The internal structure is optimised for rendering, not for sequential access. Pull images out in storage order and you get a jumbled mess that doesn't correspond to how products appear on the page.

The fix was matching object references between two different PDF libraries. I use pdfplumber to get image positions in visual order, then look up each image's internal reference ID to extract it with PyMuPDF. This gives me correct ordering with correct colours.

---

## Copy generation

CAD sheets don't include product descriptions. They have just enough text to identify each item. But ecommerce platforms and marketing channels need actual copy.

Users configure a project with brand context, target audience, tone, style format, and specific requirements like dos and don'ts. The system then generates descriptions for each product by looking at the extracted image combined with its metadata. A striped vest gets different copy than a floral dress because the AI can see what it's describing.

The interface lets users iterate on individual products. If a generated description misses something, you type feedback like "add more on the fabric being linen and good for summer" and regenerate. The conversation history carries forward, so each revision builds on the last rather than starting fresh.

This turns a one-time extraction into an ongoing content workflow. The same catalogue of images can produce copy for product pages, social posts, email campaigns, and ads, each with different tone and format requirements.

---

## Output

The processor outputs extracted images matched to their metadata. Users review products, generate and refine copy, then export to spreadsheet. The spreadsheet maps each SKU to its generated description and image filename, ready for import into ecommerce platforms or asset management systems.

