# libspatialite-ios

A Makefile for automatically downloading and compiling
[libspatialite](https://www.gaia-gis.it/fossil/libspatialite/index) (including
its dependencies [SQLite](http://sqlite.org/index.html),
[GEOS](http://trac.osgeo.org/geos/) and [PROJ.4](https://trac.osgeo.org/proj/))
statically for iOS.

The resulting library is a "fat" library suitable for multiple architectures.
This includes:

- armv7 (iOS)
- armv7s (iOS)
- arm64 (iOS)
- i386 (iOS Simulator)
- x86_64 (iOS Simulator)

## Requirements

Xcode 12.1 with Command Line Tools installed. The following compiled
dependencies can be installed with Homebrew:

```sh
brew install automake autoconf libtool libxml2 pkg-config
brew link libxml2
```

## Installation

Simply run

```
make
```

## Usage

- Copy the contents of `lib` and the `include` directory to your Xcode project
  directory. You should end up with something like the following:

```
lib/
└── libspatialite
    ├── include
    │   ├── geodesic.h
    │   ├── geos
    │   │   ├── (many more files in geos)
    │   ├── geos.h
    │   ├── geos_c.h
    │   ├── org_proj4_PJ.h
    │   ├── org_proj4_Projections.h
    │   ├── proj_api.h
    │   ├── projects.h
    │   ├── spatialite
    │   └── spatialite.h
    ├── libgeos.a
    ├── libgeos_c.a
    ├── libproj.a
    ├── libspatialite.a
    └── mod_spatialite.a
```

- Then, drag the contents from Finder into the project navigator to incldue them
  in your project. Xcode should automatically add the library files to the
  "Build Phases" window. If not, add them later when you add the other required
  libraries.

- Add these to the search paths in your Xcode project's "Build Settings":

  - Library Search Paths: \$(PROJECT_DIR)/AppName/lib/libspatialite
  - Header Search Paths: \$(PROJECT_DIR)/AppName/lib/libspatialite/include

- And in the "Build Phases" window, add the following to the section "Link
  Binary With Libraries":

  - libiconv
  - libcharset.1.0.0
  - libc++
  - libxml2.2
  - libz

- Lastly, if your project is written in Swift, include the headers in your
  bridging header:

```swift
//
//  bridging.h
//

#include <sqlite3.h>
#include <spatialite/gaiageo.h>
#include <spatialite.h>
```

- Now you should be able to use Spatialite:

```swift
spatialite_init(0);
print(spatialite_version()!)
```

## Acknowledgements

Thanks to [gstf](https://github.com/gstf) for providing the original repository
this is forked from (https://github.com/gstf/libspatialite-ios), as well as
[davenquinn](https://github.com/davenquinn) and
[smellman](https://github.com/smellman) for their forks making it possible to
build for newer versions. Thanks to [aaronpk](https://github.com/aaronpk) for
the instructions on how to use this in an iOS project
(https://gist.github.com/aaronpk/0252426d5161bc9650d8). This is heavily adapted
from all of their work.
