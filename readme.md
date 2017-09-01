# RADIUS 

### Really, Another Developer Indentation Utility Software?

Basic useful feature list:

 * Indents Assembly source files
 * Supports the idea of set columns that get pushed or bumped to the right
 * Balances consistency with sanity for spacing rule

This is a really quickly thrown together indenter for Merlin32 assembly files (but really all Merlin files and many other formats of 6502 code).  I currently use CADIUS, a really much more impressive tool that supports indentation as one feature, but it doesn't let me set my own column widths so I've decided to make my own software to address this.

Currently, the options allow you to set a column 0, 1 and 2.  Those represent the Opcode, Operand and Comment columns respectively. 

## Usage
```
radius.rb [-h] [-c0 nn] [-c1 nn] [-c2 nn] filename.

  -h  : help
  -c0 : column 0 indent (start of opcode column)
  -c1 : column 1 indent (start of operand column)
  -c2 : column 2 indent (start of comment column)
  -s  : redirect to standard out only (default overwrites source file)
```
