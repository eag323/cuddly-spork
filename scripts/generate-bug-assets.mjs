#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';
import XLSX from 'xlsx';
import pLimit from 'p-limit';
import { PixelLabClient } from '@pixellab/sdk';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..');

const DEFAULTS = {
  input: path.join(repoRoot, 'BugsOS_200_Bugs_Themed_Prompts.xlsx'),
  styleImage: path.join(repoRoot, 'style.png'),
  outputDir: path.join(repoRoot, 'assets', 'bugs'),
  optionsPerBug: 3,
  width: 256,
  height: 256,
  noBackground: true,
  concurrency: 1,
  delayMs: 1200,
  retries: 3,
  retryDelayMs: 1800,
  sheet: null,
  dryRun: false,
};

function parseArgs(argv) {
  const cfg = { ...DEFAULTS };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--dry-run') cfg.dryRun = true;
    else if (arg === '--input') cfg.input = path.resolve(argv[++i]);
    else if (arg === '--style') cfg.styleImage = path.resolve(argv[++i]);
    else if (arg === '--out') cfg.outputDir = path.resolve(argv[++i]);
    else if (arg === '--sheet') cfg.sheet = argv[++i];
    else if (arg === '--concurrency') cfg.concurrency = Number(argv[++i]);
    else if (arg === '--delay-ms') cfg.delayMs = Number(argv[++i]);
    else if (arg === '--retries') cfg.retries = Number(argv[++i]);
    else if (arg === '--retry-delay-ms') cfg.retryDelayMs = Number(argv[++i]);
    else if (arg === '--help' || arg === '-h') {
      console.log('Usage: node scripts/generate-bug-assets.mjs [--dry-run] [--input file.xlsx] [--style style.png] [--out assets/bugs] [--sheet name] [--concurrency n] [--delay-ms n] [--retries n]');
      process.exit(0);
    }
  }
  return cfg;
}

function sleep(ms) { return new Promise((resolve) => setTimeout(resolve, ms)); }

function slugify(value) {
  return String(value ?? '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function pick(row, keys) {
  for (const key of keys) {
    if (row[key] != null && String(row[key]).trim() !== '') return row[key];
  }
  return undefined;
}

async function withRetry(fn, retries, retryDelayMs, context) {
  let attempt = 0;
  while (attempt <= retries) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === retries) throw error;
      attempt += 1;
      console.warn(`[retry] ${context} failed (${error.message}); retry ${attempt}/${retries} in ${retryDelayMs}ms`);
      await sleep(retryDelayMs);
    }
  }
}

async function parseWorkbook(inputPath, preferredSheet) {
  const workbook = XLSX.readFile(inputPath);
  const sheetName = preferredSheet || workbook.SheetNames[0];
  if (!sheetName) throw new Error('No worksheet found in workbook');
  const sheet = workbook.Sheets[sheetName];
  const rows = XLSX.utils.sheet_to_json(sheet, { defval: '' });

  const bugs = rows.map((row, idx) => {
    const prompt = pick(row, ['prompt', 'Prompt', 'PROMPT']);
    const rarity = pick(row, ['rarity', 'Rarity', 'RARITY']);
    const name = pick(row, ['name', 'Name', 'bug_name', 'Bug Name']);
    const slugRaw = pick(row, ['slug', 'Slug']) || name || `bug-${idx + 1}`;
    return {
      index: idx + 1,
      name: String(name || slugRaw),
      rarity: slugify(rarity || 'unknown'),
      prompt: String(prompt || '').trim(),
      slug: slugify(slugRaw),
    };
  }).filter((row) => row.prompt);

  return { sheetName, bugs };
}

async function main() {
  const cfg = parseArgs(process.argv.slice(2));
  if (!process.env.PIXELLAB_API_KEY && !cfg.dryRun) {
    throw new Error('Missing PIXELLAB_API_KEY environment variable');
  }

  await fs.access(cfg.input);
  await fs.access(cfg.styleImage);

  const { sheetName, bugs } = await parseWorkbook(cfg.input, cfg.sheet);
  const styleBuffer = await fs.readFile(cfg.styleImage);
  const styleBase64 = styleBuffer.toString('base64');

  const client = cfg.dryRun ? null : new PixelLabClient({ apiKey: process.env.PIXELLAB_API_KEY });
  const limiter = pLimit(Math.max(1, cfg.concurrency));
  let lastRequestAt = 0;

  const generationTasks = bugs.map((bug) => limiter(async () => {
    const bugDir = path.join(cfg.outputDir, bug.rarity, bug.slug);
    const filenames = Array.from({ length: cfg.optionsPerBug }, (_, i) => `option_${i + 1}.png`);
    const metadataPath = path.join(bugDir, 'metadata.json');

    const metadata = {
      name: bug.name,
      rarity: bug.rarity,
      prompt: bug.prompt,
      filenames,
      generationStatus: cfg.dryRun ? 'dry-run' : 'pending',
      error: null,
      generatedAt: new Date().toISOString(),
    };

    await fs.mkdir(bugDir, { recursive: true });

    try {
      for (let i = 0; i < cfg.optionsPerBug; i += 1) {
        if (cfg.dryRun) continue;
        const now = Date.now();
        const waitFor = cfg.delayMs - (now - lastRequestAt);
        if (waitFor > 0) await sleep(waitFor);

        const response = await withRetry(async () => client.images.generate({
          prompt: bug.prompt,
          noBackground: cfg.noBackground,
          imageSize: { width: cfg.width, height: cfg.height },
          styleImage: styleBase64,
        }), cfg.retries, cfg.retryDelayMs, `${bug.slug}:option_${i + 1}`);

        lastRequestAt = Date.now();
        const b64 = response?.imageBase64 || response?.data?.[0]?.b64_json;
        if (!b64) throw new Error('PixelLab response missing image base64');
        await fs.writeFile(path.join(bugDir, filenames[i]), Buffer.from(b64, 'base64'));
      }
      metadata.generationStatus = cfg.dryRun ? 'dry-run' : 'success';
    } catch (error) {
      metadata.generationStatus = 'failed';
      metadata.error = error.message;
      console.error(`[error] ${bug.slug}: ${error.message}`);
    }

    await fs.writeFile(metadataPath, JSON.stringify(metadata, null, 2));
  }));

  await Promise.all(generationTasks);
  console.log(`Processed ${bugs.length} bugs from sheet "${sheetName}".`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
