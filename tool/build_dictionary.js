const fs = require('fs');
const path = require('path');

const source = path.join(__dirname, 'ecdict.csv');
const supplementalSource = path.join(__dirname, 'supplemental_dictionary.json');
const output = path.join(__dirname, '..', 'assets', 'dictionaries', 'exam_basic.json');
const metaOutput = path.join(__dirname, '..', 'assets', 'dictionaries', 'exam_basic_meta.json');
const supportedTags = ['gre', 'ielts', 'toefl', 'cet4', 'cet6', 'life', 'economics', 'math'];

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
  const examTagged = tags.some((item) =>
    ['gre', 'ielts', 'toefl', 'cet4', 'cet6'].includes(item)
  );
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

function upsertEntry(entry) {
  const word = (entry.word || '').trim().toLowerCase();
  if (!word) return;
  const tags = (entry.tags || [])
    .map((item) => item.toString().trim().toLowerCase())
    .filter((item) => supportedTags.includes(item));
  if (tags.length === 0) return;

  const existing = entries[word];
  if (existing) {
    entries[word] = {
      word,
      phonetic: entry.phonetic || existing.phonetic,
      chineseMeaning: entry.chineseMeaning || existing.chineseMeaning,
      englishMeaning: entry.englishMeaning || existing.englishMeaning,
      partOfSpeech: entry.partOfSpeech || existing.partOfSpeech,
      tags: Array.from(new Set([...existing.tags, ...tags])),
    };
    return;
  }

  entries[word] = {
    word,
    phonetic: entry.phonetic || '',
    chineseMeaning: entry.chineseMeaning || '',
    englishMeaning: entry.englishMeaning || 'No English definition in local dictionary.',
    partOfSpeech: entry.partOfSpeech || '',
    tags: Array.from(new Set(tags)),
  };
}

for (const row of rows) {
  const word = (row[indexes.word] || '').trim().toLowerCase();
  const phonetic = (row[indexes.phonetic] || '').trim();
  const definition = cleanDefinition(row[indexes.definition] || '');
  const translation = cleanTranslation(row[indexes.translation] || '');
  const pos = (row[indexes.pos] || '').trim();
  const tag = (row[indexes.tag] || '').trim().toLowerCase();
  const tags = splitList(tag).filter((item) => supportedTags.includes(item));

  if (!isUsefulExamWord(word, tag, translation, definition)) continue;

  upsertEntry({
    word,
    phonetic,
    chineseMeaning: translation,
    englishMeaning: definition || 'No English definition in local dictionary.',
    partOfSpeech: pos,
    tags,
  });
}

if (fs.existsSync(supplementalSource)) {
  const supplementalEntries = JSON.parse(fs.readFileSync(supplementalSource, 'utf8'));
  for (const entry of supplementalEntries) {
    upsertEntry(entry);
  }
}

const sourceCounts = Object.fromEntries(supportedTags.map((tag) => [tag, 0]));
for (const entry of Object.values(entries)) {
  for (const tag of entry.tags) {
    sourceCounts[tag] += 1;
  }
}

fs.writeFileSync(output, JSON.stringify(entries, null, 2), 'utf8');
fs.writeFileSync(
  metaOutput,
  JSON.stringify(
    {
      source: 'ECDICT + supplemental professional dictionary',
      sourceUrl: 'https://github.com/skywind3000/ECDICT',
      supplementalSource: 'tool/supplemental_dictionary.json',
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
