// Fail when a Markdown paragraph or comment block reads above a set
// Flesch-Kincaid grade. This keeps the docs easy to read for a high school
// graduate. The score only looks at sentence and word length, so code, paths
// and tool names are left out to keep them from pushing the score up.
//   node toolchain/readability.mjs [max grade, default 12]
import { execFileSync } from "node:child_process";
import { readFileSync } from "node:fs";

const max = Number(process.argv[2] ?? 12);
// Long names that are not hard words.
const TOOLS = /\b(?:editorconfig-checker|markdownlint-cli2|markdownlint|semantic-release|ShellCheck|actionlint|lefthook|Dependabot)\b/gi;

// A common estimate: count vowel groups, but skip a silent final e, -es or -ed.
function syllables(word) {
  const w = word.toLowerCase().replace(/[^a-z]/g, "");
  if (w.length <= 3) return 1;
  const groups = w.replace(/(?:[^laeiouy]es|ed|[^laeiouy]e)$/, "").replace(/^y/, "").match(/[aeiouy]{1,2}/g);
  return Math.max(1, groups ? groups.length : 1);
}

function scrub(text) {
  return text
    .replace(/`[^`]*`/g, " X ")
    .replace(/!?\[([^\]]*)\]\([^)]*\)/g, "$1")
    .replace(/https?:\/\/\S+/g, " X ")
    .replace(/\S*[/_$=<>@]\S*/g, " X ")
    .replace(/\b[\w-]+\.(?:md|sh|gd|yml|yaml|json|jsonc|cfg|mk|mjs|txt|zip)\b/g, " X ")
    .replace(TOOLS, " X ")
    .replace(/[*#>|]/g, " ")
    .replace(/\s*\n\s*/g, " ");
}

function grade(text) {
  const sentences = text.split(/(?<=[.!?])\s+/).filter((s) => /[a-z]{2,}/i.test(s));
  const words = sentences.flatMap((s) => s.split(/\s+/).filter((w) => /[a-z]/i.test(w)));
  if (words.length < 8) return 0;
  const syl = words.reduce((n, w) => n + syllables(w), 0);
  return 0.39 * (words.length / sentences.length) + 11.8 * (syl / words.length) - 15.59;
}

// Blocks of { line, text }: paragraphs, list items and table rows in Markdown.
function markdownBlocks(lines) {
  const blocks = [];
  let block = null;
  let fenced = false;
  const end = () => { if (block) blocks.push(block); block = null; };
  lines.forEach((line, i) => {
    if (/^\s*```/.test(line)) { fenced = !fenced; end(); return; }
    if (fenced || /^\s*$/.test(line) || /^\s*\|?\s*-{3}/.test(line)) { end(); return; }
    if (/^\s*\|/.test(line)) {
      // Each table cell reads as its own sentence.
      end();
      const cells = line.split("|").map((c) => c.trim()).filter(Boolean);
      blocks.push({ line: i + 1, text: cells.map((c) => c.replace(/\.?$/, ".")).join(" ") });
      return;
    }
    if (/^\s*(?:#{1,6}\s|[-*]\s|\d+\.\s)/.test(line)) end();
    block ??= { line: i + 1, text: "" };
    block.text += line + "\n";
  });
  end();
  return blocks;
}

// Runs of whole-line comments, ignoring shebangs and tool directives.
function commentBlocks(lines, marker) {
  const blocks = [];
  let block = null;
  lines.forEach((line, i) => {
    const m = line.match(marker);
    if (!m || /^#!|shellcheck |^syntax=/.test(line.trim()) || !m[1].trim()) {
      if (block) blocks.push(block);
      block = null;
      return;
    }
    block ??= { line: i + 1, text: "" };
    block.text += m[1] + "\n";
  });
  if (block) blocks.push(block);
  return blocks;
}

function blocksOf(file, lines) {
  if (file.endsWith(".md")) return markdownBlocks(lines);
  if (/\.(?:jsonc|mjs)$/.test(file)) return commentBlocks(lines, /^\s*\/\/\s?(.*)$/);
  if (/\.(?:cfg|godot)$/.test(file)) return commentBlocks(lines, /^\s*;\s?(.*)$/);
  if (/\.(?:sh|gd|ya?ml|mk)$|(?:^|\/)(?:Dockerfile|Makefile|\.git\w+|\.editorconfig|CODEOWNERS)$|^toolchain\/bin\//.test(file)) {
    return commentBlocks(lines, /^\s*#+\s?(.*)$/);
  }
  return [];
}

const files = execFileSync("git", ["ls-files", "-co", "--exclude-standard"], { encoding: "utf8" }).split("\n").filter(Boolean);
let failed = 0;
for (const file of files) {
  let src;
  try { src = readFileSync(file, "utf8"); } catch { continue; }
  for (const block of blocksOf(file, src.split("\n"))) {
    const g = grade(scrub(block.text));
    if (g > max) {
      failed++;
      console.log(`${file}:${block.line}: grade ${g.toFixed(1)}, over ${max}: ${block.text.replace(/\s+/g, " ").trim().slice(0, 80)}`);
    }
  }
}
if (failed) {
  console.log(`${failed} block(s) read above grade ${max}. Use shorter sentences and plainer words.`);
  process.exit(1);
}
console.log(`readability: ok (grade ${max} or below)`);
