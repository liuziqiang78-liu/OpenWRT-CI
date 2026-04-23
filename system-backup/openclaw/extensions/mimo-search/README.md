# Mimo Web Search Plugin

OpenClaw plugin that provides web search capabilities via the Mimo Search API.

## Installation

```bash
openclaw plugins install -l ./extensions/mimo-search
```

## Configuration

Add the following to your `openclaw.json`:

```json
{
  "plugins": {
    "entries": {
      "mimo-search": {
        "enabled": true,
        "config": {
          "token": "your-api-token-here",
          "apiBaseUrl": "https://aistudio.xiaomimimo.com/open-apis/search",
          "maxResults": 5
        }
      }
    }
  }
}
```

### Config Options

| Option       | Required | Default                                       | Description                              |
| ------------ | -------- | --------------------------------------------- | ---------------------------------------- |
| `token`      | Yes      | —                                             | API token for authentication             |
| `apiBaseUrl` | No       | `https://aistudio.xiaomimimo.com/open-apis/search` | Search API endpoint URL                  |
| `maxResults` | No       | `5`                                           | Max number of results to return (1–20)   |

## Tool

### `mimo_web_search`

Search the web for real-time information.

**Parameters:**

- `query` (string, required): The search query.

**Example agent usage:**

> "What's the weather in Wuhan today?"

The agent will call `mimo_web_search` with `{"query": "武汉今天什么天气"}` and receive formatted results with titles, URLs, summaries, and source information.
