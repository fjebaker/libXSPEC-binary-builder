using BinaryBuilder

name = "LibXSPEC"
version = v"0.1.8"
sources = [
    # ArchiveSource("https://heasarc.gsfc.nasa.gov/cgi-bin/Tools/tarit/tarit.pl?mode=download&arch=src&src_pc_linux_debian=Y&src_other_specify=&general=heasptools&general=heagen&xanadu=xspec")
    DirectorySource("heasoft-6.30.1")
]

scripts = raw"""
# replace paths to use `spectral` directory directly in `$HEADAS`
# commented out for now since did this on host to save time
# find ${WORKSPACE}/srcdir -type f -exec sed -n 's|../spectral/|spectral/|g' {} \;

cd ${WORKSPACE}/srcdir/BUILD_DIR

# do we need to do this explicitly? i don't think so
# export FC=$(which gcc)
# export CC=$(which gcc)
# export CXX=$(which g++)

if [[ ${target} == *'darwin'* ]] ; then
    ./configure --prefix=${prefix} --disable-x --enable-xs-models-only --enable-mac_arm_build
else
    ./configure --prefix=${prefix} --build=${MACHTYPE} --host=${target} --disable-x --enable-xs-models-only
fi

# can't use `-j`, since parallel compilation breaks XSPEC :/
make
make install

# move libraries around to put them all in the export location
rm -fr ${prefix}/heacore/*/lib/cmake ${prefix}/heacore/*/lib/pkgconfig
mv ${prefix}/heacore/*/lib/* ${prefix}/lib/
mv ${prefix}/heacore/*/include/* ${prefix}/include/

mv ${prefix}/Xspec/*/lib/* ${prefix}/lib/
mv ${prefix}/Xspec/*/include/* ${prefix}/include/

# copy some shared libraries // why do simlinks not work?
ln -s ${prefix}/lib/libcfitsio.so.9 ${prefix}/lib/libcfitsio.9.so 
ln -s ${prefix}/lib/libreadline.so ${prefix}/lib/libreadline.8.so
ln -s ${prefix}/lib/libfgsl.so ${prefix}/lib/libfgsl.1.so

# remove bloat
ls ${prefix}
rm -r ${prefix}/heacore \
    ${prefix}/Xspec \
    ${prefix}/$(uname -m)-* \
    ${prefix}/logs \
    ${prefix}/spectral/help \
    ${prefix}/include \
    ${prefix}/spectral/scripts \
    ${prefix}/bin  

# remove large modelData files so we can actually upload artifact
# if these are needed by end user, can just copy them into the right artifact directory
# rm ${prefix}/spectral/modelData/xillver-a-Ec3.fits \
#     ${prefix}/spectral/modelData/slimbb-full.fits \
#     ${prefix}/spectral/modelData/apec_v3.0.9_nei_comp.fits \
#     ${prefix}/spectral/modelData/apec_v3.0.9_nei_line.fits \
#     ${prefix}/spectral/modelData/apec_v3.0.9_line.fits \
#     ${prefix}/spectral/modelData/apec_v3.0.9_coco.fits
rm -rf ${prefix}/spectral/modelData

# concatanate all of the licenses
cat ${WORKSPACE}/srcdir/licenses/* > ${WORKSPACE}/srcdir/LICENSE
install_license ${WORKSPACE}/srcdir/LICENSE
"""

platforms = [
    Platform("x86_64", "linux"; libc="glibc", libgfortran_version="5.0.0"),
    Platform("x86_64", "linux"; libc="glibc", libgfortran_version="4.0.0"),
    Platform("aarch64", "macos"; libgfortran_version="5.0.0"),
    Platform("aarch64", "macos"; libgfortran_version="4.0.0"),
    Platform("x86_64", "macos"; libc="glibc", libgfortran_version="5.0.0"),
    Platform("x86_64", "macos"; libc="glibc", libgfortran_version="4.0.0")
    #Platform("aarch64", "linux"; libc=:glibc),
    #Platform("x86_64", "macos"; libc="glibc"),
    #Platform("aarch64", "macos"; libgfortran_version="5.0.0")
]
# platforms = expand_cxxstring_abis(platforms)
# platforms = expand_gfortran_versions(platforms)

products = map([
    "libwcs-7.7" => :libwcs,
    "libcfitsio.9" => :libcfitsio,
    "libCCfits_2.6" => :libCCfits,
    "libhdsp_6.30" => :libhdsp,
    "libreadline.8" => :libreadline,
    "libape_2.9" => :libape,
    "libhdio_6.30" => :libhdio,
    "libhdutils_6.30" => :libhdutils,
    "libfgsl.1" => :libfgsl,
    "libXS" => :libXS,
    "libXSUtil" => :libXSUtil,
    "libXSFunctions" => :libXSFunctions
]) do lib
    LibraryProduct(first(lib), last(lib))
end

dependencies = [
    Dependency("Ncurses_jll"),
    Dependency("Zlib_jll"),
    #Dependency("CFITSIO_jll", v"3.49"; compat="~3.49"),
]

init_block = raw"""# set environment variable needed by the models
    ENV["HEADAS"] = LibXSPEC_jll.artifact_dir
"""

build_tarballs(ARGS, name, version, sources, scripts, platforms, products, dependencies; julia_compat="1.7", init_block=init_block)



# """if [[ $(uname -m) == 'arm64' ]] && [[ $OSTYPE == 'darwin'* ]]; then
#     echo "* mac arm build"
#     ./configure --disable-x --enable-xs-models-only --enable-mac_arm_build > config.txt 2>&1
# else
#     echo "* regular build"
#     apk update
#     apk add readline readline-dev ncurses-libs ncurses-terminfo ncurses-dev libc6-compat gcompat zlib-dev
#     ./configure --prefix=$prefix --build=${MACHTYPE} --host=${target} --disable-x --enable-xs-models-only # > config.txt 2>&1
# fi"""