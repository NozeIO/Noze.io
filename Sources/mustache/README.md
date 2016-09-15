# Mustache

A simple Mustache parser/evaluator for Swift.

[Mustache](http://mustache.github.io) is a very simple templating language.
Implementations are available for pretty much any programming language
(check the [Mustache](http://mustache.github.io) website) - this is one for
Swift.

In the context of Noze.io you don't need to call this manually,
but you can just use the Mustache template support in the
Noze.io [Express](../express) module.
Checkout the [express-simple](../../Samples/express-simple) app as an example
on how to do this.

This Mustache implementation comes with a very simple Key-Value coding
implementation, which is used to extract values from model objects for
rendering.
With that you can render both, generic Dictionary/Array structures as well
as Swift objects with properties.
Since the reflection capabilities of Swift are pretty limited, so is the
KVC implementation.

## Example

Sample Mustache:

    Hello {{name}}
    You have just won {{& value}} dollars!
    {{#in_ca}}
      Well, {{{taxed_value}}} dollars, after taxes.
    {{/in_ca}}
    {{#addresses}}
      Has address in: {{city}}
    {{/addresses}}
    {{^addresses}}
      Has NO addresses
    {{/addresses}}

The template features value access: `{{name}}`,
conditionals: `{{#in_ca}}`,
as well as repetitions: `{{#addresses}}`.

Sample code to parse and evaluate the template:

    let sampleDict  : [ String : Any ] = [
      "name"        : "Chris",
      "value"       : 10000,
      "taxed_value" : Int(10000 - (10000 * 0.4)),
      "in_ca"       : true,
      "addresses"   : [
        [ "city"    : "Cupertino" ]
      ]
    ]
    
    let parser = MustacheParser()
    let tree   = parser.parse(string: template)
    let result = tree.render(object: sampleDict)

You get the idea.
