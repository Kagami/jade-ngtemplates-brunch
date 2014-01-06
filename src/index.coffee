fs = require "fs"
_ = require "lodash"
jade = require "jade"
minify = require("html-minifier").minify

module.exports = class JadeNgtemplates
  brunchPlugin: true
  type: "template"
  extension: "jade"

  DEFAULT_MODULE_CONFIG:
    name: "partials"
    pattern: /^app[\/\\].*\.jade$/
    url: (path) ->
      path.replace /\\/g, "/"  # Convert Window-like paths to Unix-like
      "/#{path}"
  DEFAULT_JADE_OPTIONS:
    doctype: "html"
  DEFAULT_HTMLMIN_OPTIONS:
    removeComments: true
    removeCommentsFromCDATA: true
    removeCDATASectionsFromCDATA: true
    collapseWhitespace: true
    collapseBooleanAttributes: true
    removeAttributeQuotes: true
    removeRedundantAttributes: true
    useShortDoctype: true
    removeEmptyAttributes: true
    removeScriptTypeAttributes: true
    removeStyleLinkTypeAttributes: true

  constructor: (config) ->
    @optimize = config.optimize
    pluginConfig = config.plugins?.jadeNgtemplates
    modulesConfig = pluginConfig?.modules or [@DEFAULT_MODULE_CONFIG]
    @modulesConfig = modulesConfig.map (m) =>
      _.extend({}, @DEFAULT_MODULE_CONFIG, m)

    jadeConfig = _.extend({}, pluginConfig?.jade)
    @jadeLocals = jadeConfig.locals
    delete jadeConfig.locals
    @jadeOptions = _.extend(jadeConfig, @DEFAULT_JADE_OPTIONS)
    if @optimize
      # We don't want redundant whitespaces for product version, right?
      @jadeOptions.pretty = false

    # Disable html-minifier by default.
    @htmlmin = false
    if @optimize
      htmlminConfig = pluginConfig?.htmlmin
      if _.isBoolean(htmlminConfig)
        @htmlmin = htmlminConfig
        @htmlminOptions = @DEFAULT_HTMLMIN_OPTIONS
      else if _.isObject(htmlminConfig)
        @htmlmin = true
        @htmlminOptions = htmlminConfig

  findModuleConfig: (path) ->
    ###
    Return module config for the given file path.
    ###
    _.find @modulesConfig, (m) -> m.pattern.exec(path)

  wrapWithTemplateCache: (data, path) ->
    ###
    Wrap compiled template string with the angular templateCache
    directions.
    ###
    urlGenerator = @findModuleConfig(path).url
    url = urlGenerator(path)
    data = data.replace /'/g, "\\'"
    if @optimize
      "t.put('#{url}','#{data}');"
    else
      "\n  $templateCache.put('#{url}', '#{data}');"

  compile: (data, path, callback) ->
    # Compile single template.
    try
      templateFn = jade.compile(data, @jadeOptions)
      result = templateFn(@jadeLocals)
      if @htmlmin
        result = minify(result, @htmlminOptions)
      result = @wrapWithTemplateCache result, path
    catch err
      error = err
    finally
      callback error, result

  wrapWithModule: (data, module) ->
    ###
    Wrap compiled templates with the angular module definition.
    ###
    moduleName = module.name.replace /'/g, "\\'"
    if @optimize
      "angular.module('#{moduleName}',[])"+
      ".run(['$templateCache',function(t){#{data}}])"
    else
      """
      angular.module('#{moduleName}', []).run(function($templateCache) {
      #{data}
      });

      """

  onCompile: (generatedFiles) ->
    # When everything is compiled, add angular module wrapper around
    # templates.
    for generated in generatedFiles
      # XXX: Take only first source file for check against defined
      # modules config which may be not enough.
      continue unless generated.sourceFiles.length
      source = generated.sourceFiles[0]
      continue unless source.type is "template"
      module = @findModuleConfig(source.path)
      continue unless module?

      data = fs.readFileSync generated.path
      data = @wrapWithModule data, module
      fs.writeFileSync generated.path, data
