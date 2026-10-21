import { basename } from "node:path";
import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, type TUI, visibleWidth } from "@earendil-works/pi-tui";

const FIELD_SEPARATOR = "\x1f";
const JJ_COLORS = ["accent", "muted", "success", "text"] as const;

type JjContext = {
	fields: string[];
};

type UsageTotals = {
	input: number;
	output: number;
	cacheRead: number;
	cacheWrite: number;
	cost: number;
};

function clean(value: string): string {
	return value.replace(/[\u0000-\u001f\u007f]/g, " ").trim();
}

function repositoryName(remoteOutput: string, root: string): string {
	const origin = remoteOutput.split("\n").find((line) => line.startsWith("origin "))?.slice(7).trim();
	const match = origin?.match(/github\.com[:/]([^/]+\/[^/]+?)(?:\.git)?$/);
	return match?.[1] ?? basename(root);
}

function formatTokens(value: number): string {
	if (value < 1_000) return `${value}`;
	if (value < 1_000_000) return `${Math.round(value / 1_000)}k`;
	return `${Math.round(value / 1_000_000)}M`;
}

function usageTotals(ctx: ExtensionContext): UsageTotals {
	const totals: UsageTotals = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0 };
	for (const entry of ctx.sessionManager.getBranch()) {
		if (entry.type !== "message" || entry.message.role !== "assistant") continue;
		const usage = (entry.message as AssistantMessage).usage;
		totals.input += usage.input;
		totals.output += usage.output;
		totals.cacheRead += usage.cacheRead;
		totals.cacheWrite += usage.cacheWrite;
		totals.cost += usage.cost.total;
	}
	return totals;
}

function renderJjContext(context: JjContext, theme: ExtensionContext["ui"]["theme"]): string {
	const separator = theme.fg("muted", " / ");
	return context.fields
		.map((field, index) => theme.fg(JJ_COLORS[index] ?? "text", field))
		.join(separator);
}

function renderUsage(
	ctx: ExtensionContext,
	pi: ExtensionAPI,
	theme: ExtensionContext["ui"]["theme"],
	width: number,
): string {
	const totals = usageTotals(ctx);
	const cacheTotal = totals.input + totals.cacheRead;
	const cacheHit = cacheTotal > 0 ? (totals.cacheRead / cacheTotal) * 100 : 0;
	const contextUsage = ctx.getContextUsage();
	const contextWindow = contextUsage?.contextWindow ?? ctx.model?.contextWindow ?? 0;
	const contextPercent = contextUsage?.percent ?? 0;
	const stats = [
		`↑${formatTokens(totals.input)}`,
		`↓${formatTokens(totals.output)}`,
		`R${formatTokens(totals.cacheRead)}`,
		`W${formatTokens(totals.cacheWrite)}`,
		`CH${cacheHit.toFixed(1)}%`,
		`$${totals.cost.toFixed(3)}`,
		`${contextPercent.toFixed(1)}%/${formatTokens(contextWindow)} (auto)`,
	].join(" ");
	const model = ctx.model ? `(${ctx.model.provider}) ${ctx.model.id}` : "no-model";
	const left = theme.fg("dim", stats);
	const right = theme.fg("dim", `${model} • ${pi.getThinkingLevel()}`);
	const padding = " ".repeat(Math.max(1, width - visibleWidth(left) - visibleWidth(right)));
	return truncateToWidth(left + padding + right, width);
}

function renderFooter(
	ctx: ExtensionContext,
	pi: ExtensionAPI,
	context: JjContext,
	theme: ExtensionContext["ui"]["theme"],
	width: number,
): string[] {
	return [
		truncateToWidth(renderJjContext(context, theme), width),
		renderUsage(ctx, pi, theme, width),
	];
}

async function readJjContext(pi: ExtensionAPI): Promise<JjContext | undefined> {
	const root = await pi.exec("jj", ["--ignore-working-copy", "root"], { timeout: 3_000 });
	if (root.code !== 0) return undefined;

	await pi.exec("jj", ["util", "snapshot"], { timeout: 3_000 });

	const [workspace, bookmark, revision, remotes] = await Promise.all([
		pi.exec(
			"jj",
			[
				"--ignore-working-copy",
				"workspace",
				"list",
				"--no-pager",
				"--color=never",
				"-T",
				'if(target.current_working_copy(), name, "")',
			],
			{ timeout: 3_000 },
		),
		pi.exec(
			"jj",
			[
				"--ignore-working-copy",
				"log",
				"--no-graph",
				"-r",
				"closest_bookmark(@)",
				"-T",
				'bookmarks.map(|b| b.name()).join(" ")',
			],
			{ timeout: 3_000 },
		),
		pi.exec(
			"jj",
			[
				"--ignore-working-copy",
				"log",
				"--no-graph",
				"-r",
				"@",
				"-T",
				'change_id.shortest(8) ++ "\\x1f" ++ description.first_line()',
			],
			{ timeout: 3_000 },
		),
		pi.exec("jj", ["--ignore-working-copy", "git", "remote", "list"], { timeout: 3_000 }),
	]);

	if (workspace.code !== 0 || bookmark.code !== 0 || revision.code !== 0 || remotes.code !== 0) {
		return undefined;
	}

	const [changeId, description = ""] = revision.stdout.split(FIELD_SEPARATOR);
	return {
		fields: [
			repositoryName(remotes.stdout, root.stdout.trim()),
			clean(workspace.stdout),
			clean(bookmark.stdout).split(/\s+/)[0],
			clean(description) || clean(changeId),
		].filter(Boolean),
	};
}

export default function (pi: ExtensionAPI): void {
	let currentContext: JjContext | undefined;
	let activeTui: TUI | undefined;

	const restoreDefaultFooter = (ctx: ExtensionContext) => {
		currentContext = undefined;
		ctx.ui.setFooter(undefined);
		activeTui = undefined;
	};

	const installFooter = (ctx: ExtensionContext) => {
		if (!currentContext || !ctx.hasUI) return;
		ctx.ui.setFooter((tui, theme, footerData) => {
			activeTui = tui;
			const unsubscribe = footerData.onBranchChange(() => tui.requestRender());
			return {
				dispose: () => {
					unsubscribe();
					if (activeTui === tui) activeTui = undefined;
				},
				invalidate() {},
				render: (width: number) => renderFooter(ctx, pi, currentContext ?? { fields: [] }, theme, width),
			};
		});
	};

	const refresh = async (ctx: ExtensionContext) => {
		const next = await readJjContext(pi);
		if (!next) {
			restoreDefaultFooter(ctx);
			return;
		}
		currentContext = next;
		activeTui?.requestRender();
		installFooter(ctx);
	};

	pi.on("session_start", async (_event, ctx) => refresh(ctx));
	pi.on("session_switch", async (_event, ctx) => refresh(ctx));
	pi.on("turn_end", async (_event, ctx) => refresh(ctx));
	pi.on("agent_end", async (_event, ctx) => refresh(ctx));
}
