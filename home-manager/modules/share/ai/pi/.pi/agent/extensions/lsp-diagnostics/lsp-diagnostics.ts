/**
 * Static LSP server definitions for the lsp-diagnostics extension.
 *
 * This file is the single source of truth for which language servers are
 * supported, how they are invoked, and what settings they receive. Prefer
 * editing this file over raw JSON — you get types, inline docs, and safety.
 *
 * Shape mirrors LspDiagnosticsFileConfig / LspServerConfig from types.ts.
 * Resolver picks up the first PATH-available binary for each matched file.
 */

import type { LspDiagnosticsFileConfig } from "./types.js";

export const LSP_SERVERS_CONFIG: LspDiagnosticsFileConfig = {
  servers: {
    // ── TypeScript / JavaScript ────────────────────────────────────────────
    // vtsls is the VS Code TypeScript language server, exposed as a standalone
    // binary. It handles both plain JS and TS, including JSX/TSX.
    vtsls: {
      command: "vtsls",
      args: ["--stdio"],
      fileTypes: [".ts", ".tsx", ".js", ".jsx"],
      rootMarkers: ["package.json", "tsconfig.json", ".git"],
    },

    // ── Java ──────────────────────────────────────────────────────────────
    // jdtls (Eclipse JDT Language Server) requires a writable workspace dir
    // passed via --data. The default /tmp path is safe for one-shot checks
    // but will lose cross-session indexing. Point it at a persistent dir if
    // you work on large Java projects.
    jdtls: {
      command: "jdtls",
      args: ["--data", "/tmp/jdtls-workspace"],
      fileTypes: [".java"],
      rootMarkers: [
        "pom.xml",
        "build.gradle",
        "build.gradle.kts",
        "settings.gradle",
        ".project",
      ],
    },

    // ── Nix ───────────────────────────────────────────────────────────────
    // nil is a lean Nix language server. No args needed; it speaks stdio by
    // default. Root is detected by flake.nix or the nearest .git boundary.
    nil: {
      command: "nil",
      args: [],
      fileTypes: [".nix"],
      rootMarkers: ["flake.nix", ".git"],
    },

    // ── Lua ───────────────────────────────────────────────────────────────
    // lua-language-server (sumneko). Globals include common Neovim-ecosystem
    // names so diagnostics don't flag `vim`, `LazyVim`, etc. as undefined.
    // checkThirdParty:false suppresses noisy "third-party library" prompts.
    "lua-language-server": {
      command: "lua-language-server",
      args: [],
      fileTypes: [".lua"],
      rootMarkers: [
        ".luarc.json",
        ".luarc.jsonc",
        ".luacheckrc",
        ".stylua.toml",
        "stylua.toml",
        ".git",
      ],
      settings: {
        Lua: {
          runtime: { version: "LuaJIT" },
          diagnostics: {
            globals: ["vim", "LazyVim", "Snacks", "describe", "it"],
          },
          workspace: { checkThirdParty: false },
          // Opt out of telemetry — the server phones home by default.
          telemetry: { enable: false },
        },
      },
    },

    // ── Ruby ──────────────────────────────────────────────────────────────
    // RuboCop doubles as an LSP server via --lsp. It reports style offences
    // as diagnostics. Needs a .rubocop.yml or Gemfile to anchor the root.
    rubocop: {
      command: "rubocop",
      args: ["--lsp"],
      fileTypes: [".rb"],
      rootMarkers: [".rubocop.yml", "Gemfile", ".git"],
    },

    // ── YAML ──────────────────────────────────────────────────────────────
    // yaml-language-server from Red Hat. Validates schema, anchors, and
    // indentation. Works best with a .yamllint or schema association, but
    // provides useful structural diagnostics even without one.
    "yaml-language-server": {
      command: "yaml-language-server",
      args: ["--stdio"],
      fileTypes: [".yaml", ".yml"],
      rootMarkers: [".git"],
    },

    // ── XML / SVG ─────────────────────────────────────────────────────────
    // LemMinX (Eclipse XML Language Server). Provides schema-aware
    // diagnostics for XML, XSD, XSL, XSLT, and SVG.
    //
    // The capabilities block below is required because LemMinX's completion
    // and rename support relies on specific client capability flags that are
    // not advertised by the default minimal client bundled in this extension.
    // Without them, LemMinX may emit spurious errors or skip rename edits.
    lemminx: {
      command: "lemminx",
      args: [],
      fileTypes: [".xml", ".xsd", ".xsl", ".xslt", ".svg"],
      rootMarkers: [".git"],
      capabilities: {
        textDocument: {
          completion: {
            completionItem: {
              commitCharactersSupport: false,
              deprecatedSupport: true,
              documentationFormat: ["markdown", "plaintext"],
              insertReplaceSupport: true,
              insertTextModeSupport: { valueSet: [1] },
              labelDetailsSupport: true,
              preselectSupport: false,
              resolveSupport: {
                properties: [
                  "documentation",
                  "detail",
                  "additionalTextEdits",
                  "command",
                  "data",
                ],
              },
              snippetSupport: true,
              tagSupport: { valueSet: [1] },
            },
            completionList: {
              itemDefaults: [
                "commitCharacters",
                "editRange",
                "insertTextFormat",
                "insertTextMode",
                "data",
              ],
            },
            contextSupport: true,
            insertTextMode: 1,
          },
        },
        workspace: {
          fileOperations: {
            didRename: true,
            willRename: true,
          },
        },
      },
    },
  },
};
