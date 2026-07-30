---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.mjs"
  - "**/package.json"
  - "**/tsconfig.json"
---

# Node Development

## Package Manager

npm is the only package manager. Never use pnpm, yarn, or bun. Commit `package-lock.json`.

Use `npm ci` in CI and containers. Use `npm install` only when changing dependencies.

## Language

TypeScript by default. New projects are TypeScript with `strict: true`. Plain JavaScript only when a project already has no TypeScript.

ESM only. Set `"type": "module"` in `package.json`. Never `require()` in new code.

## Project Structure

```text
<project-name>/
├── package.json
├── package-lock.json
├── tsconfig.json
├── .nvmrc
├── src/
│   ├── index.ts
│   └── ...
└── tests/
    └── ...
```

Never write loose scripts in the project root. Build output goes to `dist/` and is gitignored.

## package.json Template

```json
{
  "name": "<package-name>",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "test": "vitest run",
    "test:watch": "vitest",
    "lint": "eslint .",
    "format": "prettier --write ."
  }
}
```

## tsconfig.json Template

Set `target` to match the Node version pinned in `.nvmrc`.

```json
{
  "compilerOptions": {
    "module": "nodenext",
    "moduleResolution": "nodenext",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "rootDir": "src",
    "outDir": "dist",
    "declaration": true,
    "sourceMap": true
  },
  "include": ["src"]
}
```

## Node Version

Pin with `.nvmrc` at the project root. Match it with an `engines.node` range in `package.json`.

## Testing

vitest is the test runner. Tests live in `tests/` or beside the source as `*.test.ts`.

```bash
npm test                 # single run
npm run test:watch       # watch mode
npx vitest run --coverage
```

Never use jest or mocha in new projects.

## Linting and Formatting

```bash
npx eslint .             # lint
npx prettier --write .   # format
```

ESLint config is flat config in `eslint.config.js`. Never `.eslintrc*`.

## Style

- Named exports. Default exports only when a framework requires one
- `const` by default, `let` when reassigned, never `var`
- No `any`. Use `unknown` and narrow
- Async/await over raw promise chains
- Node builtins use the `node:` prefix: `import { readFile } from "node:fs/promises"`
