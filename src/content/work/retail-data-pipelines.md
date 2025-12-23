# Retail Data Pipelines

Transformation systems that convert raw product catalogues into state-specific marketing assets.

Australian retailers run promotions across multiple jurisdictions, each with different pricing regulations and compliance requirements. A national liquor retailer might have different prices in Victoria versus Queensland, different promotional mechanics allowed in each state, and different legal copy that must appear. Creating marketing materials meant manually producing variants for each jurisdiction, a slow process that invited errors.

I built transformation pipelines that take a single source spreadsheet and generate all the state-specific variants automatically. Marketing teams define products, pricing, and promotions in a format they already understand. The system handles jurisdiction logic, compliance text, and layout selection.

---

## Jurisdiction mapping

The core complexity is mapping business rules to states. A product might be "national except Victoria and Tasmania" or "Queensland and Northern NSW only." Pricing columns in the source data are prefixed by state, so a single product row might have VIC, NSW, QLD, WA, SA, and TAS prices that all differ.

The transformation layer interprets these rules and produces separate output for each jurisdiction. A "Nat ex VIC TAS" product appears in the Queensland output but not the Victorian output. State-specific pricing gets pulled from the correct column. Products that aren't available in a jurisdiction simply don't appear in that jurisdiction's output.

This means marketing teams work from a single master spreadsheet. They don't maintain six separate documents that drift out of sync. They define the rules once and the system applies them consistently.

---

## Pricing mechanics

Retail promotions use varied pricing structures. Single items, multi-buy deals, pack pricing, case pricing, member-only pricing. Each mechanic displays differently and requires different data.

The transformation logic inspects the pricing data to determine how to present it. A price like "2 for 40.00" triggers multi-buy display logic. A pack size above a threshold switches from "pack" to "case" labelling. Member pricing shows the non-member price alongside the member price. The system parses pricing strings, extracts the numeric values, and routes each product to the appropriate display template.

Some pricing rules interact with jurisdiction. A state might not allow certain promotional mechanics, or might require specific disclaimer text. The pipeline handles these conditions by checking both the pricing data and the jurisdiction when determining output.

---

## Product parsing

Source data often contains denormalized product information. A single cell might hold "Brand Name Product 4x330ml Cans" and the system needs to extract brand, product name, pack configuration, and container type as separate values.

The parsers use pattern matching to pull apart these compound strings. Volume patterns like "750ml" or "4x330ml" get extracted and normalised. Container types like "cans" or "bottles" affect which layout template gets used. The parsing handles common inconsistencies in how source data is formatted.

Product images come from a CDN keyed by SKU. The transformation looks up each SKU and constructs the appropriate image URL, including any transforms needed for the layout like background removal or resizing.

---

## Output format

The pipelines output structured data that drives design tools. Each output record specifies a template, a set of field values, and a name for the generated asset. The design tool reads this data and produces the final artwork.

This separation means the transformation logic doesn't need to know about design tool internals. It produces a clean data structure. The design tooling consumes that structure. Changes to templates don't require changes to the transformation code, and vice versa.

---

## Scope

Each pipeline is specific to a client and asset type. A catalogue pipeline handles the particular layout rules and data format for that client's catalogues. An email pipeline handles different rules for email modules. The underlying patterns are similar, but the specific field mappings and business logic vary.

The work spans several retail clients across liquor, department stores, and specialty retail. Each has their own source data format, their own jurisdiction rules, and their own output requirements. The pipelines encode all of this in executable form so that what used to take days of manual production now takes minutes.

