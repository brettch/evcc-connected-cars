# EVCC Connected Cars

Provides [Connected Cars](https://connectedcars.io/) [API](https://connectedcars.io/api/) support for the [EVCC](https://evcc.io/) EV charge management software.

## Background

Connected Cars provides a solution for accessing and analysing data obtained from car fleets. It is an end to end solution that includes in-car hardware, central infrastructure and APIs for collecting and analysing data, and mobile applications for end users.

One of those clients of this solution is Volkswagen Australia who use it due to their standard MyVW solution not being available in Australia.

EVCC works best when it can access up-to-date car details including current state of charge (i.e. how full is the battery?).

EVCC doesn't (yet) support the Connected Cars API, so this repository contains a set of standalone scripts that can be invoked by EVCC to obtain this car data.

## Pre-requisites

You will need the following Connected Cars details before proceeding:

* Username: This is an email address that you probably already use to authenticate via a mobile app.
* Password: Hopefully self explanatory
* Instance domain: Connected Cars has different instances in different geographical regions. The "standard" instance APIs are within the `connectedcars.io` domain. The Australian instance APIs are within the `au1.connectedcars.io` domain.
* Organisation namespace: Each client has a unique namespace that is selected via a `x-organization-namespace` request header. Volkswagen Australia uses the `vwaustralia:app` namespace.

## Setup

Copy all files in this repository to a location of your choice accessible by EVCC.

Run `configure.sh` and provide the following arguments (it will prompt for password):
* Instance domain
* Organisation namespace
* Username

This script will perform the following steps:
* Remove any existing devices named "evcc" registered to your Connected Cars user.
* Create a new device named "evcc" against your Connected Cars user.
* Create a data directory.
* Create a `config.json` with all parameters and tokens required by the scripts.

Test the configuration by running the various `get-*` scripts. You may also run `refresh-data.sh` directly.

In `evcc.yaml` (or via the UI), configure your car as a `custom` vehicle. Configure the following fields to use a `script` source pointing at the relevant `get-*` script.

* soc (state of charge)
* range
* odometer

See below for an example vehicle configuration:

```
vehicles:
- type: custom
  name: id4
  title: Volkswagen ID.4
  capacity: 78
  soc:
    source: script
    cmd: /mypath/get-charge-percentage.sh
    timeout: 10s
#  status:
  range:
    source: script
    cmd: /mypath/get-range.sh
    timeout: 10s
  odometer:
    source: script
    cmd: /mypath/get-odometer.sh
    timeout: 10s
```

## Reference

See [Connected Cars API Documentation](https://docs.connectedcars.io/) for details on Connected Cars API and their usage.

The GraphQL API exposes the Graphiql UI which can be accessed via `https://api.connectedcars.io/graphql/graphiql/`. Use the "Connected Cars" tab on the left to authenticate which will then set the appropriate request headers for GraphQL requests.

In some cases API examples fail to include mandatory headers. These include `Content-Type` which is typically set to `application/json` and `Authorization` which is typically set to `Bearer <auth-token>`.
