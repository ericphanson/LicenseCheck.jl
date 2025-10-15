# https://github.com/JuliaPackaging/Yggdrasil/blob/348003044a6e4f2150b2a8de8282ebf7739c6a0d/L/licensecheck/build_tarballs.jl#L26C1-L29C92

build_dir = joinpath(@__DIR__, "..", "build")
rm(build_dir; recursive=true, force=true)
mkpath(build_dir)
run(`git -C $build_dir clone https://github.com/google/licensecheck`)
licencecheck_dir = joinpath(build_dir, "licensecheck")
run(`git -C $licencecheck_dir checkout 5aa300fd3333d0c6592148249397338023cafcce`)

main = joinpath(@__DIR__, "main.go")
wrapper_c = joinpath(@__DIR__, "wrapper.c")
libdir = joinpath(build_dir, "lib")
dlext = "dylib"
_run = cmd -> run(Cmd(cmd; dir=licencecheck_dir))
_run(`mkdir clib`)
_run(`cp $main clib/main.go`)
_run(`mkdir -p $libdir`)

# Build the Go library
go_lib_path = "$libdir/licensecheck_go.$dlext"
_run(addenv(`go build -buildmode=c-shared -o $go_lib_path clib/main.go`, "CGO_ENABLED" => "1"))

# Build the C wrapper that manages signal handlers
wrapper_lib_path = "$libdir/licensecheck.$dlext"
run(`gcc -shared -fPIC -o $wrapper_lib_path $wrapper_c -ldl`)
