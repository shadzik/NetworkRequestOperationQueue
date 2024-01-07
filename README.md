## NetworkRequestOperationQueue

Enqueue your network requests using NetworkRequestOperationQueue.

### Benefits

* serial or parallel
* prioritize requests
* cancel requests
* add dependencies to requests
* define and use _ready_ strategies
* define and use _retry_ strategies
* use predefined content mappers (JSON, data) or easily create your own

### Instalation

#### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/shadzik/NetworkRequestOperationQueue.git", .upToNextMajor(from: "1.0.0"))
]
```

### Usage

Please refer to our Demo project or the unit tests to see how it works.

#### A bit of history

Back in the day, working for a great german telco, we've implemented this code in Objective-C with Jola, Paweł, Maciej, Stefan, Stefan and me. This is a complete rewrite in Swift (+ some changes and additions).
