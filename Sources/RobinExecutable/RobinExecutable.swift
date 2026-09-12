import RobinCLI

@main
struct RobinExecutable {
  static func main() async {
    await RobinCommandLine.main()
  }
}
