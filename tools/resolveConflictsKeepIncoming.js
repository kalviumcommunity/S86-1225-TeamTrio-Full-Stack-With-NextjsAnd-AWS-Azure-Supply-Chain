const fs = require('fs');
const path = require('path');

function resolveFile(filePath) {
  let src = fs.readFileSync(filePath, 'utf8');
  if (!src.includes('<<<<<<<')) return false;

  let changed = false;
  while (src.includes('<<<<<<<')) {
    const start = src.indexOf('<<<<<<<');
    const mid = src.indexOf('=======', start);
    const end = src.indexOf('>>>>>>>', mid);
    if (start === -1 || mid === -1 || end === -1) break;

    const incomingBlock = src.slice(mid + '======='.length, end).replace(/^\n/, '');
    src = src.slice(0, start) + incomingBlock + src.slice(end + ('>>>>>>>'.length));
    changed = true;
  }

  if (changed) {
    fs.writeFileSync(filePath, src, 'utf8');
  }
  return changed;
}

function walk(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (['.git', 'node_modules', '.next'].includes(e.name)) continue;
      walk(full);
    } else if (e.isFile()) {
      try {
        const stat = fs.statSync(full);
        if (stat.size > 5 * 1024 * 1024) continue; // skip very large files
        const content = fs.readFileSync(full, 'utf8');
        if (content.includes('<<<<<<<')) {
          const ok = resolveFile(full);
          if (ok) console.log('Resolved:', full);
        }
      } catch (err) {
        // ignore binary or unreadable files
      }
    }
  }
}

const root = path.resolve(process.argv[2] || '.');
console.log('Scanning for conflict markers under', root);
walk(root);
console.log('Done');
