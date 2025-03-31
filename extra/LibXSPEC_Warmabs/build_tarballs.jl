using BinaryBuilder

name = "LibXSPEC_Warmabs"

version = v"2.58.5"

sources = [
    ArchiveSource(
        "https://heasarc.gsfc.nasa.gov/FTP/software/plasma_codes/xstar/warmabstar.tar.gz",
        "5ad07e26e14bc7e100c91f1eeb0382c15200d11a25afd998506452e305945fb3",
    ),
]

scripts = raw"""
cd ${WORKSPACE}/srcdir

# Choose extension based on architecture
if [[ ${target} == *'apple-darwin'* ]] ; then
    EXT=dylib
else
    EXT=so
fi

$FC -fPIC -shared -lcfitsio -lgfortran -lXSFunctions -lXS -o "fphotems.$EXT" fphotems.f90

mkdir -p ${prefix}/lib
mv "fphotems.$EXT" ${prefix}/lib/

install_license README
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

products = [LibraryProduct("fphotems", :libXSPEC_fphotems)]

dependencies = [Dependency("CompilerSupportLibraries_jll"), Dependency("LibXSPEC_jll")]

init_block = """# set environment variable needed by the models
    ENV["WARMABS_DATA"] = expanduser("~/.julia/spectral_fitting_data/warmabs")
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
