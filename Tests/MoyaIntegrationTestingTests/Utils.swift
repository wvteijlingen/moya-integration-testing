import Foundation
import Moya

struct MoyaRequest: RequestType {
    let request: URLRequest?
    let sessionHeaders: [String: String] = [:]

    init(_ request: URLRequest?) {
        self.request = request
    }

    func authenticate(username: String, password: String, persistence: URLCredential.Persistence) -> Self {
        self
    }

    func authenticate(with credential: URLCredential) -> Self {
        self
    }

    func cURLDescription(calling handler: @escaping (String) -> Void) -> Self {
        self
    }
}

struct MoyaTarget: TargetType {
    var baseURL: URL
    var path: String
    var method: Moya.Method
    var sampleData: Data = Data()
    var task: Task = .requestPlain
    var headers: [String: String]?

    var request: URLRequest {
        let url = URL(string: path, relativeTo: baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        return request
    }

    var moyaRequest: RequestType {
        MoyaRequest(request)
    }
}

enum TestTarget: TargetType {
    case foo
    case bar

    var baseURL: URL {
        URL(string: "https://example.com")!
    }

    var path: String {
        switch self {
        case .foo:
            return "foo"
        case .bar:
            return "bar"
        }
    }

    var method: Moya.Method {
        .get
    }

    var sampleData: Data {
        Data()
    }

    var task: Task {
        .requestPlain
    }

    var headers: [String: String]? {
        nil
    }
}
