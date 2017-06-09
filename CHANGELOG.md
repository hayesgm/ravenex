# Changes to Ravenex

## 1.0.8

* Ensure client can use poison 3.x

## 1.0.6

* Ensure that Sentry gets the correct error level when passing errors via the logger backend

## 1.0.5

* Bug fix: If given DSN as {:system, "ENV_VAR"}, don't crash when "ENV_VAR" is not set

## 1.0.4

* Allow DSN to be set via {:system, "ENV_VAR"}

## 1.0.3

* Don't guess env from Mix.env
