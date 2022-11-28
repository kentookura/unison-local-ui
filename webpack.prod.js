const path = require("path");
const HtmlWebpackPlugin = require("html-webpack-plugin");
const FileManagerPlugin = require("filemanager-webpack-plugin");
const postcssPresetEnv = require("postcss-preset-env");
const FaviconsWebpackPlugin = require("favicons-webpack-plugin");

const UI_CORE_SRC = "elm-stuff/gitdeps/github.com/kentookura/ui-core/src";

const unisonLocalCfg = {
  module: {
    rules: [
      {
        test: /\.css$/i,
        use: [
          "style-loader",
          {
            loader: "css-loader",
            options: { importLoaders: 1 },
          },
          {
            loader: "postcss-loader",
            options: {
              postcssOptions: {
                plugins: [
                  postcssPresetEnv({
                    features: {
                      "is-pseudo-class": false,
                      "custom-media-queries": {
                        importFrom: `${UI_CORE_SRC}/css/ui/viewport.css`,
                      },
                    },
                  }),
                ],
              },
            },
          },
        ],
      },
      {
        test: /\.(png|svg|jpg|jpeg|gif)$/i,
        type: "asset/resource",
      },
      {
        test: /\.(woff(2)?|ttf|eot)$/i,
        type: "asset/resource",
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        use: [
          {
            loader: "elm-asset-webpack-loader",
          },
          {
            loader: "elm-webpack-loader",
            options: {
              debug: false,
              cwd: __dirname,
            },
          },
        ],
      },
    ],
  },
  resolve: {
    alias: {
      assets: path.resolve(__dirname, "src/assets/"),
      "ui-core": path.resolve(__dirname, UI_CORE_SRC + "/"),
    },
  },

  entry: "./src/unisonLocal.js",

  plugins: [
    new HtmlWebpackPlugin({
      template: "./src/unisonLocal.ejs",
      inject: "body",
      publicPath: "/static/",
      base: false, // set dynamically by grabbing the 2 first path segments in the url.
      filename: path.resolve(__dirname, "dist/unisonLocal/index.html"),
    }),

    new FaviconsWebpackPlugin({
      logo: "./src/assets/favicon.svg",
      inject: true,
      favicons: {
        appName: "Unison Local",
        appDescription: "Explore, read docs about, and share Unison libraries",
        developerName: "Unison",
        developerURL: "https://unison-lang.org",
        background: "#FF9BA3",
        theme_color: "#FF9BA3",
      },
    }),

    new FileManagerPlugin({
      events: {
        onEnd: {
          archive: [
            { source: "dist/unisonLocal", destination: "dist/unisonLocal.zip" },
          ],
        },
      },
    }),
  ],

  output: {
    filename: "[name].[contenthash].js",
    path: path.resolve(__dirname, "dist/unisonLocal/static"),
    clean: true,
  },
};

module.exports = unisonLocalCfg;
