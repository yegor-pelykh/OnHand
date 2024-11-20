const path = require('path');

module.exports = {
  entry: ['./src-service-worker/service-worker.ts'],
  devtool: false,
  module: {
    rules: [
      {
        test: /\.ts?$/,
        loader: 'ts-loader',
        exclude: /node_modules/,
        options: {
          configFile: 'tsconfig.json',
        },
      },
    ],
  },
  resolve: {
    extensions: ['.tsx', '.ts', '.js'],
    extensionAlias: {
      '.js': ['.js', '.ts'],
      '.cjs': ['.cjs', '.cts'],
      '.mjs': ['.mjs', '.mts'],
    },
  },
  output: {
    filename: 'service-worker.js',
    path: path.resolve(__dirname, '../web'),
  },
  performance: {
    maxAssetSize: 1000000,
    maxEntrypointSize: 1000000,
  },
};
