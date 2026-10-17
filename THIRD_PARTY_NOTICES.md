# Third-party notices

This file records bundled software and font licenses currently identified in the repository. It is a source-tree notice; release packaging must place it beside desktop builds or otherwise make it available to players. This is a partial inventory, not release clearance: the archived Godot 4.7.2 engine list has not been compared with the actual export template, and the final asset/audio provenance review remains open.

## Godot Engine 4.7.2

This game uses the Godot Engine, available under the MIT license.

Copyright (c) 2014-present Godot Engine contributors.
Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

The official Godot 4.7.2 runtime binary's `Engine.get_copyright_info()` and `Engine.get_license_info()` outputs are archived as [`godot-4.7.2-copyright-info.json`](docs/release/licenses/godot-4.7.2-copyright-info.json) and [`godot-4.7.2-license-info.json`](docs/release/licenses/godot-4.7.2-license-info.json). They list 102 components and 19 license texts. The export templates are not installed in this workspace, so this archive is not claimed as an exact-template verification. For release, compare it with, or regenerate it using, the actual export template: [Godot license guidance](https://godotengine.org/license) and [official license-compliance documentation](https://docs.godotengine.org/en/stable/about/complying_with_licenses.html).

## godot-cpp

The native extension is built against `godot-cpp` commit `b8530af7546a3fcae80cef2477526569fd42ffc2`, licensed under MIT. The project pins this revision in `CMakeLists.txt`.

Copyright (c) 2017-present Godot Engine contributors.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Fonts

- **Press Start 2P** — SIL Open Font License 1.1; copyright 2012 The Press Start 2P Project Authors, with Reserved Font Name "Press Start 2P". The full license is in [`game/assets/fonts/PRESS-START-2P-OFL.txt`](game/assets/fonts/PRESS-START-2P-OFL.txt).
- **DejaVu Sans** — Bitstream Vera license, with DejaVu changes in the public domain. The full copyright and license notice is in [`game/assets/fonts/DEJAVU-LICENSE.txt`](game/assets/fonts/DEJAVU-LICENSE.txt).

## Game assets

The art inventory describes the current sprite, icon, and UI assets and their editable sources in [`docs/art/INVENTAIRE_ASSETS_UI.md`](docs/art/INVENTAIRE_ASSETS_UI.md). That inventory is not a substitute for a final provenance review of every release asset. Audio assets are not audited by this file; merge their owner's notice and provenance record before release.
