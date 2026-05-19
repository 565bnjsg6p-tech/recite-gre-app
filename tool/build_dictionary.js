const fs = require('fs');
const path = require('path');

const source = path.join(__dirname, 'ecdict.csv');
const output = path.join(__dirname, '..', 'assets', 'dictionaries', 'exam_basic.json');
const metaOutput = path.join(__dirname, '..', 'assets', 'dictionaries', 'exam_basic_meta.json');

function parseCsv(text) {
  const rows = [];
  let field = '';
  let row = [];
  let inQuotes = false;

  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    const next = text[i + 1];

    if (char === '"') {
      if (inQuotes && next === '"') {
        field += '"';
        i += 1;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char === ',' && !inQuotes) {
      row.push(field);
      field = '';
    } else if ((char === '\n' || char === '\r') && !inQuotes) {
      if (char === '\r' && next === '\n') {
        i += 1;
      }
      row.push(field);
      if (row.some((item) => item.length > 0)) {
        rows.push(row);
      }
      row = [];
      field = '';
    } else {
      field += char;
    }
  }

  if (field.length > 0 || row.length > 0) {
    row.push(field);
    rows.push(row);
  }
  return rows;
}

function cleanTranslation(raw) {
  return normalizeBreaks(raw)
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .filter((line) => !line.startsWith('[网络]'))
    .slice(0, 4)
    .join('\n');
}

function cleanDefinition(raw) {
  return normalizeBreaks(raw)
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .slice(0, 3)
    .join('\n');
}

function normalizeBreaks(raw) {
  return raw
    .replace(/\\r\\n/g, '\n')
    .replace(/\\n/g, '\n')
    .replace(/\\r/g, '\n')
    .replace(/\r/g, '\n');
}

function splitList(raw) {
  return raw
    .split(/[,\s;]+/)
    .map((item) => item.trim().toLowerCase())
    .filter(Boolean);
}

function isUsefulExamWord(word, tag, translation, definition) {
  if (!/^[a-z][a-z-]{3,}$/.test(word)) return false;
  if (word.includes('--')) return false;
  if (!translation && !definition) return false;

  const tags = splitList(tag);
  const examTagged = tags.some((item) => ['gre', 'ielts', 'toefl'].includes(item));
  if (!examTagged) return false;

  // Keep the dictionary focused on exam vocabulary rather than very basic words.
  const tooBasic = new Set([
    'able', 'about', 'above', 'after', 'again', 'also', 'away', 'back',
    'because', 'been', 'before', 'being', 'below', 'between', 'both',
    'come', 'could', 'does', 'done', 'down', 'each', 'even', 'ever',
    'every', 'from', 'have', 'here', 'into', 'just', 'like', 'make',
    'many', 'more', 'most', 'much', 'must', 'only', 'other', 'over',
    'same', 'some', 'such', 'than', 'that', 'their', 'them', 'then',
    'there', 'these', 'they', 'this', 'those', 'through', 'time',
    'under', 'very', 'were', 'what', 'when', 'where', 'which', 'with',
    'would', 'your',
  ]);
  return !tooBasic.has(word);
}

const text = fs.readFileSync(source, 'utf8');
const rows = parseCsv(text);
const header = rows.shift();
const indexes = Object.fromEntries(header.map((name, index) => [name, index]));

const entries = {};
const sourceCounts = { gre: 0, ielts: 0, toefl: 0 };

for (const row of rows) {
  const word = (row[indexes.word] || '').trim().toLowerCase();
  const phonetic = (row[indexes.phonetic] || '').trim();
  const definition = cleanDefinition(row[indexes.definition] || '');
  const translation = cleanTranslation(row[indexes.translation] || '');
  const pos = (row[indexes.pos] || '').trim();
  const tag = (row[indexes.tag] || '').trim().toLowerCase();
  const tags = splitList(tag).filter((item) => ['gre', 'ielts', 'toefl'].includes(item));

  if (!isUsefulExamWord(word, tag, translation, definition)) continue;

  for (const item of tags) {
    sourceCounts[item] += 1;
  }

  entries[word] = {
    word,
    phonetic,
    chineseMeaning: translation,
    englishMeaning: definition || 'No English definition in local dictionary.',
    partOfSpeech: pos,
    tags,
  };
}

fs.writeFileSync(output, JSON.stringify(entries, null, 2), 'utf8');
fs.writeFileSync(
  metaOutput,
  JSON.stringify(
    {
      source: 'ECDICT',
      sourceUrl: 'https://github.com/skywind3000/ECDICT',
      generatedAt: new Date().toISOString(),
      entryCount: Object.keys(entries).length,
      sourceCounts,
      fields: ['word', 'phonetic', 'chineseMeaning', 'englishMeaning', 'partOfSpeech', 'tags'],
    },
    null,
    2,
  ),
  'utf8',
);

console.log(`Wrote ${Object.keys(entries).length} entries to ${output}`);
