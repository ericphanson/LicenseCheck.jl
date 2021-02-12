using LicenseCheck
using Test

MIT = """
    MIT License Copyright (c) <year> <copyright holders>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished
    to do so, subject to the following conditions:

    The above copyright notice and this permission notice (including the next
    paragraph) shall be included in all copies or substantial portions of the
    Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
    OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
    OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."""

Latex2e = """
    Copyright (C) 2007, 2008, 2009, 2010 Karl Berry.

    Copyright (C) 1988, 1994, 2007 Stephen Gilmore.

    Copyright (C) 1994, 1995, 1996 Torsten Martinsen.

    Permission is granted to make and distribute verbatim copies of this manual
    provided the copyright notice and this permission notice are preserved on
    all copies.

    Permission is granted to copy and distribute modified versions of this manual
    under the conditions for verbatim copying, provided that the entire resulting
    derived work is distributed under the terms of a permission notice identical
    to this one.

    Permission is granted to copy and distribute translations of this manual into
    another language, under the above conditions for modified versions."""

dorian_gray = """
    The artist is the creator of beautiful things.  To reveal art and
    conceal the artist is art's aim.  The critic is he who can translate
    into another manner or a new material his impression of beautiful
    things.

    The highest as the lowest form of criticism is a mode of autobiography.
    Those who find ugly meanings in beautiful things are corrupt without
    being charming.  This is a fault.

    Those who find beautiful meanings in beautiful things are the
    cultivated.  For these there is hope.  They are the elect to whom
    beautiful things mean only beauty.

    There is no such thing as a moral or an immoral book.  Books are well
    written, or badly written.  That is all."""

@testset "LicenseCheck" begin
    @testset "`licensecheck`" begin
        result = licensecheck(MIT)
        @test result.licenses == ["MIT"]
        @test result.percent_covered ≈ 100.0 atol = 2

        result = licensecheck(MIT * "\n" * Latex2e)
        @test result.licenses == ["MIT", "Latex2e"]
        @test result.percent_covered ≈ 100.0 atol = 2

        result = licensecheck(MIT * "\n" * dorian_gray)
        @test result.licenses == ["MIT"]
        @test result.percent_covered ≈ 100 * length(MIT) / (length(dorian_gray) + length(MIT)) atol = 5

        result = licensecheck(MIT * "\n" * dorian_gray * "\n" * Latex2e)
        @test result.licenses == ["MIT", "Latex2e"]
        @test result.percent_covered ≈
            100 * (length(MIT) + length(Latex2e)) /
            (length(dorian_gray) + length(MIT) + length(Latex2e)) atol = 5
    end

    @testset "`is_osi_approved`" begin
        @test is_osi_approved("MIT") == true
        @test is_osi_approved("ABC") == false

        @test is_osi_approved(find_license(pkgdir(LicenseCheck))) == true
        @test is_osi_approved((; licenses = ["MIT", "MIT"]))
        @test !is_osi_approved((; licenses = String[]))
    end


    @testset "`find_licenses_*`" begin
        fl = find_license(joinpath(@__DIR__, ".."))
        # check it found the right one
        @test fl.path == joinpath(@__DIR__, "..", "LICENSE")
        @test fl.licenses == ["MIT"]
        @test fl.percent_covered > 90

        for method in (find_licenses, find_licenses_by_bruteforce, find_licenses_by_list_intersection)
            results = method(joinpath(@__DIR__, ".."))
            @test only(results) == fl
        end

        # this can return more than 1 result due to case-insenitivity issues
        results = find_licenses_by_list(joinpath(@__DIR__, ".."))
        @test fl ∈ results
    end
end
