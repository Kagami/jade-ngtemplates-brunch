# jade-ngtemplates-brunch

Adds Jade AngularJS templates support to brunch.

Generally this means that Jade templates in specified directory will be compiled into AngularJS module(s) and available in angular application without additional HTTP requests with the help of [$templateCache](http://docs.angularjs.org/api/ng.$templateCache) factory. This could dramatically decrease number of HTTP requests browsers made.

## Usage

Install the plugin via npm with `npm install --save jade-ngtemplates-brunch`.

Or, do manual install:

* Add `"jade-ngtemplates-brunch": "x.y.z"` to `package.json` of your brunch app.
  Pick a plugin version that corresponds to your minor (y) brunch version.
* If you want to use git version of plugin, add
`"jade-ngtemplates-brunch": "git+https://github.com/Kagami/jade-ngtemplates-brunch.git"`.

Add standart `joinTo` declaration for the templates depending on your preferences:
```coffeescript
exports.config =
  ...
  files:
    templates:
      joinTo:
        "static/js/partials.js": /^app\//
```

## Brunch plugin settings

Plugin settings could be defined in the `plugins.jadeNgtemplates` section of the brunch config. Defaults are:

```coffeescript
exports.config =
  ...
  plugins:
    jadeNgtemplates:
      modules: [
        name: "partials"
        pattern: /^app[\/\\]/
        url: (path) ->
          path.replace /\\/g, "/"  # Convert Window-like paths to Unix-like
          "/#{path}"
      ]
      jade:
        doctype: "html"
      htmlmin: false
```

### Modules

You could specify generated angular modules settings in the `modules` section *(Array)*. By default all files with `.jade` extension in `app/` directory will be compiled into single `partials` module with URLs (cache ID) like `/app/templates/1.jade`.

Module description is an *Object* which consists of:

* **name**: *(String)* Name of the angular module which will contain generated templates. Default is `partials`.
* **pattern**: *(RegExp)*. Pattern used to match source files names. Default is `/^app[\/\\]/`.
* **url**: *(Function)* Takes path of the source file and returns URL (cache ID) where template will be available. See above for the default value.

Note that all omitted options in module object description will be filled up with defaults.

Example:
```coffeescript
exports.config =
  ...
  plugins:
    jadeNgtemplates:
      modules: [
        name: "partials.auth"
        pattern: /^app\/auth\//
        url: (path) ->
          path.replace /^app\/auth\/(.*)\.jade$/, "/partials/$1.html"
      ,
        name: "partials.admin"
        pattern: /^app\/admin\//
        url: (path) ->
          path.replace /^app\/admin\/(.*)\.jade$/, "/partials/$1.html"
      ]
```

You may need to edit `files.templates.joinTo` brunch option accordingly.

### Jade options

You could specify Jade options and template locals in the `jade` and `jade.locals` sections accordingly. Example:
```coffeescript
exports.config =
  ...
  plugins:
    jadeNgtemplates:
      jade:
        doctype: "xml"
        pretty: true
        locals:
          varname: "123"
```

Note that in optimize mode `pretty` option is always disabled.

### HTML minification

You could minify compiled templates using [html-minifier](https://github.com/kangax/html-minifier) by passing following values to the `htmlmin` section:

* Enable with default options with `true`. Default options are:
```coffeescript
removeComments: true
removeCommentsFromCDATA: true
removeCDATASectionsFromCDATA: true
collapseBooleanAttributes: true
useShortDoctype: true
removeEmptyAttributes: true
removeScriptTypeAttributes: true
removeStyleLinkTypeAttributes: true
```

* Specify custom options by passing *Object*; see options description [here](http://perfectionkills.com/experimenting-with-html-minifier/#options).

Note that by default HTML minification is disabled and could be enabled only for optimize mode. Also beware that minification especially with agressive options enabled could broke things.

Example:
```coffeescript
exports.config =
  ...
  plugins:
    jadeNgtemplates:
      htmlmin:
        removeComments: true
        collapseWhitespace: true
        removeEmptyAttributes: true
```

## See also

If you have static Jade pages which you want to compile with Brunch as well it's recommended to use [jade-pages-brunch](https://github.com/Kagami/jade-pages-brunch) plugin.

## License

jade-ngtemplates-brunch - Adds Jade AngularJS templates support to brunch

Written in 2014 by Kagami Hiiragi <kagami@genshiken.org>

To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to this software to the public domain worldwide. This software is distributed without any warranty.

You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
