// swift-tools-version:5.0
 import PackageDescription

 let package = Package(
     name: "Fingertips",
     platforms: [.iOS(.v11)],
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
