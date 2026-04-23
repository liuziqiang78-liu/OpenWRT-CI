import { Type } from "@sinclair/typebox";

interface WebPage {
  name: string;
  url: string;
  snippet: string;
  summary: string;
  siteName: string;
  datePublished: string;
}

interface SearchApiResponse {
  code: number;
  msg: string;
  data: {
    webPages?: {
      value: WebPage[];
    };
  };
}

const DEFAULT_API_URL = "https://aistudio.xiaomimimo.com/open-apis/search";
const DEFAULT_MAX_RESULTS = 5;

function formatWebPage(page: WebPage, index: number): string {
  const parts: string[] = [];
  parts.push(`[${index + 1}] ${page.name}`);
  parts.push(`    URL: ${page.url}`);
  if (page.siteName) {
    parts.push(`    Source: ${page.siteName}`);
  }
  if (page.datePublished) {
    parts.push(`    Date: ${page.datePublished.split("T")[0]}`);
  }
  const text = page.snippet || page.summary;
  if (text) {
    parts.push(`    Content: ${text.replace(/\n+/g, " ").trim()}`);
  }
  return parts.join("\n");
}

export default function mimoSearchPlugin(api: any) {
  api.registerTool({
    name: "mimo_web_search",
    description:
      "Search the web for real-time information including news, facts, weather, documentation, or anything requiring up-to-date data. Returns results with titles, URLs, summaries, and sources.",
    parameters: Type.Object({
      query: Type.String({
        description:
          "The search query. Be specific and descriptive for better results.",
      }),
    }),

    async execute(
      _toolCallId: string,
      params: { query: string },
    ) {
      const pluginConfig = api.config?.plugins?.entries?.["mimo-search"]?.config ?? {};
      const token = pluginConfig.token;
      const apiUrl = pluginConfig.apiBaseUrl || DEFAULT_API_URL;
      const maxResults = pluginConfig.maxResults || DEFAULT_MAX_RESULTS;

      if (!token) {
        return {
          content: [
            {
              type: "text" as const,
              text: "Error: Mimo Search API token is not configured. Please set the token in plugins.entries.mimo-search.config.token in your openclaw.json configuration.",
            },
          ],
        };
      }

      try {
        const response = await fetch(apiUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ token, query: params.query }),
        });

        if (!response.ok) {
          return {
            content: [
              {
                type: "text" as const,
                text: `Error: Search API returned HTTP ${response.status} ${response.statusText}`,
              },
            ],
          };
        }

        const result: SearchApiResponse = await response.json();

        if (result.code !== 0) {
          return {
            content: [
              {
                type: "text" as const,
                text: `Error: Search API error ${result.code}: ${result.msg}`,
              },
            ],
          };
        }

        const webPages = result.data?.webPages?.value ?? [];

        if (webPages.length === 0) {
          return {
            content: [
              {
                type: "text" as const,
                text: `No results found for: "${params.query}"`,
              },
            ],
          };
        }

        const limitedPages = webPages.slice(0, maxResults);
        const formattedResults = limitedPages
          .map((page, i) => formatWebPage(page, i))
          .join("\n\n");

        return {
          content: [
            {
              type: "text" as const,
              text: `Search results for "${params.query}":\n\n${formattedResults}`,
            },
          ],
        };
      } catch (error: unknown) {
        const message = error instanceof Error ? error.message : String(error);
        return {
          content: [
            {
              type: "text" as const,
              text: `Error: Web search failed: ${message}`,
            },
          ],
        };
      }
    },
  });
}
