import { existsSync, readdirSync, readFileSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = fileURLToPath(new URL('../..', import.meta.url));
const SELF = fileURLToPath(import.meta.url);
const SKILL_KEYS = new Set(['name', 'description', 'license', 'compatibility', 'metadata', 'allowed-tools']);
const SKILL_NAME = /^[a-z0-9]+(-[a-z0-9]+)*$/;
const FORBIDDEN = [
  { pattern: /\/internal\b/, reason: 'rota interna da API' },
  { pattern: /\bnd-(key|oat|ort)\.[A-Za-z0-9_-]{8,}/, reason: 'chave ou token da NomadFy' },
];

const errors = [];
const fail = (file, message) => {
  errors.push(`${relative(ROOT, file)}: ${message}`);
};

function frontmatter(file) {
  const match = readFileSync(file, 'utf8').match(/^---\n([\s\S]*?)\n---\n/);
  if (!match) {
    fail(file, 'sem o cabeçalho entre ---');
    return null;
  }
  const fields = {};
  for (const line of match[1].split('\n')) {
    if (!line.trim() || /^\s/.test(line)) continue;
    const field = line.match(/^([a-z-]+):\s*(.*)$/);
    if (!field) {
      fail(file, `linha do cabeçalho fora do formato: ${line}`);
      return null;
    }
    const [, key, raw] = field;
    try {
      fields[key] = raw.startsWith('"') ? JSON.parse(raw) : raw;
    } catch {
      fail(file, `valor entre aspas inválido em "${key}"`);
      return null;
    }
  }
  return fields;
}

const skillsDir = join(ROOT, 'skills');
for (const name of readdirSync(skillsDir)) {
  const dir = join(skillsDir, name);
  if (!statSync(dir).isDirectory()) continue;
  const file = join(dir, 'SKILL.md');
  if (!existsSync(file)) {
    fail(dir, 'pasta de skill sem o SKILL.md');
    continue;
  }
  const fields = frontmatter(file);
  if (!fields) continue;
  for (const key of Object.keys(fields)) {
    if (!SKILL_KEYS.has(key)) fail(file, `campo "${key}" não aceito no cabeçalho`);
  }
  if (fields.name !== name) fail(file, `name "${fields.name}" diferente da pasta "${name}"`);
  if (!SKILL_NAME.test(name) || name.length > 64) fail(file, 'nome fora do formato (minúsculas, números e hífen, até 64)');
  if (!fields.description || fields.description.length > 1024) fail(file, 'description vazia ou com mais de 1024 caracteres');
}

function json(path) {
  try {
    return JSON.parse(readFileSync(join(ROOT, path), 'utf8'));
  } catch (error) {
    fail(join(ROOT, path), `JSON inválido: ${error.message}`);
    return null;
  }
}

const plugin = json('.claude-plugin/plugin.json');
const marketplace = json('.claude-plugin/marketplace.json');
json('.mcp.json');
if (plugin && marketplace && !marketplace.plugins?.some((entry) => entry.name === plugin.name)) {
  fail(join(ROOT, '.claude-plugin/marketplace.json'), `nenhum plugin com o nome "${plugin.name}"`);
}

function walk(dir) {
  for (const entry of readdirSync(dir)) {
    if (entry === '.git' || entry === 'node_modules') continue;
    const path = join(dir, entry);
    if (statSync(path).isDirectory()) {
      walk(path);
    } else if (path !== SELF && /\.(md|json|sh|mjs|ya?ml)$/.test(entry)) {
      const text = readFileSync(path, 'utf8');
      for (const { pattern, reason } of FORBIDDEN) {
        if (pattern.test(text)) fail(path, reason);
      }
    }
  }
}
walk(ROOT);

if (errors.length) {
  console.error(errors.join('\n'));
  process.exit(1);
}
console.log('Tudo certo.');
