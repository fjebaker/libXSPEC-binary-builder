using BinaryBuilder

name = "LibXSPEC_KYNReverb"

version = v"0.1.3"

sources = [
    GitSource("https://github.com/xstarkit/kynreverb", "8a47ce589374d17f1fb1e12425e4fa047cacb8f3"),
    DirectorySource("bundled"),
    FileSource("https://owncloud.asu.cas.cz/index.php/s/abuFcygHKEKFiSa/download", "426d7356522c625c62ee6dd92fc016a2c805202372c2fb101ec79e016b8da711"; filename="KBHlamp80.fits"),
    FileSource("https://owncloud.asu.cas.cz/index.php/s/WP8aLN168MJgcB9/download", "fac193835b6f5981bdab8bff45ec09882ddf533060cfb934a8a41874bfaac799"; filename="KBHtables80.fits"),
    FileSource("https://heasarc.gsfc.nasa.gov/xanadu/xspec/models/reflion.mod.gz", "4f315fe24d6b8e6e2e6f866df4370b7e3087363c50579376c4f7646cffc6e073"),
    FileSource("https://heasarc.gsfc.nasa.gov/xanadu/xspec/models/reflionx.mod.gz", "b0368041414f6e5fe734628571680aba07fc4a9afc06f6e293c9ca0101fb19fa"),
]

scripts = raw"""
cd ${WORKSPACE}/srcdir
gzip -d reflion.mod.gz
gzip -d reflionx.mod.gz
cd kynreverb
atomic_patch -p1 ../patches/generic-build.patch
atomic_patch -p1 ../patches/generated-xspec-module.patch

# Copy new makefile
mv ../makefiles/Makefile ./

# Choose extension based on architecture
if [[ ${target} == *'apple-darwin'* ]] ; then
    EXT=dylib
else
    EXT=so
fi

mkdir -p ${prefix}/lib 

make \
    INCLUDE_ROOT=${WORKSPACE}/destdir/include \
    LIBRARY_ROOT=${WORKSPACE}/destdir/lib

mv kynrefrev ${prefix}/lib/kynrefrev.${EXT}
mv ../*.fits ${prefix}/lib
mv ../*.mod ${prefix}/lib

# just use the readme as a license
mv README.md LICENSE
install_license LICENSE
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc", libgfortran_version="5.0.0"),
    Platform("x86_64", "linux"; libc="glibc", libgfortran_version="4.0.0"),
    Platform("aarch64", "macos"; libgfortran_version="5.0.0"),
    Platform("x86_64", "macos"; libgfortran_version="5.0.0"),
    Platform("x86_64", "macos"; libgfortran_version="4.0.0")
]
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

products = [LibraryProduct("kynrefrev", :libXSPEC_kynrefrev)]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("LibXSPEC_jll"),
    Dependency("CFITSIO_jll"),
]

build_tarballs(ARGS, name, version, sources, scripts, platforms, products, dependencies; julia_compat="1.6",)
