# Local Dictionary

The web MVP includes a local exam dictionary generated from ECDICT, plus a
small supplemental professional dictionary for words that are easy to miss in
exam-only sources:

- Source: https://github.com/skywind3000/ECDICT
- License copy: `assets/dictionaries/ECDICT_LICENSE.txt`
- Generated asset: `assets/dictionaries/exam_basic.json`
- Metadata: `assets/dictionaries/exam_basic_meta.json`
- Supplemental source: `tool/supplemental_dictionary.json`

The generator is `tool/build_dictionary.js`.

To rebuild after updating `tool/ecdict.csv` or the supplemental JSON:

```powershell
node tool\build_dictionary.js
```

The current ECDICT filter keeps words tagged as `gre`, `ielts`, `toefl`,
`cet4`, or `cet6`, removes a small list of very basic words, then merges
supplemental entries tagged as `life`, `economics`, or `math`.

The app currently exposes word books for GRE, IELTS, TOEFL, CET4, CET6, life
English, and economics. Math terms are available for local completion and can
be turned into a word book later by adding a `math` entry to
`lib/src/data/word_book_catalog.dart`.

The compact fields used by the app are:

- word
- phonetic
- chineseMeaning
- englishMeaning
- partOfSpeech
- tags

Future dictionary sources can be added by producing the same JSON shape.
