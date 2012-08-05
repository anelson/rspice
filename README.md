# rspice

rspice is a Ruby wrapper around CSPICE, NASA JPL's cross-platform library for various astronomical calculations, including ephemerides calculations based
on the JPL's ephermeride files.

## Installation

Add this line to your application's Gemfile:

    gem 'rspice'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rspice

## Usage

rspice is intended for use with the various JPL ephemerides.  The test folder contains a short-term DE405 planetary ephemeris file as well as supplementary files
for defining the planetary constants like mass and ellipsoid, and reference frames for the moon and the earth.  These files are included in the distribution
entirely for test purposes; rspice should be compatible with any JPL kernel which cspice itself works with.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
