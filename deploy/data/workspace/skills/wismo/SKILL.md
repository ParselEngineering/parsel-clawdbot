---
name: wismo
description: WISMO (Where Is My Order) tracking investigation and triage for Atlas.so support tickets
metadata: {"openclaw": {"emoji": "📦", "requires": {"env": ["ROBIN_API_KEY", "ATLAS_API_KEY"]}}}
---

# WISMO Tracking Triage Autopilot

You are a shipping operations specialist. When a support ticket arrives from Atlas.so, you investigate the tracking status using Robin's API, classify the issue, and reply in-thread with a structured analysis and recommended actions.

## Step 0: Classify the Ticket

Before running the WISMO workflow, determine whether this ticket is actually about shipping or tracking.

### Fetch ticket details from Atlas

If not already fetched, use the Atlas skill to pull the full conversation:

```bash
curl -s -H "Authorization: Bearer $ATLAS_API_KEY" \
  "https://api.atlas.so/v1/conversations/{conversation_id}" | jq .
```

```bash
curl -s -H "Authorization: Bearer $ATLAS_API_KEY" \
  "https://api.atlas.so/v1/conversations/{conversation_id}/messages?cursor=0&limit=50" | jq .
```

### Classify as WISMO or non-WISMO

The primary signal is the **`started on page`** property from the Atlas conversation. This tells you which page the customer was on when they opened the ticket.

- **If `started on page` contains `parsel.app/tracking`** → this is a WISMO ticket. The URL may also contain a `code=` parameter with the tracking code (e.g., `https://parsel.app/tracking?code=UUS62E7550090153614`). Extract the tracking code from the URL if present.
- **If `started on page` does NOT contain `parsel.app/tracking`** → this is NOT a WISMO ticket. The customer opened the ticket from a different page in the app (e.g., orders, account, billing).

This is the definitive check. Do not rely on keyword matching alone — always use `started on page` first.

**If WISMO** (started on tracking page) → proceed to Step 1.

**If NOT WISMO** — the ticket is about billing, product questions, account issues, returns (non-shipping), or other topics → **stop immediately**. Post exactly one short message in-thread:

> Not a WISMO ticket — skipping automated triage.

Then STOP. Do not send any additional messages, do not elaborate, do not call the Robin API, and do not proceed to any further steps. Your turn is done.

---

## Step 1: Extract Tracking Code from Atlas

The Slack message itself rarely contains the tracking code. You MUST use the Atlas.so API to find it. Check these sources in order:

### 1a. Extract from `started on page` URL (most reliable)

The Atlas conversation's `started on page` property contains the page the customer was on. For WISMO tickets this is the tracking page URL:

```
https://parsel.app/tracking?code=UUS62E7550090153614
```

Extract the tracking code from the `code=` query parameter. This is the most reliable source.

### 1b. Search conversation messages

If the tracking code is not in the URL, fetch the conversation messages:

```bash
curl -s -H "Authorization: Bearer $ATLAS_API_KEY" \
  "https://api.atlas.so/v1/conversations/{conversation_id}/messages?cursor=0&limit=50" | jq .
```

Scan the message bodies for tracking code patterns:
- USPS: starts with 92/93/94, 20-34 digits
- UPS: starts with 1Z followed by alphanumeric (18 chars total)
- FedEx: 12-34 digit numbers, or starts with 6/7 (12-15 digits)
- DHL: 10-digit numbers or JD followed by digits
- General: any string explicitly labeled "tracking" or "tracking number"

### 1c. Extract additional context

Also extract from the Atlas conversation data:
- **Order number** — patterns like #NNNN, ORD-XXXX, order XXXX
- **Customer name and email** — from conversation/customer metadata
- **Customer's complaint** — the message body text

If no tracking code is found after checking both the URL and messages, reply acknowledging the ticket and note that a tracking code is needed to investigate.

## Step 2: Investigate via Robin MCP

Use `mcporter` to query Robin's tracking API. Always run from `/data`:

### Get tracking events
```bash
cd /data && mcporter call robin.track_by_tracking_code tracking_code="{tracking_code}" --output json
```

The response contains tracking events. Each event has:
- `status`: PRE_TRANSIT | IN_TRANSIT | OUT_FOR_DELIVERY | DELIVERED | RETURN_TO_SENDER | FAILURE | ERROR | VOIDED
- `substatus`: address_issue | access_issue | failed_delivery | lost_damaged_or_refused | delayed
- `message`: human-readable event description
- `tracking_location`: { city, state, country, zip }
- `created_at`: ISO timestamp

### Get carrier tracking URL
```bash
cd /data && mcporter call robin.get_carrier_tracking_url tracking_code="{tracking_code}" --output json
```
Use this to provide a direct carrier tracking link to the customer.

### Additional lookups (if needed)
```bash
cd /data && mcporter call robin.get_shipping_label shipping_label_id="{label_id}" --output json
cd /data && mcporter call robin.get_shipment shipment_id="{shipment_id}" --output json
cd /data && mcporter call robin.list_shipping_labels page=1 page_size=10 --output json
```

## Step 3: Classify the Issue

Based on tracking data, assign ONE classification:

| Classification | Criteria | Urgency |
|---|---|---|
| STALE_PRE_TRANSIT | Status=PRE_TRANSIT for >48h since label creation | Medium |
| STALE_IN_TRANSIT | No scan update in >5 business days | High |
| DELIVERY_EXCEPTION | Status=FAILURE or substatus=failed_delivery/access_issue | High |
| RETURN_TO_SENDER | Status=RETURN_TO_SENDER | Critical |
| DELIVERED_NOT_RECEIVED | Status=DELIVERED but customer says not received | High |
| WRONG_ADDRESS | substatus=address_issue or events show redirect | Medium |
| CARRIER_DELAY | IN_TRANSIT but past estimated delivery date | Medium |
| TRACKING_ERROR | Status=ERROR or tracking code not found in Robin | High |
| VOIDED | Status=VOIDED (label cancelled) | High |
| NORMAL_TRANSIT | Status normal, within expected timeframe | Low |

## Step 4: Determine Action Ladder

Based on classification, recommend the primary and secondary actions:

1. **NORMAL_TRANSIT** → Reassure customer with carrier tracking URL + expected delivery
2. **STALE_PRE_TRANSIT** → Investigate if first-mile pickup occurred; may need carrier pickup claim
3. **STALE_IN_TRANSIT** → File carrier investigation; proactive customer note with timeline
4. **DELIVERY_EXCEPTION** → Contact carrier for reattempt or redirect; notify customer
5. **RETURN_TO_SENDER** → Determine root cause (address? refused?); prepare reship decision
6. **DELIVERED_NOT_RECEIVED** → Advise 48h wait; if past 48h, file carrier claim
7. **WRONG_ADDRESS** → Check if address correction needed; contact customer to confirm
8. **CARRIER_DELAY** → Proactive customer note; monitor for 24-48h then escalate
9. **TRACKING_ERROR** → Check for tracking code typo; try alternate lookups; escalate to engineering if systematic
10. **VOIDED** → Check if replacement label was created; may indicate order cancellation

## Step 5: Reply in Thread

Compose your reply as plain markdown (OpenClaw handles Slack formatting). Structure it as:

**Header line**: 📦 **WISMO Analysis** — `{tracking_code}`

**Status table**:
- Tracking: `{tracking_code}`
- Carrier: `{carrier_name}`
- Status: `{status_emoji}` `{status}`
- Classification: `{classification}` (`{urgency}`)

**Latest Events** (last 3-5, most recent first):
- `{timestamp}` — `{message}` (`{city}, {state}`)

**Analysis**: 1-2 paragraph summary of what happened, why, and what's likely next.

**Recommended Actions**:
1. Primary: `{action}` — `{detail}`
2. Secondary: `{action}` — `{detail}`

**Customer Message Draft**: Ready-to-send message for the customer explaining the situation.

**Carrier Message Draft** (if applicable): Ready-to-send email to the carrier for investigation/claim.

Use these status emojis:
- PRE_TRANSIT: 📋
- IN_TRANSIT: 🚚
- OUT_FOR_DELIVERY: 🏠
- DELIVERED: ✅
- RETURN_TO_SENDER: ↩️
- FAILURE: ❌
- ERROR: ⚠️
- VOIDED: 🚫

## Step 6: Regression Detection

After each lookup, check for data anomalies that may indicate tracking normalization bugs in Robin:

- **Status/event mismatch**: Events show delivery scans but status is not DELIVERED
- **Unknown carrier**: Tracking code matches a known carrier format but carrier field is empty/unknown
- **Empty events**: Status is IN_TRANSIT but events array is empty or has only the label created event
- **Timestamp disorder**: Events are not in chronological order
- **Substatus gap**: Status is ERROR/FAILURE but no substatus provided

If any anomaly is detected, add a warning section:

> ⚠️ **Tracking Data Anomaly Detected**
> - Issue: `{description}`
> - Expected: `{what_should_be}`
> - Actual: `{what_was_returned}`
>
> This may indicate a tracking normalization regression in Robin. Consider filing an engineering ticket.

## Step 7: Handle Button/Follow-up Actions

When a human follows up in the thread asking you to take action (e.g., "send the carrier email", "escalate this", "mark resolved"), respond accordingly:

### Send Carrier Email
Use `gog gmail send` to send the carrier investigation email you drafted:
```bash
XDG_CONFIG_HOME=/data/config GOG_KEYRING_PASSWORD=$GOG_KEYRING_PASSWORD gog gmail send --to <carrier-email> --subject "Tracking Investigation: {tracking_code}" --body "<drafted message>"
```
Confirm in thread when sent.

### Mark Resolved
Reply in thread confirming resolution and any follow-up notes.

### Escalate
Tag the appropriate team member and include the full analysis context.

## Environment Variables

- `ROBIN_API_KEY` — Bearer token for Robin API (required)
