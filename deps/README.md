# build

This is setup for building a copy of licensecheck with our `main.go` for debugging https://github.com/ericphanson/LicenseCheck.jl/issues/11

- `main.go`: copied from https://github.com/JuliaPackaging/Yggdrasil/blob/master/L/licensecheck/bundled/main.go
- `build.jl`: modified from https://github.com/JuliaPackaging/Yggdrasil/blob/348003044a6e4f2150b2a8de8282ebf7739c6a0d/L/licensecheck/build_tarballs.jl
    - `build_tarballs.jl` is part of the https://binarybuilder.org/ cross-compilation & artifact distribution system used by Julia. For this branch, we replace it with a local build to allow for faster iteration and debugging.
