import {
  DEFAULT_MAX_LENGTH,
  FETCH_TIMEOUT_MS,
  type FetchDetails,
} from "./types.js";

type FetchResult = {
  content: { type: "text"; text: string }[];
  details: FetchDetails;
};

function errorResult(
  url: string,
  mode: "raw" | "readable",
  message: string,
): FetchResult {
  return {
    content: [{ type: "text" as const, text: `Error: ${message}` }],
    details: {
      url,
      mode,
      status: 0,
      contentType: "",
      originalLength: 0,
      returnedLength: 0,
      truncated: false,
      error: message,
    },
  };
}

function extractReadableText(html: string): string {
  let text = html
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, " ")
    .replace(/<style\b[^>]*>[\s\S]*?<\/style>/gi, " ")
    .replace(/<!--[\s\S]*?-->/g, " ");

  text = text.replace(
    /<\/(p|div|section|article|header|footer|h[1-6]|li|tr|blockquote|pre)>/gi,
    "\n",
  );

  text = text.replace(/<br\s*\/?>/gi, "\n").replace(/<hr\s*\/?>/gi, "\n---\n");
  text = text.replace(/<[^>]+>/g, "");

  // Decode numeric character references (decimal and hex)
  text = text
    .replace(/&#x([0-9a-f]+);/gi, (_, hex) =>
      String.fromCodePoint(parseInt(hex, 16)),
    )
    .replace(/&#([0-9]+);/g, (_, dec) =>
      String.fromCodePoint(parseInt(dec, 10)),
    );

  // Decode common named HTML entities
  const NAMED_ENTITIES: Record<string, string> = {
    amp: "&",
    lt: "<",
    gt: ">",
    quot: '"',
    apos: "'",
    nbsp: "\u00A0",
    mdash: "—",
    ndash: "–",
    hellip: "…",
    ldquo: "\u201C",
    rdquo: "\u201D",
    lsquo: "\u2018",
    rsquo: "\u2019",
    copy: "©",
    reg: "®",
    trade: "™",
    middot: "·",
    bull: "•",
    laquo: "«",
    raquo: "»",
    eacute: "é",
    egrave: "è",
    ecirc: "ê",
    agrave: "à",
    aacute: "á",
    acirc: "â",
    atilde: "ã",
    auml: "ä",
    oacute: "ó",
    ograve: "ò",
    ocirc: "ô",
    ouml: "ö",
    uacute: "ú",
    ugrave: "ù",
    uuml: "ü",
    iacute: "í",
    igrave: "ì",
    icirc: "î",
    iuml: "ï",
    ntilde: "ñ",
    ccedil: "ç",
    szlig: "ß",
  };
  text = text.replace(/&([a-z]+);/gi, (match, name) => {
    return NAMED_ENTITIES[name.toLowerCase()] ?? match;
  });

  return text
    .replace(/[ \t]+/g, " ")
    .replace(/\n[ \t]+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

export async function executeFetch(
  url: string,
  mode: "raw" | "readable" = "readable",
  maxLength: number = DEFAULT_MAX_LENGTH,
  signal?: AbortSignal,
): Promise<FetchResult> {
  let parsedUrl: URL;
  try {
    parsedUrl = new URL(url);
  } catch {
    return errorResult(url, mode, `Invalid URL: "${url}"`);
  }

  if (!["http:", "https:"].includes(parsedUrl.protocol)) {
    return errorResult(
      url,
      mode,
      `Unsupported protocol "${parsedUrl.protocol}" — only http/https are allowed`,
    );
  }

  const controller = new AbortController();
  let timedOut = false;
  let externallyAborted = false;
  const timeoutId = setTimeout(() => {
    timedOut = true;
    controller.abort();
  }, FETCH_TIMEOUT_MS);

  const onExternalAbort = () => {
    externallyAborted = true;
    controller.abort();
  };
  signal?.addEventListener("abort", onExternalAbort);

  let response: Response;
  try {
    response = await fetch(url, {
      signal: controller.signal,
      headers: {
        "User-Agent": "pi-coding-agent/web-fetch",
        Accept: "text/html,text/plain,application/xhtml+xml,*/*",
      },
      redirect: "follow",
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return errorResult(
      url,
      mode,
      timedOut
        ? `Request timed out after ${FETCH_TIMEOUT_MS / 1000}s`
        : externallyAborted
          ? "Request was cancelled"
          : `Network error: ${msg}`,
    );
  } finally {
    clearTimeout(timeoutId);
    signal?.removeEventListener("abort", onExternalAbort);
  }

  const contentType = response.headers.get("content-type") ?? "";

  if (!response.ok) {
    response.body?.cancel().catch(() => {});
    return errorResult(
      url,
      mode,
      `HTTP ${response.status} ${response.statusText}`,
    );
  }

  let body: string;
  try {
    body = await response.text();
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return errorResult(url, mode, `Failed to read response body: ${msg}`);
  }

  const originalLength = body.length;
  let content = mode === "readable" ? extractReadableText(body) : body;

  const truncated = content.length > maxLength;
  const returnedLength = truncated ? maxLength : content.length;
  if (truncated) {
    content =
      content.slice(0, maxLength) +
      `\n\n…[truncated — ${originalLength.toLocaleString()} chars total, showing first ${maxLength.toLocaleString()}]`;
  }

  return {
    content: [{ type: "text" as const, text: content }],
    details: {
      url,
      mode,
      status: response.status,
      contentType,
      originalLength,
      returnedLength,
      truncated,
    },
  };
}
