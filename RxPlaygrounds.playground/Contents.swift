//: Playground - noun: a place where people can play

import UIKit
import RxSwift

let myFirstObservable = Observable<Int>.create { observer in
    observer.onNext(1)
    observer.onNext(2)
    observer.onNext(3)
    observer.onCompleted()
    
    return Disposables.create()
}

let subscription = myFirstObservable.subscribe { event in
    switch event {
    case .next(let element):
        print(element)
    case .error(let error):
        print(error)
    case .completed:
        print("completed")
    }
}
subscription.dispose()

let subscription2 = myFirstObservable
    .map { $0 * 5 }
    .subscribe(onNext: { print("map: \($0)")})
subscription2.dispose()


import RxCocoa

struct SearchResult {
    let repos: [GithubRepository]
    let totalCount: Int
    
    init?(response: Any) {
        guard let response = response as? [String: Any],
            let reposDictionaries = response["items"] as? [[String: Any]],
            let count = response["total_count"] as? Int
            else {
                return nil
        }
        
        repos = reposDictionaries.flatMap { GithubRepository(dictionary: $0) }
        totalCount = count
    }
}

struct GithubRepository {
    let name: String
    let startCount: Int
    
    init(dictionary: [String: Any]) {
        name = dictionary["full_name"] as! String
        startCount = dictionary["stargazers_count"] as! Int
    }
}

func searchRepos(keyword: String) -> Observable<SearchResult?> {
    let endPoint: String = "https://api.github.com"
    let path: String = "/search/repositories"
    let query: String = "?q=\(keyword)"
    let url = URL(string: endPoint + path + query)
    var request: URLRequest {
        return URLRequest(url: url!)
    }

    return URLSession.shared
        .rx.json(request: request)
        .map {
            print($0)
            return SearchResult(response: $0)
    }
}

let subscription3 = searchRepos(keyword: "RxSwift")
    .subscribe(onNext: { print($0!) },
               onError: { _ in print("Error") },
               onCompleted: { print("Completed") })







