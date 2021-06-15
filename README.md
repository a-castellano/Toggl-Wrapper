# Toggl-Wrapper

[![pipeline status](https://git.windmaker.net/a-castellano/Toggl-Wrapper/badges/master/pipeline.svg)](https://git.windmaker.net/a-castellano/Toggl-Wrapper/-/commits/master)[![coverage report](https://git.windmaker.net/a-castellano/Toggl-Wrapper/badges/master/coverage.svg)](https://git.windmaker.net/a-castellano/Toggl-Wrapper/-/commits/master)

## Synopsis
This module aims to intereact with toggl.com API. For the time being, this module allows users to authenticate using user/password pair or an API token instead.

## Dependencies

You should be able to download all the requeriments using cpanm.
Place yourself on the root of this project

```bash
cpanm --quiet --installdeps --notest .
```
Author recommends to install packages from Ubuntu mirrors instead of installing dependencies with cpanm.

```bash
apt-get install libdatetime-format-iso8601-perl libemail-abstract-perl libnet-http-perl libjson-types-perl libcpanel-json-xs-perl libio-all-lwp-perl libmoose-perl libmoosex-semiaffordanceaccessor-perl libmoosex-strictconstructor-perl libmoosex-types-common-perl libconfig-json-perl libjson-any-perl libjson-perl libdate-calc-perl libboolean-perl libmoosex-types-email-perl libjson-parse-perl
```

## Installation

To install this module, run the following commands:
```bash
perl Makefile.PL
make
make test -> optionally
make install
```

## Support and Documentation

After installing, you can find documentation for this module with the perldoc command:
```bash
perldoc Toggl::Wrapper
```
