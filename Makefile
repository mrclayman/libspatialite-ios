XCODE_DEVELOPER = $(shell xcode-select --print-path)
IOS_PLATFORM ?= iPhoneOS

# Pick latest SDK in the directory
IOS_PLATFORM_DEVELOPER = ${XCODE_DEVELOPER}/Platforms/${IOS_PLATFORM}.platform/Developer
IOS_SDK = ${IOS_PLATFORM_DEVELOPER}/SDKs/$(shell ls ${IOS_PLATFORM_DEVELOPER}/SDKs | sort -r | head -n1)

all: lib/libspatialite.a
lib/libspatialite.a: build_arches
	mkdir -p lib
	mkdir -p include

	# Copy includes
	cp -R build/arm64/include/geos include
	cp -R build/arm64/include/spatialite include
	cp -R build/arm64/include/*.h include

	# Make fat libraries for all architectures
	for file in build/arm64/lib/*.a; \
		do name=`basename $$file .a`; \
		lipo -create \
			-arch armv7 build/armv7/lib/$$name.a \
			-arch armv7s build/armv7s/lib/$$name.a \
			-arch arm64 build/arm64/lib/$$name.a \
			-arch i386 build/i386/lib/$$name.a \
			-arch x86_64 build/x86_64/lib/$$name.a \
			-output lib/$$name.a \
		; \
		done;

# Build separate architectures
build_arches:
	${MAKE} arch ARCH=armv7 IOS_PLATFORM=iPhoneOS HOST=arm-apple-darwin
	${MAKE} arch ARCH=armv7s IOS_PLATFORM=iPhoneOS HOST=arm-apple-darwin
	${MAKE} arch ARCH=arm64 IOS_PLATFORM=iPhoneOS HOST=arm-apple-darwin
	${MAKE} arch ARCH=i386 IOS_PLATFORM=iPhoneSimulator HOST=i386-apple-darwin
	${MAKE} arch ARCH=x86_64 IOS_PLATFORM=iPhoneSimulator HOST=x86_64-apple-darwin

PREFIX = ${CURDIR}/build/${ARCH}
LIBDIR = ${PREFIX}/lib
BINDIR = ${PREFIX}/bin
INCLUDEDIR = ${PREFIX}/include

CXX = ${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++
CC = ${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
CFLAGS = -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH} -I${INCLUDEDIR} -miphoneos-version-min=7.0 -O3 -fembed-bitcode
CXXFLAGS = -stdlib=libc++ -std=c++11 -isysroot ${IOS_SDK} -I${IOS_SDK}/usr/include -arch ${ARCH} -I${INCLUDEDIR} -miphoneos-version-min=7.0 -O3 -fembed-bitcode
LDFLAGS = -stdlib=libc++ -isysroot ${IOS_SDK} -L${LIBDIR} -L${IOS_SDK}/usr/lib -arch ${ARCH} -miphoneos-version-min=7.0

# Library version definitions
SPATIALITE_VERSION = 5.0.1
TIFF_VERSION = 4.3.0
PROJ_VERSION = 8.1.0
GEOS_VERSION = 3.8.2
RTTOPO_VERSION = 1.1.0
SQLITE3_YEAR = 2021
SQLITE3_VERSION = 3360000

arch: ${LIBDIR}/libspatialite.a

#${LIBDIR}/libspatialite.a: ${LIBDIR}/libtiff.a ${LIBDIR}/libproj.a ${LIBDIR}/libgeos.a ${LIBDIR}/librttopo.a ${CURDIR}/spatialite
${LIBDIR}/libspatialite.a: ${LIBDIR}/librttopo.a ${CURDIR}/spatialite
	cd spatialite && env \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS} -Wno-error=implicit-function-declaration" \
	CXXFLAGS="${CXXFLAGS} -Wno-error=implicit-function-declaration" \
	LDFLAGS="${LDFLAGS} -liconv -lgeos -lgeos_c -lc++" ./configure --host=${HOST} --enable-freexl=no --enable-libxml2=no --prefix=${PREFIX} --with-geosconfig=${BINDIR}/geos-config --disable-shared && make clean install-strip

${CURDIR}/spatialite:
	curl http://www.gaia-gis.it/gaia-sins/libspatialite-sources/libspatialite-${SPATIALITE_VERSION}.tar.gz > spatialite.tar.gz
	tar -xzf spatialite.tar.gz
	rm spatialite.tar.gz
	mv libspatialite-${SPATIALITE_VERSION} spatialite
	./update-spatialite
	./change-deployment-target spatialite

${LIBDIR}/libtiff.a: ${CURDIR}/tiff
	cd tiff && env \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS}" \
	CXXFLAGS="${CXXFLAGS}" \
	LDFLAGS="${LDFLAGS}" ./configure --host=${HOST} --prefix=${PREFIX} --disable-shared && make clean install

${CURDIR}/tiff:
	curl -L http://download.osgeo.org/libtiff/tiff-${TIFF_VERSION}.tar.gz > tiff.tar.gz
	tar -xzf tiff.tar.gz
	rm tiff.tar.gz
	mv tiff-${TIFF_VERSION} tiff
	./change-deployment-target tiff
	(pushd tiff && mv VERSION VERSION.txt && patch -p0 < ../tiff-rename-VERSION.patch)

${LIBDIR}/libproj.a: ${CURDIR}/proj
	cd proj && env \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS}" \
	CXXFLAGS="${CXXFLAGS}" \
	LDFLAGS="${LDFLAGS}" ./configure --host=${HOST} --prefix=${PREFIX} --disable-shared --without-curl && make clean install

${CURDIR}/proj:
	curl -L http://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz > proj.tar.gz
	tar -xzf proj.tar.gz
	rm proj.tar.gz
	mv proj-${PROJ_VERSION} proj
	./change-deployment-target proj

${LIBDIR}/libgeos.a: ${CURDIR}/geos
	cd geos && env \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS}" \
	CXXFLAGS="${CXXFLAGS}" \
	LDFLAGS="${LDFLAGS}" ./configure --host=${HOST} --prefix=${PREFIX} --disable-shared && make clean install

${CURDIR}/geos:
	curl http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2 > geos.tar.bz2
	tar -xzf geos.tar.bz2
	rm geos.tar.bz2
	mv geos-${GEOS_VERSION} geos
	./change-deployment-target geos

${LIBDIR}/librttopo.a: ${CURDIR}/rttopo
	cd rttopo && \
	./autogen.sh && \
	../change-deployment-target . && \
	env \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS}" \
	CXXFLAGS="${CXXFLAGS}" \
	LDFLAGS="${LDFLAGS}" ./configure --host=${HOST} --prefix=${PREFIX} --with-geosconfig=${BINDIR}/geos-config --disable-shared && make clean install

${CURDIR}/rttopo:
	curl -L https://git.osgeo.org/gitea/rttopo/librttopo/archive/librttopo-${RTTOPO_VERSION}.tar.gz > rttopo.tar.gz
	tar -xzf rttopo.tar.gz
	rm rttopo.tar.gz
	mv librttopo rttopo

${LIBDIR}/libsqlite3.a: ${CURDIR}/sqlite3
	cd sqlite3 && env LIBTOOL=${XCODE_DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/libtool \
	CXX=${CXX} \
	CC=${CC} \
	CFLAGS="${CFLAGS} -DSQLITE_THREADSAFE=1 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS=1" \
	CXXFLAGS="${CXXFLAGS} -DSQLITE_THREADSAFE=1 -DSQLITE_ENABLE_RTREE=1 -DSQLITE_ENABLE_FTS3=1 -DSQLITE_ENABLE_FTS3_PARENTHESIS=1" \
	LDFLAGS="-Wl,-arch -Wl,${ARCH} -arch_only ${ARCH} ${LDFLAGS}" \
	./configure --host=${HOST} --prefix=${PREFIX} --disable-shared \
	   --enable-dynamic-extensions --enable-static && make clean install-includeHEADERS install-libLTLIBRARIES

${CURDIR}/sqlite3:
	curl https://www.sqlite.org/${SQLITE_YEAR}/sqlite-autoconf-${SQLITE3_VERSION}.tar.gz > sqlite3.tar.gz
	tar xzvf sqlite3.tar.gz
	rm sqlite3.tar.gz
	mv sqlite-autoconf-${SQLITE3_VERSION} sqlite3
	./change-deployment-target sqlite3
	touch sqlite3

clean:
	rm -rf build geos proj spatialite rttopo tiff include lib
