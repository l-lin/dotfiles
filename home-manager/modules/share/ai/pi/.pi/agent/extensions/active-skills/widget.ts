/**
 * Active-skills widget — shows all skills activated in the current session.
 *
 * Uses the factory form of setWidget so the component is registered once and
 * renders dynamically without rebuilding the widget container on every update.
 */
import type { ExtensionContext } from "@mariozechner/pi-coding-agent";
import type { TUI } from "@mariozechner/pi-tui";
import { truncateToWidth } from "@mariozechner/pi-tui";
import type { ActivatedSkill } from "./types.js";
import { ICON_SKILL } from "./types.js";

export const WIDGET_KEY = "active-skills";
export const WIDGET_PLACEMENT = { placement: "belowEditor" as const };

class SkillWidgetManager {
  private skills: ActivatedSkill[] = [];
  private requestRenderFn: (() => void) | undefined;
  private registered = false;

  update(ctx: ExtensionContext, skills: ActivatedSkill[]): void {
    if (!ctx.hasUI) return;
    this.skills = skills;

    if (skills.length === 0) {
      this.deregister(ctx);
      return;
    }

    this.ensureRegistered(ctx);
    this.requestRenderFn?.();
  }

  clear(ctx: ExtensionContext): void {
    this.skills = [];
    this.requestRenderFn = undefined;
    this.deregister(ctx);
  }

  private deregister(ctx: ExtensionContext): void {
    if (!this.registered) return;
    this.registered = false;
    if (ctx.hasUI) ctx.ui.setWidget(WIDGET_KEY, undefined);
  }

  private ensureRegistered(ctx: ExtensionContext): void {
    if (this.registered) return;
    this.registered = true;

    ctx.ui.setWidget(
      WIDGET_KEY,
      (tui: TUI, theme: any) => {
        this.requestRenderFn = () => tui.requestRender();
        tui.requestRender();

        return {
          render: (width: number): string[] => {
            if (this.skills.length === 0) return [];

            const names = this.skills.map((s) => s.name).join("+");
            const line = theme.fg("muted", `${ICON_SKILL} ${names}`);

            return [truncateToWidth(line, width)];
          },
          invalidate() {},
        };
      },
      WIDGET_PLACEMENT,
    );
  }
}

export const skillWidgetManager = new SkillWidgetManager();

export function updateSkillWidget(
  ctx: ExtensionContext,
  skills: ActivatedSkill[],
): void {
  skillWidgetManager.update(ctx, skills);
}

export function clearSkillWidget(ctx: ExtensionContext): void {
  skillWidgetManager.clear(ctx);
}
