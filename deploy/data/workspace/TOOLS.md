# Available CLI Tools

## gog — Gmail and Google Calendar

You have access to the `gog` CLI tool for Gmail and Google Calendar operations.
The account glen@getparsel.com is already authenticated.

IMPORTANT: Always run gog with these environment variables prefixed:
```bash
XDG_CONFIG_HOME=/data/config GOG_KEYRING_PASSWORD=$GOG_KEYRING_PASSWORD gog <command>
```

### Gmail

List/search emails (query is required):
```bash
XDG_CONFIG_HOME=/data/config GOG_KEYRING_PASSWORD=$GOG_KEYRING_PASSWORD gog gmail list "in:inbox"
XDG_CONFIG_HOME=/data/config GOG_KEYRING_PASSWORD=$GOG_KEYRING_PASSWORD gog gmail list "is:unread"
XDG_CONFIG_HOME=/data/config GOG_KEYRING_PASSWORD=$GOG_KEYRING_PASSWORD gog gmail list "from:someone@example.com newer_than:7d"
```

Read a specific email:
```bash
XDG_CONFIG_HOME=/data/config GOG_KEYRING_PASSWORD=$GOG_KEYRING_PASSWORD gog gmail get <message-id>
```

Send an email:
```bash
XDG_CONFIG_HOME=/data/config GOG_KEYRING_PASSWORD=$GOG_KEYRING_PASSWORD gog gmail send --to user@example.com --subject "Hello" --body "Message body"
```

### Google Calendar

List upcoming events:
```bash
XDG_CONFIG_HOME=/data/config GOG_KEYRING_PASSWORD=$GOG_KEYRING_PASSWORD gog calendar list
```

Get event details:
```bash
XDG_CONFIG_HOME=/data/config GOG_KEYRING_PASSWORD=$GOG_KEYRING_PASSWORD gog calendar get <event-id>
```

Create an event:
```bash
XDG_CONFIG_HOME=/data/config GOG_KEYRING_PASSWORD=$GOG_KEYRING_PASSWORD gog calendar create --title "Meeting" --start "2026-03-01T10:00:00" --end "2026-03-01T11:00:00"
```

Always use `gog` when the user asks about their email or calendar.

## mcporter — MCP Server Client

You have access to `mcporter` for calling MCP (Model Context Protocol) servers.
The Robin shipping API is already configured.

IMPORTANT: Always run mcporter from the `/data` directory:
```bash
cd /data && mcporter <command>
```

### Robin MCP Tools

Track a package by tracking code:
```bash
cd /data && mcporter call robin.track_by_tracking_code tracking_code="92612927005253000000000025" --output json
```

Get carrier tracking URL:
```bash
cd /data && mcporter call robin.get_carrier_tracking_url tracking_code="92612927005253000000000025" --output json
```

Get shipping label details:
```bash
cd /data && mcporter call robin.get_shipping_label shipping_label_id="lbl_abc123" --output json
```

List shipping labels:
```bash
cd /data && mcporter call robin.list_shipping_labels page=1 page_size=10 --output json
```

List all configured MCP servers:
```bash
cd /data && mcporter list
```

Use `mcporter` when investigating shipping, tracking, or label issues via Robin.

## web_search — Web Search

You have a built-in `web_search` tool for searching the web. Use it when you need current information, news, or to research topics. It uses Perplexity Sonar Pro via OpenRouter and returns synthesized answers with citations.

## web_fetch — Fetch Web Pages

You have a built-in `web_fetch` tool for fetching and reading web page content. Use it to retrieve information from specific URLs.
