using BinaryBuilder

name = "LibXSPEC"

version = v"6.35.1"

sources = [
    ArchiveSource(
        "https://heasarc.gsfc.nasa.gov/FTP/software/lheasoft/lheasoft6.35.1/heasoft-6.35.1src.tar.gz",
        "60515214c01dbf3bea13fce27b5a2335f0be051172c745922cfe4c0be442bbbb",
    ),
    DirectorySource("bundled"),
]

scripts = raw"""
echo "Starting build..."

cd ${WORKSPACE}/srcdir/
mv heasoft-6.35.1 BUILD_DIR
cd BUILD_DIR

# Replace paths to use `spectral` directory directly in `$HEADAS`
# Commented out for now since did this on host to save time

modfiles=(
    Xspec/src/XSFunctions/hatm.cxx
    Xspec/src/XSFunctions/Utilities/xsFortran.cxx
    Xspec/src/XSFunctions/carbatm.cxx
    Xspec/src/scripts/xspec.tcl
    Xspec/src/scripts/xspec.tcl
    Xspec/src/XSUser/Python/mxspec/pymXspecmodule.cxx
    Xspec/src/XSUser/Python/mxspec/pymXspecmodule.cxx
    Xspec/src/tools/raysmith/rayspec_m.f
    Xspec/src/XSUser/Global/Global.cxx
)

for file in "${modfiles[@]}" ; do
    sed -i 's|../spectral/|spectral/|g' "$file"
done

echo "Done path patch"

# Need this to avoid undefined symbols
export LDFLAGS="-lgfortran"

if [[ ${target} == *'apple-darwin'* ]] ; then
    # Apply patch
    atomic_patch -p1 ../patches/apple.patch
else
    atomic_patch -p1 ../patches/linux.patch
fi

# Run autoconf in each build directory to propagate changes to build files
cd ..
find . -type d -name "BUILD_DIR" -exec autoconf -f -o {}/configure {}/configure.in \;
cd BUILD_DIR/BUILD_DIR

CONFIGURE_FLAGS="--prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-x --enable-xs-models-only"

if [[ ${target} == *'apple-darwin'* ]] ; then
    # Need to link BLAS and quadmath explicitly to avoid missing symbols on OSX
    export LDFLAGS="$LDFLAGS -lblas -lquadmath"
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --target=${target}"

    if [[ ${target} != *'aarch64-apple-darwin'* ]] ; then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-mac_intel_build"
    fi

    # Need to compile hd_install for the container seperately
    /opt/x86_64-linux-musl/bin/x86_64-linux-musl-gcc -o ./hd_install.o -Wall --pedantic -Wno-comment -Wno-long-long -g  -Dunix -fPIC -fno-common hd_install.c
    mv hd_install.o hd_install
    rm -f hd_install.c

    # Copy it everywhere it is needed and remove the old source version
    cp hd_install ../heacore/BUILD_DIR
    rm ../heacore/BUILD_DIR/hd_install.c
    cp hd_install ../Xspec/BUILD_DIR
    rm ../Xspec/BUILD_DIR/hd_install.c
fi

# Configure with selected flags
./configure $CONFIGURE_FLAGS

# Can't use `-j`, since parallel compilation breaks XSPEC :/
# XSPEC compiles `hd_install` as the first target, which is used throughout the rest of the Makefile
make
make install

# Move libraries around to put them all in the export location
rm -fr ${prefix}/heacore/*/lib/cmake ${prefix}/heacore/*/lib/pkgconfig
mv ${prefix}/heacore/*/lib/* ${prefix}/lib/
mv ${prefix}/heacore/*/include/* ${prefix}/include/
mv ${prefix}/Xspec/*/lib/* ${prefix}/lib/
mv ${prefix}/Xspec/*/include/* ${prefix}/include/

# Remove bloat
ls ${prefix}
rm -r ${prefix}/heacore \
    ${prefix}/Xspec \
    ${prefix}/$(uname -m)-* \
    ${prefix}/spectral/help \
    ${prefix}/spectral/scripts \
    ${prefix}/bin

# Remove large modelData files so we can actually upload artifact
rm -rf ${prefix}/spectral/modelData

# Concatanate all of the licenses
cat ${WORKSPACE}/srcdir/BUILD_DIR/licenses/* > ${WORKSPACE}/srcdir/LICENSE
install_license ${WORKSPACE}/srcdir/LICENSE
"""

platforms = [
    Platform("x86_64", "linux"; libc = "glibc", libgfortran_version = "5.0.0"),
    Platform("x86_64", "linux"; libc = "glibc", libgfortran_version = "4.0.0"),
    Platform("aarch64", "macos"; libgfortran_version = "5.0.0"),
    Platform("x86_64", "macos"; libgfortran_version = "5.0.0"),
    Platform("x86_64", "macos"; libgfortran_version = "4.0.0"),
]
platforms = expand_cxxstring_abis(platforms)
platforms = expand_gfortran_versions(platforms)

products = map([
    "libcfitsio" => :libcfitsio,
    "libreadline" => :libreadline,
    "libfgsl" => :libfgsl,
    "libXS" => :libXS,
    "libXSUtil" => :libXSUtil,
    "libXSFunctions" => :libXSFunctions,
    "libXSModel" => :libXSModel,
]) do lib
    LibraryProduct(first(lib), last(lib))
end

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("Ncurses_jll"),
    Dependency("Zlib_jll"),
]

init_block = raw"""# set environment variable needed by the models
    ENV["HEADAS"] = LibXSPEC_jll.artifact_dir
"""

build_tarballs(
    ARGS,
    name,
    version,
    sources,
    scripts,
    platforms,
    products,
    dependencies;
    julia_compat = "1.6",
    init_block = init_block,
)
