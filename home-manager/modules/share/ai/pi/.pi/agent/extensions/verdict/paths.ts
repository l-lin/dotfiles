import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export function baseForms(filePath: string): string[] {
  const forms = [filePath];

  try {
    const resolvedPath = fs.realpathSync(filePath);

    if (resolvedPath !== filePath) {
      forms.push(resolvedPath);
    }
  } catch {}

  return forms;
}

// Resolve existing ancestors so writes to nonexistent symlink targets cannot escape protection.
export function rebuiltForms(absolutePath: string): string[] {
  const forms = new Set<string>([absolutePath]);
  let ancestor = absolutePath;
  const tail: string[] = [];

  for (;;) {
    try {
      const real = fs.realpathSync(ancestor);
      forms.add(path.join(real, ...tail));

      return [...forms];
    } catch {}

    let link: string | null = null;

    try {
      if (fs.lstatSync(ancestor).isSymbolicLink()) {
        link = path.resolve(path.dirname(ancestor), fs.readlinkSync(ancestor));
      }
    } catch {
      link = null;
    }

    if (link !== null && !forms.has(link)) {
      forms.add(path.join(link, ...tail));
      ancestor = link;
      continue;
    }

    const parent = path.dirname(ancestor);

    if (parent === ancestor) {
      return [...forms];
    }

    tail.unshift(path.basename(ancestor));
    ancestor = parent;
  }
}

const CASE_INSENSITIVE_FS =
  process.platform === "darwin" || process.platform === "win32";

const fold = (value: string): string =>
  CASE_INSENSITIVE_FS ? value.toLowerCase() : value;

export const pathEquals = (left: string, right: string): boolean =>
  fold(left) === fold(right);

export const pathStartsWith = (child: string, base: string): boolean => {
  const foldedBase = fold(base);

  // A root path contains every absolute path; adding a second separator would prevent matches.
  if (foldedBase === path.sep) {
    return true;
  }

  return fold(child).startsWith(foldedBase + path.sep);
};

export function expandHome(filePath: string): string {
  return filePath.startsWith("~")
    ? path.join(os.homedir(), filePath.slice(1))
    : filePath;
}
