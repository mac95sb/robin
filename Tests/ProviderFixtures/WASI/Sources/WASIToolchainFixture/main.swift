@main
struct WASIToolchainFixture {
  static func main() {
    #if os(WASI)
      print("wasi-toolchain-ok")
    #endif
  }
}
