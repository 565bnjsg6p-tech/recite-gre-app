# Local Dictionary

The web MVP includes a local exam dictionary generated from ECDICT:

- Source: https://github.com/skywind3000/ECDICT
- License copy: `assets/dictionaries/ECDICT_LICENSE.txt`
- Generated asset: `assets/dictionaries/exam_basic.json`
- Metadata: `assets/dictionaries/exam_basic_meta.json`

The generator is `tool/build_dictionary.js`.

To rebuild after updating `tool/ecdict.csv`:

```powershell
node tool\build_dictionary.js
```

The current filter keeps words tagged as `gre`, `ielts`, or `toefl`, removes a
small list of very basic words, and writes compact fields used by the app:

- word
- phonetic
- chineseMeaning
- englishMeaning
- partOfSpeech
- tags

Future dictionary sources can be added by producing the same JSON shape.
