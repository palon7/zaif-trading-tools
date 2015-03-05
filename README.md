# Zaif trading tools

## Installation

Require ruby and bundler.

```bash
bundler install
```

Copy "config.default.rb" to "config.rb".

## Usage
Please rename **config.default.rb** to **config.rb** and setup config before start using tools.

### stealth.rb

板を出さずに自動で注文を発注します。
```bash
./stealth.rb bid mona 15.4 100
./stealth.rb ask mona 12.4 115
```
