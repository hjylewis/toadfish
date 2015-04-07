## YO!
This is adapted from the [less middleware](https://npmjs.org/package/less-middleware) written by [zoramite](https://npmjs.org/~zoramite)
We have removed LESS specific, replaced it with the coffee-script equivalent, removed dependance on static files, and added inline sourcemaps.

## Installation

    npm install coffee-middleware

## Options

<table>
    <thead>
        <tr>
            <th>Option</th>
            <th>Description</th>
            <th>Default</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th><code>force</code></th>
            <td>Always re-compile coffee-script files on each request.</td>
            <td><code>false</code></td>
        </tr>
        <tr>
            <th><code>once</code></th>
            <td>Only check for need to recompile once after each server restart. Useful for reducing disk i/o on production.</td>
            <td><code>false</code></td>
        </tr>
        <tr>
            <th><code>debug</code></th>
            <td>Output any debugging messages to the console.</td>
            <td><code>false</code></td>
        </tr>
        <tr>
            <th><code>bare</code></th>
            <td>Compile the JavaScript without the top-level function safety wrapper.</td>
            <td><code>false</code></td>
        </tr>
        <tr>
            <th><code>src</code></th>
            <td>Source directory containing the <code>.coffee</code> files. <strong>Required.</strong></td>
            <td></td>
        </tr>
        <tr>
            <th><code>encodeSrc</code></th>
            <td>Encode CoffeeScript source file as base64 comment in compiled JavaScript</td>
            <td><code>true</code></td>
        </tr>
        <tr>
            <th><code>prefix</code></th>
            <td>Path which should be stripped from the public <code>pathname</code>.</td>
            <td></td>
        </tr>
    </tbody>
</table>

## Examples

### Connect

    var coffeeMiddleware = require('coffee-middleware');

    var server = connect.createServer(
        coffeeMiddleware({
            src: __dirname + '/public',
            compress: true
        }),
    );

### Express

    var coffeeMiddleware = require('coffee-middleware');

    var app = express.createServer();

    app.configure(function () {
        // Other configuration here...

        app.use(coffeeMiddleware({
            src: __dirname + '/public',
            compress: true
        }));
    });
