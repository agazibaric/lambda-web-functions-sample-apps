// Web Function bundle: src/index.ts -> dist/index.js, one minified ESM file, no node_modules.
export default {
  input: 'src/index.ts',
  platform: 'node',
  treeshake: true,
  transform: {
    target: 'node24',
  },
  resolve: {
    // Sources import './common.js' (NodeNext style); the file on disk is common.ts.
    extensionAlias: { '.js': ['.ts', '.js'] },
  },
  output: {
    dir: 'dist',
    format: 'esm',
    // The runtime runs index.js at the zip root.
    entryFileNames: 'index.js',
    codeSplitting: false,
    minify: true,
    keepNames: true,
    sourcemap: false,
  },
}
