// swift-tools-version:5.7
 import PackageDescription

 let package = Package(
     name: "Fingertips",
     platforms: [.iOS(.v11), .custom("visionOS", versionString: "1.0")],
     products: [
         .library(name: "Fingertips", targets: ["Fingertips"]),
     ],
     targets: [
         .target(
             name: "Fingertips",
             dependencies: [],
             publicHeadersPath: ".")
     ]
 )
