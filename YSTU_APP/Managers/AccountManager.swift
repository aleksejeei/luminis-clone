//
//  AccountManager.swift
//  YSTU_APP
//

import Foundation

enum AuthError: Error {
    case invalidCredentials
    case notAuthorized
    case failedToGetData
}

struct ServerError: Error {
    let code: Int
    let message: String
}

private struct APIErrorResponse: Decodable {
    struct Inner: Decodable {
        let code: Int?
        let message: String?
    }
    let error: Inner?
}

final class AccountManager {
    static let shared = AccountManager()
    private init() {}

    // MARK: - Token storage

    private struct StoredTokens: Codable {
        let accessToken: String
        let refreshToken: String
        let expiresAt: TimeInterval
    }

    private let tokensKey = "auth_tokens"

    private var tokens: StoredTokens? {
        get {
            guard let data = UserDefaults.standard.data(forKey: tokensKey) else { return nil }
            return try? JSONDecoder().decode(StoredTokens.self, from: data)
        }
        set {
            if let newValue = newValue, let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: tokensKey)
            } else {
                UserDefaults.standard.removeObject(forKey: tokensKey)
            }
        }
    }

    var isAuthorized: Bool { tokens != nil }

    // MARK: - Sign in / out

    func signIn(login: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        var components = URLComponents(string: "\(Constants.oauthURL)/access_token")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.oauthClientID),
            URLQueryItem(name: "grant_type", value: "password"),
            URLQueryItem(name: "scope", value: Constants.oauthScope),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["username": login, "password": password])

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(error ?? AuthError.failedToGetData))
                return
            }

            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard (200..<300).contains(status) else {
                if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data),
                   let inner = apiError.error {
                    completion(.failure(ServerError(code: inner.code ?? status, message: inner.message ?? "")))
                } else {
                    completion(.failure(AuthError.invalidCredentials))
                }
                return
            }

            do {
                let token = try JSONDecoder().decode(AuthTokenResponse.self, from: data)
                self.store(token)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func signOut(completion: @escaping () -> Void) {
        guard let token = tokens?.accessToken else {
            tokens = nil
            completion()
            return
        }

        var request = URLRequest(url: URL(string: "\(Constants.oauthURL)/logout")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            self?.tokens = nil
            completion()
        }.resume()
    }

    // MARK: - Refresh

    private let queue = DispatchQueue(label: "AccountManager.auth")
    private var isRefreshing = false
    private var pendingRefreshes: [(String?) -> Void] = []

    private func store(_ token: AuthTokenResponse) {
        tokens = StoredTokens(
            accessToken: token.access_token,
            refreshToken: token.refresh_token,
            expiresAt: Date().timeIntervalSince1970 + token.expires_in
        )
    }

    private func invalidateToken() {
        if var t = tokens {
            t = StoredTokens(accessToken: t.accessToken, refreshToken: t.refreshToken, expiresAt: 0)
            tokens = t
        }
    }

    private func ensureValidAccessToken(completion: @escaping (String?) -> Void) {
        queue.async {
            if let t = self.tokens, t.expiresAt > Date().timeIntervalSince1970 + 60 {
                completion(t.accessToken)
                return
            }

            self.pendingRefreshes.append(completion)
            guard !self.isRefreshing else { return }

            guard let refreshToken = self.tokens?.refreshToken else {
                self.drainPendingRefreshes(with: nil)
                return
            }

            self.isRefreshing = true
            self.performRefresh(refreshToken: refreshToken)
        }
    }

    private func performRefresh(refreshToken: String) {
        var components = URLComponents(string: "\(Constants.oauthURL)/access_token")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.oauthClientID),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { data, response, error in
            var newToken: AuthTokenResponse?
            if let data = data, error == nil,
               (200..<300).contains((response as? HTTPURLResponse)?.statusCode ?? 0) {
                newToken = try? JSONDecoder().decode(AuthTokenResponse.self, from: data)
            }

            self.queue.async {
                self.isRefreshing = false
                if let newToken = newToken {
                    self.store(newToken)
                    self.drainPendingRefreshes(with: newToken.access_token)
                } else {
                    self.tokens = nil
                    self.drainPendingRefreshes(with: nil)
                }
            }
        }.resume()
    }

    private func drainPendingRefreshes(with token: String?) {
        let pending = pendingRefreshes
        pendingRefreshes = []
        for completion in pending {
            completion(token)
        }
    }

    // MARK: - Authorized requests

    func authorizedRequest(_ url: URL, retried: Bool = false, completion: @escaping (Result<Data, Error>) -> Void) {
        ensureValidAccessToken { [weak self] token in
            guard let self = self else { return }
            guard let token = token else {
                completion(.failure(AuthError.notAuthorized))
                return
            }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    completion(.failure(error ?? AuthError.failedToGetData))
                    return
                }

                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                if (status == 401 || status == 403), !retried {
                    self.invalidateToken()
                    self.authorizedRequest(url, retried: true, completion: completion)
                    return
                }

                guard (200..<300).contains(status) else {
                    completion(.failure(AuthError.notAuthorized))
                    return
                }

                completion(.success(data))
            }.resume()
        }
    }

    // MARK: - Data

    func fetchAuthUser(completion: @escaping (Result<CheckAuthResponse.AuthInfo, Error>) -> Void) {
        let url = URL(string: "\(Constants.oauthURL)/check")!
        authorizedRequest(url) { result in
            switch result {
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(CheckAuthResponse.self, from: data)
                    completion(.success(decoded.auth_info))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchStudentDetails(completion: @escaping (Result<StudentDetails, Error>) -> Void) {
        let url = URL(string: "\(Constants.baseURL)/general/v1/user/my")!
        authorizedRequest(url) { result in
            switch result {
            case .success(let data):
                do {
                    completion(.success(try JSONDecoder().decode(StudentDetails.self, from: data)))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchMarks(completion: @escaping (Result<[Mark], Error>) -> Void) {
        let url = URL(string: "\(Constants.baseURL)/general/v1/mark/my")!
        authorizedRequest(url) { result in
            switch result {
            case .success(let data):
                do {
                    completion(.success(try JSONDecoder().decode([Mark].self, from: data)))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
