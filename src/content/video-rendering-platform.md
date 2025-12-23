# Distributed Video Rendering Platform

A system for generating personalised marketing videos at scale from After Effects templates.

Agencies produce hundreds of video variants per campaign, each with different text, images, and layer configurations. The manual process is slow and error-prone. Cloud rendering services exist but cost too much at volume.

I built internal tooling to automate the workflow. Users upload an After Effects template, define variants in a spreadsheet, and the system renders them across available machines. An API handles job queuing and storage. Render nodes running on local hardware poll for work, process templates through After Effects, and upload results.

The fewer things that need to know about each other, the fewer things that can break. So I designed each component to be as ignorant as possible:

- The API has no idea which render nodes exist or where they are.
- Nodes pull work from a queue without knowing about each other.
- Files go straight to storage without touching the API.
- Users configure everything from a spreadsheet they already know how to use.

---

## Polling for jobs

The architecture uses pull-based distribution. Render nodes poll a job queue rather than receiving pushed work.

Push-based systems need nodes to be addressable. That means public IPs, or webhook endpoints, or tunneling services, plus authentication and retry logic on the sender side. Pull inverts this. Nodes reach out when they're ready for work. They can sit behind NAT, run on a laptop, or spin up in a different network entirely. The API doesn't need to know anything about them.

Scaling becomes trivial. Adding capacity means starting another node and pointing it at the queue. No registration, no discovery, no config changes. The API remains ignorant of how many nodes exist or where they are.

The tradeoff is latency. Jobs wait in the queue until a node polls. I used exponential backoff when the queue is empty to balance responsiveness against API costs, but there's inherent delay compared to a push model. For renders that take 10+ minutes, a few seconds of queue latency doesn't matter.

---

## File uploads

The same principle applies to file handling. The API shouldn't be moving bytes around if it doesn't have to.

Template files go directly to object storage rather than through the API. The API returns a presigned upload URL, the client uploads directly, then notifies the API on completion. Routing files through your API means you pay for the compute, you're bound by request size limits, and you're adding latency. Presigned URLs let clients talk directly to storage infrastructure built for this purpose.

The same pattern works for downloads. Render nodes fetch templates via presigned URLs rather than through the API. Large files with linked assets get bundled into zip archives, downloaded once, and cached locally.

---

## Spreadsheet configuration

Non-technical users configure video generation through spreadsheets. Each row is a video and each column maps to an After Effects operation via a header syntax. A header like `text.Main Comp.Title Card.Headline` means "replace the text in the Headline layer, which is inside Title Card, which is inside Main Comp." The path syntax handles nested compositions without users needing to understand After Effects project structure. Other operations cover image replacement, visibility, colours, and transforms.

I considered JSON config files or a web UI. Spreadsheets won because they're the native tool for this kind of tabular data. Users already think in rows and columns when planning campaign variants. Meeting them there, rather than forcing a new interface, reduced onboarding to almost nothing.

---

## Handling failures

Video renders take 5 to 30 minutes or more. Machines crash, networks drop, processes hang. The system assumes failures will happen and treats them as routine rather than exceptional.

Each job has a visibility timeout. If a node crashes or disconnects, the job returns to the queue after the timeout expires. Long-running renders send heartbeat updates to extend their lease. Graceful shutdown catches termination signals and re-queues in-progress work.

This is standard queue semantics, but it matters for long jobs. A 20-minute render failing at minute 19 and silently disappearing would be a bad experience. Jobs either complete successfully or fail with a logged error. Nothing gets lost.
