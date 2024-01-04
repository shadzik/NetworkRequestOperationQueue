## NetworkRequestOperationQueue

Enqueue your network requests using NetworkRequestOperationQueue.

### Benefits

* serial or parallel
* prioritize requests
* add dependencies to requests
* define and use ready strategies
* define and use retry strategies

### Instalation

#### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/shadzik/NetworkRequestOperationQueue.git", .upToNextMajor(from: "1.0.0"))
]
```

### Usage

Please refer to the unit tests to see how it works

#### A bit of history

Back in the day, working for a great german telco, we've implemented this code with Jola, Paweł, Maciej, Stefan, Stefan and me. This is a complete rewrite in Swift (+ some changes and additions)
