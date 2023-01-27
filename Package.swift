// swift-tools-version:4.2
 import PackageDescription

 let package = Package(
     name: "Fingertips",
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
