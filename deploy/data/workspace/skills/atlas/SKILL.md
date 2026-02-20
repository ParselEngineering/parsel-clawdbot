---
name: atlas
description: Query Atlas.so helpdesk API to fetch support ticket conversations, messages, and customer details
metadata: {"openclaw": {"emoji": "🎫", "requires": {"env": ["ATLAS_API_KEY"]}}}
---

# Atlas.so — Support Ticket API

You have access to the Atlas.so helpdesk API to fetch ticket details, conversation messages, and customer information.

## Authentication

All requests use Bearer token auth via the `ATLAS_API_KEY` environment variable:

```
Authorization: Bearer $ATLAS_API_KEY
```

## Base URL

```
https://api.atlas.so/v1
```

## Available Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/conversations/{id}` | GET | Fetch a conversation/ticket by ID |
| `/conversations/{id}/messages` | GET | List all messages in a conversation |
| `/conversations` | GET | List conversations (paginated) |
| `/customers/lookup` | POST | Look up a customer by ID |
| `/customers/{id}` | GET | Fetch customer details (via update endpoint) |

## Usage

### Fetch a conversation/ticket by ID

```bash
curl -s -H "Authorization: Bearer $ATLAS_API_KEY" \
  "https://api.atlas.so/v1/conversations/{conversation_id}"
```

### List messages in a conversation

```bash
curl -s -H "Authorization: Bearer $ATLAS_API_KEY" \
  "https://api.atlas.so/v1/conversations/{conversation_id}/messages?cursor=0&limit=50"
```

### List recent conversations

```bash
curl -s -H "Authorization: Bearer $ATLAS_API_KEY" \
  "https://api.atlas.so/v1/conversations?cursor=0&limit=20"
```

### Look up a customer

```bash
curl -s -X POST -H "Authorization: Bearer $ATLAS_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"id": "{customer_id}"}' \
  "https://api.atlas.so/v1/customers/lookup"
```

## Extracting the Conversation ID from Slack

When an Atlas.so ticket arrives in Slack as a bot card, extract the conversation ID from:
- The message URL (e.g., `https://app.atlas.so/conversations/{id}`)
- The message metadata or fields containing the ticket/conversation reference

Use this ID to fetch the full ticket details via the endpoints above.

## Pagination

Use query parameters `cursor` and `limit` for paginated endpoints:
- `cursor=0` — start from the beginning
- `limit=20` — number of results per page (default: 20)

## Tips

- Always fetch the conversation first to get the ticket subject, status, and customer ID
- Use the messages endpoint to get the full customer complaint text
- Pipe through `jq` for readable output: `curl ... | jq .`
