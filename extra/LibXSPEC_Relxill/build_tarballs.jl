using BinaryBuilder

name = "LibXSPEC_Relxill"

version = v"0.2.4"

sources = [
    ArchiveSource(
        "http://sternwarte.uni-erlangen.de/~dauser/research/relxill/relxill_model_v2.4.tgz",
        "f510733a51626ec15d014f4b0ed2e230c796f8f8f6d804c4253790960b085232",
    ),
    DirectorySource("bundled"),
    FileSource(
        "http://www.sternwarte.uni-erlangen.de/~dauser/research/relxill/rel_table_v0.5a.fits.gz",
        "a41bc29ee8cd96ca94aae40e79c19d71f5c6270b43bb074e61bfc1ada2f12316",
    ),
]

scripts = raw"""
cd ${WORKSPACE}/srcdir

# copy in makefile
mv ./makefiles/Makefile ./

# Choose extension based on architecture
if [[ ${target} == *'apple-darwin'* ]] ; then
    EXT=dylib
else
    EXT=so
fi

mkdir -p ${prefix}/lib
mkdir -p ${prefix}/data

sed -i 's|#define RELXILL_TABLE_PATH.*|#define RELXILL_TABLE_PATH "../data"|' common.h

make -j \
    INCLUDE_ROOT=${WORKSPACE}/destdir/include \
    LIBRARY_ROOT=${WORKSPACE}/destdir/lib

mv relxill ${prefix}/lib/relxill.${EXT}
gzip -d rel_table_v0.5a.fits.gz
mv *.fits ${prefix}/data

install_license LICENSE
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

products = [LibraryProduct("relxill", :libXSPEC_relxill)]

dependencies = [Dependency("CompilerSupportLibraries_jll"), Dependency("LibXSPEC_jll")]

init_block = """# set environment variable needed by the models
    ENV["RELXILL_TABLE_PATH"] = $(name)_jll.artifact_dir * "/data"
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
