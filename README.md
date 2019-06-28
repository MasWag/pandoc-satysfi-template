pandoc-satysfi-template
=======================

[![wercker status](https://app.wercker.com/status/408e4e794596f9cc8b2858e2d52a3594/s/master "wercker status")](https://app.wercker.com/project/byKey/408e4e794596f9cc8b2858e2d52a3594)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](./LICENSE)

A pandoc custom writer and template for [SATySFi](https://github.com/gfngfn/SATySFi). You can convert any files supported by pandoc to SATySFi or PDF. You can generate the SATySFi and PDF versions of this README by `make` in the root directory.

Remark
======

This pandoc writer is *incomplete* i.e., it is unimplemented for some elements. Your contribution is **highly appreciated!!**

Requirements
============

* pandoc
* SATySFi

Options
=======

You can use the following options by giving `-V <option_name>` to pandoc

show-title
: If `-V show-title` is given, satysfi generates the title.

toc
: If `-V toc` is given, satysfi generates the TOC (table of contents).

Note
====

The template file `template.satysfi` is for a `.saty` file not for a `.satyh` file. If you want to convert to a `.satyh` file, you need to write a template by yourself. It is easy.

Example
=======

```bash
    pandoc -t ./satysfi.lua --template ./template.satysfi -s README.md -o README.saty -V show-title
```
