# TypedCodable

Heavily inspired from [Swift 4.2 Decodable: Heterogeneous collections](https://medium.com/@kewindannerfjordremeczki/swift-4-0-decodable-heterogeneous-collections-ecc0e6b468cf) by [Kewin Dannerfjord Remeczki](https://medium.com/@kewindannerfjordremeczki).

Original code is modified in order to support NSKeyed(Un)archiver in addition to JSONEncoder/Decoder.
Additionally, a TypedCodable protocol is introduced, to factorize the code snippet needed to introduce the type information at encoding time.

See Tests/TypedCodableTests/TypedCodableTests.swift for a usage example.
