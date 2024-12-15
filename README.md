# unpub_sqlite

A package implementing a unpub's `MetaStore` for storing package metadata in a local SQLite database.

## Motivation

[Unpub](https://github.com/bytedance/unpub) is a decent solution for self-hosting a Dart package repository. However, it has a forced dependency on MongoDB, which can be an obstacle for those who prefer not to run additional services. Since Unpub already supports storing packages on the filesystem, replacing MongoDB with SQLite was a no-brainer to make Unpub more lightweight and without dependencies on other services (which are much more heavy than the unpub itself).

## Features and Missing Features

- ✅ Automatically initializes a new SQLite database
- ❌ Migrations between versions of SQLite databases
- ✅ Stores packages and their versions
- ✅ Stores uploaders
- ✅ Querying packages by keyword
- ❌ Querying packages by uploader
- ❌ Querying packages by dependency
- ❌ Any test coverage
- ❌ Security toughening – exceptions leaking over HTTP responses, etc.

## Disclaimer

The Unpub project itself is currently completely abandoned (last update 2021), and this package is likely to share the same fate. This package was created to fulfill personal requirements, and some features may be incomplete or missing.

You're welcome to open issues, but please don't expect them to be resolved promptly or at all. Contributions via pull requests are highly encouraged, it’s just a single-file package after all!

## Resources

- [Unpub Repository](https://github.com/bytedance/unpub)
- [SQLite](https://sqlite.org/index.html)
