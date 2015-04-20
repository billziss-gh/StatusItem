# StatusItem #

A simple command line utility to manage status items on the Mac's menu bar.

## Examples ##

The following commands:
```
$ StatusItem virtualbox /Applications/VirtualBox.app/Contents/Resources/virtualbox-vbox.icns
$ StatusItem green :NSStatusAvailable
$ StatusItem yellow :NSStatusPartiallyAvailable
$ StatusItem red :NSStatusUnavailable
```

Will result in the following status bar:
![Menu Bar](https://bytebucket.org/billziss/statusitem/raw/2d2b8b0e14006762bb8a234ad521bfbf36636efd/MenuBar.png)

To list all status items:
```
$ StatusItem -l
green
red
virtualbox
yellow
```

To remove all status items:
```
$ StatusItem green
$ StatusItem red
$ StatusItem virtualbox
$ StatusItem yellow
```

## Usage ##

Create/modify a status item with name NAME:
```
$ StatusItem NAME /PATH/TO/ICON.icns
```

Create/modify a status item with an icon and some message text in its menu:
```
$ StatusItem -m "MESSAGE TEXT" NAME /PATH/TO/ANOTHER/ICON.png
```

Create/modify a status item with an icon, some message text and a "Remove" option in its menu:
```
$ StatusItem -r -m "MESSAGE TEXT" NAME /PATH/TO/ANOTHER/ICON.png
```

Create/modify a status item with an icon set to a system image. Names are derived from constants
used with `[NSImage imageNamed:]`:
```
$ StatusItem NAME :SYSTEMIMAGE
```

Remove a status item with name NAME:
```
$ StatusItem NAME
```

List all current status items:
```
$ StatusItem -l
```

## Building on OS X ##

Simply execute the following command:
```
$ sh ./StatusItem.m -o StatusItem
```

This will execute the proper `clang` command and will create the executable `StatusItem`.

## License (BSD 3-Clause) ##

Copyright (c) 2015 Bill Zissimopoulos. All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation 
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors 
may be used to endorse or promote products derived from this software without 
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE 
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR 
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE 
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.