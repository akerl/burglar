burglar
=========

[![Gem Version](https://img.shields.io/gem/v/burglar.svg)](https://rubygems.org/gems/burglar)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/akerl/burglar/build.yml?branch=main)](https://github.com/akerl/burglar/actions)
[![MIT Licensed](https://img.shields.io/badge/license-MIT-green.svg)](https://tldrlegal.com/license/mit-license)

Tool for parsing data from bank websites into the format of [ledger](http://ledger-cli.org/)

## Usage

Burglar operates on the concept of `modules` for each bank's site. The module does the heavy lifting to hit the API or scrape the site for data.

### Running burglar

Burglar supports a couple of command line flags, each with a sane default:

```
   -c FILE, --config FILE  Config file to load
   -b DATE, --begin DATE   Beginning of date range
   -e DATE, --end DATE     End of date range
```

The config file will default to `~/.burglar.yml`, begin defaults to 30 days ago, and end defaults to today.

### Configuration file

Here's an initial example, which should be mostly self explanatory.

```
banks:
  amex:
    type: american_express
    user: akerl
    account: Liabilities:Credit:amex
```

The banks object is a hash of named hashes, each one is an account that will be polled. Each account *must* have a `type`, which is the name of the module to use. You can also pass an `account`, which sets the account name for the ledger output (if not set, modules can attempt to provide a default). Other configuration depends on the module.

### Modules

#### American Express

This pulls from the American Express site by scraping a CSV.

Configuration:

* [required] user: your American Express username

#### Ally

This pulls from the Ally site by scraping a CSV.

* [required] user: your Ally username
* [required] name: the nickname of the specific account

### Helpers

Helpers exist to centralize common activity that modules can rely on.

#### Creds

This uses [keylime](https://github.com/akerl/keylime) to pull creds from an OSX keychain

#### Ledger

This helps convert transactions into ledger entries using [libledger](https://github.com/akerl/libledger)

#### Mechanize

This provides a [Mechanize](https://github.com/sparklemotion/mechanize) client for modules that want to scrape the bank website

## Installation

    gem install burglar

## License

burglar is released under the MIT License. See the bundled LICENSE file for details.

