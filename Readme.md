## FindMethodsWhichMessageSelector-ObjectiveC
Introduce a script which allows a developer to identify all of the methods in the specified library L which message a specified selector S.  

# Usage
```
./FindMethodsWhichMessageSelector-MacOSX-i386.pl /Path/To/Library selectorName
```

# Example
```
./FindMethodsWhichMessageSelector-MacOSX-i386.pl /System/Library/Frameworks/AppKit.framework/AppKit "addFontTrait:"

Selector "addFontTrait:" implementation found at:
  00c7febc  __TEXT:__cstring:addFontTrait:

Selector "addFontTrait:" appears to be called from the following methods:
  -[NSFontManager fontMenu:]:
  -[NSFontManager modifyFontTrait:]:
```

# Notes
Note that this uses heuristics to determine if the S is called from a method M.  Furthermore, it only works for i386 libraries at the moment.
