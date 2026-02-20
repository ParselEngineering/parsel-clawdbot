---
name: robin
description: Query Robin's shipping tracking and label management API via MCP (mcporter)
metadata: {"openclaw": {"emoji": "🐦", "requires": {"bins": ["mcporter"]}}}
---

# Robin MCP — Shipping & Tracking Tools

You have access to Robin's shipping platform via mcporter. All commands must be run from the `/data` directory so mcporter finds its config.

## Available Tools

| Tool | Description |
|------|-------------|
| `track_by_tracking_code` | Track a package by its carrier tracking code — returns normalized tracking events |
| `track_shipping_label` | Track by Robin shipping label ID — returns tracking events |
| `get_shipping_label` | Get shipping label details by ID |
| `get_carrier_tracking_url` | Get the carrier-specific tracking page URL for a tracking code |
| `get_shipment` | Get shipment details by ID |
| `list_shipments` | List shipments with pagination |
| `list_shipping_labels` | List shipping labels with pagination |

## Usage

Always prefix commands with `cd /data &&` so mcporter finds its config:

### Track a package by tracking code
```bash
cd /data && mcporter call robin.track_by_tracking_code tracking_code="92612927005253000000000025"
```

### Get carrier tracking URL
```bash
cd /data && mcporter call robin.get_carrier_tracking_url tracking_code="92612927005253000000000025"
```

### Track by shipping label ID
```bash
cd /data && mcporter call robin.track_shipping_label shipping_label_id="lbl_abc123"
```

### Get shipping label details
```bash
cd /data && mcporter call robin.get_shipping_label shipping_label_id="lbl_abc123"
```

### Get shipment details
```bash
cd /data && mcporter call robin.get_shipment shipment_id="shp_abc123"
```

### List shipping labels (paginated)
```bash
cd /data && mcporter call robin.list_shipping_labels page=1 page_size=10
```

### List shipments (paginated)
```bash
cd /data && mcporter call robin.list_shipments page=1 page_size=10
```

## Tracking Event Schema

Each tracking event returned by `track_by_tracking_code` contains:
- `status`: PRE_TRANSIT | IN_TRANSIT | OUT_FOR_DELIVERY | DELIVERED | RETURN_TO_SENDER | FAILURE | ERROR | VOIDED
- `substatus`: address_issue | access_issue | failed_delivery | lost_damaged_or_refused | delayed
- `message`: Human-readable event description
- `tracking_location`: { city, state, country, zip }
- `created_at`: ISO timestamp

## Tips

- Use `--output json` for machine-readable results: `cd /data && mcporter call robin.track_by_tracking_code tracking_code="..." --output json`
- Pagination defaults: page=1, page_size=20
- Prefer `track_by_tracking_code` for customer-facing tracking lookups
- Use `get_carrier_tracking_url` to generate a link the customer can click
