# MOVE Platform

The industry platform for Australia's Out-of-Home advertising, connecting media buyers and site owners.

Out-of-Home advertising in Australia is fragmented. Billboards, transit ads, and street furniture are owned by different companies across thousands of locations. Media buyers planning a campaign had no unified way to see what inventory existed, where it was, or who owned it. They negotiated with each owner separately, often working from spreadsheets and PDF rate cards.

MOVE is the industry association's answer to this. It's a shared platform where competitors collaborate on infrastructure that benefits everyone. Owners list their sites. Buyers plan campaigns geographically. The platform handles the complexity of mapping, measurement, and reporting that no single company could justify building alone.

I was part of the team that built MOVE 2.0, a ground-up rebuild of the platform.

---

## Two sides of the marketplace

The platform serves two distinct user types with different needs.

Media owners upload their inventory. Each site has location data, environment classification (roadside, retail, transit), and technical specs. Owners create packages by selecting sites, setting availability windows, and defining pricing. They can share packages with specific buyers or post them publicly.

Media buyers plan campaigns by geography. The map shows every registered site in Australia, clustered at low zoom and individual at high zoom. Buyers select markets, filter by environment type, and build campaigns from the packages owners have made available. A campaign might include sites from multiple owners across different cities.

The organisation model handles this cleanly. Each company is an organisation with users and roles. Organisations can be buyers, owners, or both. Packages and campaigns belong to organisations, and permissions control who can create, edit, or view them.

---

## Geographic planning

The map is central to how both sides work. It's built on Mapbox with custom tilesets for Australian markets and demographic regions.

Sites appear as clustered points that expand as you zoom. The clustering uses Mapbox's built-in algorithms but aggregates by environment type so clusters show the mix of roadside, retail, and transit sites they contain. Clicking a cluster zooms to show individual sites. Clicking a site shows details and lets buyers add it to a campaign or owners manage its availability.

Market regions overlay the map as coloured polygons. A buyer planning a Sydney campaign can select the Sydney market and see all sites within it highlighted. The same market boundaries drive reporting, so reach and frequency metrics align with how media is actually bought.

---

## Measurement and reporting

The platform generates reports that estimate campaign reach and frequency. This is where the shared infrastructure really matters. The underlying measurement methodology is agreed across the industry, so a reach number from MOVE means the same thing regardless of which owners' sites are included.

Reports run asynchronously. A buyer submits a campaign with selected packages, target demographics, and date ranges. The system queues the report, processes it against the measurement dataset, and notifies the user when results are ready. Large campaigns with many sites can take time to process, so the queue shows position and estimated completion.

Report data includes reach by market, frequency distribution, and demographic breakdowns. Buyers can export results to share with clients or compare across campaign options.

---

## Sharing and collaboration

Packages and campaigns flow between organisations through explicit sharing. An owner creates a package and shares it with a specific buyer. The buyer sees the package in their proposals view and can add it to a campaign. Changes to the package propagate to anyone it's been shared with.

This creates a lightweight proposal workflow. Owners package sites in response to a brief, share with the buyer, and iterate based on feedback. The buyer compares proposals from multiple owners, builds a campaign from the best options, and generates reports to validate reach targets.

---

## Technical architecture

The frontend is Next.js with server-side rendering. The backend is .NET with Entity Framework for basic data access and Dapper for complex queries. PostgreSQL runs on Aurora Serverless.

Infrastructure is Terraform on AWS. ECS runs the API and web containers. CloudFront handles CDN and image transformation. The map tilesets live in Mapbox's infrastructure and get updated through their API when site data changes.

Database migrations use graphile-migrate with a committed/current split. This keeps migrations reviewable while allowing iterative development on the current schema.

