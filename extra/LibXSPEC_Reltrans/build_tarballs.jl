using BinaryBuilder

name = "LibXSPEC_Reltrans"

version = v"2.3.1"

sources = [
    GitSource(
        "https://github.com/fjebaker/reltrans/",
        "11bcf354f446bc9c298015dbc319f4712e19c8f2",
    ),
    # TODO: add data sources? else make them dynamically fetched (probably better)
]

scripts = raw"""
cd ${WORKSPACE}/srcdir

export HEADAS="${prefix}"

# Specify the target to the build script, since cross-compiling will not
# resolve uname
TARGET=Linux
if [[ ${target} == *'apple-darwin'* ]] ; then
    TARGET=Darwin
fi

cd utils
make TARGET=$TARGET

mkdir -p ${prefix}/lib
mv build/lib/* ${prefix}/lib/

install_license ../LICENSE
"""

platforms = [
    Platform("x86_64", "linux"; libc = "glibc", libgfortran_version = "5.0.0"),
    # Platform("x86_64", "linux"; libc = "glibc", libgfortran_version = "4.0.0"),
    # Platform("aarch64", "macos"; libgfortran_version = "5.0.0"),
    # Platform("x86_64", "macos"; libgfortran_version = "5.0.0"),
    # Platform("x86_64", "macos"; libgfortran_version = "4.0.0"),
]
# platforms = expand_cxxstring_abis(platforms)
# platforms = expand_gfortran_versions(platforms)

products = [LibraryProduct("libreltrans", :libXSPEC_reltrans)]

dependencies = [Dependency("CompilerSupportLibraries_jll"), Dependency("LibXSPEC_jll")]

init_block = """# set environment variable needed by the models
    # TODO: fixme, check for the right environment variables regarding data tables,
    # else print helpful error
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
