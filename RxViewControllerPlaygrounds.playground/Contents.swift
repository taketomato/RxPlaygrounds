import UIKit
import RxSwift

// 通信処理をできるように
import Foundation
import PlaygroundSupport
import RxCocoa

PlaygroundPage.current.needsIndefiniteExecution = true

URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)


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
        .map { SearchResult(response: $0) }
}

class SearchViewController: UIViewController {
    let searchField = UITextField()
    let totalCountLabel = UILabel()
    let reposLabel = UILabel()
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupSubviews()
        bind()
    }

    func setupSubviews() {
        searchField.frame = CGRect(x: 10, y: 10, width: 300, height: 20)
        totalCountLabel.frame = CGRect(x: 10, y: 40, width: 300, height: 20)
        reposLabel.frame = CGRect(x: 10, y: 60, width: 300, height: 400)
        
        searchField.borderStyle = .roundedRect
        reposLabel.numberOfLines = 0
        searchField.keyboardType = .alphabet
        
        view.addSubview(searchField)
        view.addSubview(totalCountLabel)
        view.addSubview(reposLabel)
    }
    
    func bind() {
        let result: Observable<SearchResult?> = searchField.rx.text
            .orEmpty
            .asObservable()
            .skip(1)
            .debounce(0.3, scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest {
                searchRepos(keyword: $0)
                    .observeOn(MainScheduler.instance)
                    .catchErrorJustReturn(nil)
            }
            .shareReplay(1)
        
        let foundRepos: Observable<String> = result.map {
            let repos = $0?.repos ?? [GithubRepository]()
            return repos.reduce("") {
                $0 + "\($1.name)(\($1.startCount)) \n"
            }
        }
        
        let foundCount: Observable<String> = result.map {
            let count = $0?.totalCount ?? 0
            return "TotalCount: \(count)"
        }
        
        foundRepos
            .bind(to: reposLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        foundCount
            .bind(to: totalCountLabel.rx.text)
            .addDisposableTo(disposeBag)
    }
}

PlaygroundPage.current.liveView = SearchViewController()


