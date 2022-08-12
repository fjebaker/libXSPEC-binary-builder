using BinaryBuilder

name = "LibXSPEC"

# !!! don't make changes without bumping !!!
version = v"0.1.14"

sources = [
    # ArchiveSource("https://heasarc.gsfc.nasa.gov/cgi-bin/Tools/tarit/tarit.pl?mode=download&arch=src&src_pc_linux_debian=Y&src_other_specify=&general=heasptools&general=heagen&xanadu=xspec")
    DirectorySource("heasoft-6.30.1")
]

scripts = raw"""
# Replace paths to use `spectral` directory directly in `$HEADAS`
# Commented out for now since did this on host to save time
# find ${WORKSPACE}/srcdir -type f -print0 | xargs -0 sed -i 's|../spectral/|spectral/|g'

cd ${WORKSPACE}/srcdir/BUILD_DIR

# Need this to avoid undefined symbols
export LDFLAGS="-lgfortran"

CONFIGURE_FLAGS="--prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-x --enable-xs-models-only"

if [[ ${target} == *'apple-darwin'* ]] ; then
    # Need to link BLAS explicitly to avoid missing symbols
    export LDFLAGS="$LDFLAGS -lblas -lquadmath"

    if [[ ${target} == *'aarch64-apple-darwin'* ]] ; then
        CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-mac_arm_build"
    fi

    # Need to compile hd_install for the container seperately
    /opt/x86_64-linux-musl/bin/x86_64-linux-musl-gcc -o ./hd_install.o -Wall --pedantic -Wno-comment -Wno-long-long -g  -Dunix -fPIC -fno-common hd_install.c
    mv hd_install.o hd_install
    rm -f hd_install.c

    # Copy it everywhere it is needed and remove the old source version
    for i in $(find ${WORKSPACE}/srcdir -type f -name "hd_install.c"); do loc=$(dirname $i) && cp ${WORKSPACE}/srcdir/BUILD_DIR/hd_install $loc && rm -f $loc/hd_install.c; done
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
    ${prefix}/logs \
    ${prefix}/spectral/help \
    ${prefix}/include \
    ${prefix}/spectral/scripts \
    ${prefix}/bin  

# Remove large modelData files so we can actually upload artifact
rm -rf ${prefix}/spectral/modelData

# Concatanate all of the licenses
cat ${WORKSPACE}/srcdir/licenses/* > ${WORKSPACE}/srcdir/LICENSE
install_license ${WORKSPACE}/srcdir/LICENSE
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc", libgfortran_version="5.0.0"),
    Platform("x86_64", "linux"; libc="glibc", libgfortran_version="4.0.0"),
    #Platform("aarch64", "macos"; libgfortran_version="5.0.0"),
    #Platform("x86_64", "macos"; libgfortran_version="5.0.0"),
    #Platform("x86_64", "macos"; libgfortran_version="4.0.0")
]
platforms = expand_cxxstring_abis(platforms)
# platforms = expand_gfortran_versions(platforms)

products = map([
    "libcfitsio" => :libcfitsio,
    "libreadline" => :libreadline,
    "libfgsl" => :libfgsl,
    "libXS" => :libXS,
    "libXSUtil" => :libXSUtil,
    "libXSFunctions" => :libXSFunctions
]) do lib
    LibraryProduct(first(lib), last(lib))
end

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    #Dependency("libblastrampoline_jll"),
    Dependency("Ncurses_jll"),
    Dependency("Zlib_jll")
]

init_block = raw"""# set environment variable needed by the models
    ENV["HEADAS"] = LibXSPEC_jll.artifact_dir
"""

build_tarballs(ARGS, name, version, sources, scripts, platforms, products, dependencies; julia_compat="1.6", init_block=init_block)