# Enterprise DAM Architecture

Solution architecture for a unified digital asset management platform serving a multi-brand retail group.

A retail group operating several major brands needed to consolidate their creative assets. Each brand had grown its own ecosystem: Google Drive, Dropbox, personal folders, Airtable boards, email threads, and various transfer services. Assets were duplicated, naming was inconsistent, and finding the right version of something meant knowing which system to look in and which folder structure to navigate. Regulatory compliance was particularly painful. Industry-specific advertising rules required sign-off before assets could go live, but the approval status lived in spreadsheets and email chains rather than on the assets themselves.

I led the solution architecture for an Adobe Experience Manager implementation. The work was design only. I produced a technical solution design covering taxonomy, metadata, workflows, integrations, and governance. The client's internal team handled implementation.

---

## The core shift

The fundamental change was moving from folder-based navigation to metadata-driven search. In the old model, finding an asset meant knowing where someone had filed it. Campaign photography might be in a campaign folder, or a brand folder, or a project folder, depending on who uploaded it and when. The new model attaches structured metadata at the point of upload, so assets become findable by what they are rather than where they sit.

This sounds obvious, but making it work across multiple brands with different workflows required careful design. One brand needs detailed product attributes. Another needs location codes and regional targeting. A campaign team needs job numbers and talent names. Forcing everyone into the same form would mean either missing critical data or overwhelming users with irrelevant fields.

---

## Conditional schemas

The solution uses a single master metadata schema with conditional visibility. The form adapts based on what kind of asset you're uploading. Select "Product Shot" and you see fields for SKU and product attributes. Select "Campaign Banner" and you see campaign name, job ID, and talent. The underlying schema is unified, which keeps search and reporting consistent, but users only see what's relevant to their work.

The same principle applies to compliance. Assets tagged for regulated categories automatically surface additional fields for approval status. Compliance officers can set states that other users can view but not edit. The data travels with the asset rather than living in a separate tracking system.

---

## Tag derivation

Tags and metadata overlap conceptually, which creates a risk of drift. If someone enters a product category in a metadata field but forgets to add the corresponding tag, search becomes unreliable.

The design establishes clear source-of-truth rules. For concepts that exist as metadata fields, tags are derived automatically on save. Enter a category and the system generates the tag. This eliminates double-entry and keeps faceted search in sync with the underlying data. Tags without a metadata equivalent, like distribution channel or usage restrictions, remain manually applied.

---

## External access

The platform needed to support external users without giving them access to internal work-in-progress. Suppliers upload product photography. Agencies deliver campaign assets. Store managers download marketing kits. None of these groups should see each other's content or browse internal folders.

The design uses Adobe Brand Portal as the external interface. Suppliers upload to isolated contribution folders that sync to a quarantine area in the main DAM. Assets go through automated processing and custodian review before appearing in the live taxonomy. Distribution works through collections rather than folder shares, so assets can appear in multiple kits without duplication. Store managers see a single collection for their location that automatically shows current content based on validity dates.

The distribution model uses Smart Collections with date-based filtering. Marketing sets "valid from" and "valid to" dates when uploading a kit. Assets automatically appear in relevant store collections when they become valid and drop out when they expire. No manual collection management required for the monthly changeover.

---

## Compliance workflows

Advertising in this industry requires pre-approval from regulatory bodies. Rules also vary by region. Both needed to be enforced at the asset level rather than relying on manual checks.

The design routes assets to compliance review based on their metadata. An asset tagged for a regulated category triggers the appropriate workflow. Regional targeting triggers region-specific compliance checks. Officers review and set approval status. The asset can't reach "approved" state until all relevant compliance gates have cleared.

Certificates link to assets via a related-asset field. One certificate might cover an entire campaign, so the same document references from every format variation. When a certificate approaches expiry, the system propagates warnings to all linked assets.

---

## Integration points

The platform sits at the centre of a larger ecosystem. Adobe Workfront manages campaign briefs and creative review. A product information system holds SKU data. Other platforms need images linked to specific inventory. Email marketing pulls images via API.

The design specifies bidirectional sync with Workfront so campaign metadata flows into the DAM without manual entry. Product data syncs on a schedule to pre-populate fields and validate SKU entries. Inventory integration is more complex: staff photograph products and drop files to an SFTP server, scripts extract identifiers from filenames, and the system looks up product data to enrich the asset record.

---

## Scope

This was a design engagement. The deliverable was a technical solution design document covering:

- Folder taxonomy and naming conventions
- Metadata schemas with conditional visibility rules
- Tagging strategy and derivation logic
- Search configuration and weighting
- Workflow definitions for approval, compliance, and distribution
- Integration architecture for external systems
- Access control and permission matrices
- Brand Portal configuration for external collaboration
- Rendition strategy for multi-channel delivery

The client's team took the design through implementation. I wasn't involved in the build phase, so I can't speak to what changed between design and delivery.

