# gitwalk: Bulk processing of git repos


## Features

## Installation

```bash
$ npm install -g gitwalk
```

## Usage

```bash
$ gitwalk 'github:pazdera/tco' grep TODO
```

## Expressions

### GitHub

### Glob

### URL

### Groups

## Processors

### grep

### files

### commits

### command

## Configuration

## Javascript API

```js
var gitwalk = require('gitwalk');

gitwalk('github:pazdera/\*', gitwalk.proc.grep(/TODO/, '*.js'), function (err) {
    if (err) {
        console.log 'gitwalk failed (' + err + ')';
    }
});
```

## Contributing

## Credits

Radek Pazdera &lt;me@radek.io&gt;

## Licence

Please see [LICENCE](https://github.com/pazdera/gitwalk/blob/master/LICENCE).
