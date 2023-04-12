# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 6.0.1 (2023-03-14)
* Increment waiting times when rate-limited.
* Add option to avoid SSL verification in the slack websocket connection.

## 6.0.0 (2023-01-19)
* Use linear backoff when rate-limited. 

## 5.0.0 (2023-01-17)
* Non-paginated API calls obey Slack rate-limit rules, waiting when the HTTP status code is 429.
* users.list API call is now paginated.
* Paginated API calls limit has been increased 500 by default (100-200 is the recommended value and 1000 is the maximum value).

## 4.0.0 (2022-12-30)
* Upgrade dependencies: lita >= 4.8.
* Ignore .idea folder in .gitignore.

## 3.0.0 (2022-11-22)

* Sentry integration for API error responses.

## 2.1.1 (2022-08-28)

* Replaces deprecated rtm.start with rtm.connect

## 2.1.0 (2022-06-23)

Flywire fork

* fixes im.open API deprecation 


