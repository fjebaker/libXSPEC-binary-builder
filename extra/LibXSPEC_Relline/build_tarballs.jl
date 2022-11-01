using BinaryBuilder

name = "LibXSPEC_Relline"

version = v"0.1.1"

sources = [
    ArchiveSource("http://www.sternwarte.uni-erlangen.de/~dauser/research/relline/relline_code.tgz", "e645e52b6aeb63c5af909d42ac9d89058619196e5ce9c30fe4662b4ccf255c99"),
    ArchiveSource("http://www.sternwarte.uni-erlangen.de/~dauser/research/relline/tables.fits.tgz", "bee959c560aa824a8534e8a9c21f2b7f4ec1051ca94b88906ca07041d4524432"),
]

scripts = raw"""
cd ${WORKSPACE}/srcdir

# Choose extension based on architecture
if [[ ${target} == *'apple-darwin'* ]] ; then
    EXT=dylib
else
    EXT=so
fi

sed -i "s|.*relline_tables = '.*'|relline_tables = '../data'|" relbase.f90

gfortran -shared -fPIC relbase.f90 -o tmp_out && rm tmp_out*
gfortran -shared -fPIC ../destdir/lib/libcfitsio.${EXT} relline.f90 relbase.f90 relconv.f90 -o relline.${EXT}

mkdir -p ${prefix}/lib
mkdir -p ${prefix}/data

mv relline.${EXT} ${prefix}/lib
mv *.fits ${prefix}/data

# Extract LICENSE from source file 
head -n 15 relbase.f90 > LICENSE
sed -i 's|! ||g' LICENSE
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

products = [LibraryProduct("relline", :libXSPEC_relline)]

dependencies = [
    Dependency("CompilerSupportLibraries_jll"),
    Dependency("LibXSPEC_jll")
]

init_block = """# set environment variable needed by the models
    ENV["RELLINE_TABLES"] = $(name)_jll.artifact_dir * "/data"
"""

build_tarballs(ARGS, name, version, sources, scripts, platforms, products, dependencies; julia_compat="1.6", init_block=init_block, )