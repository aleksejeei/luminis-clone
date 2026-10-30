//
//  AccountModels.swift
//  YSTU_APP
//

import Foundation

struct AuthTokenResponse: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: TimeInterval
    let token_type: String?
    let expires_refresh_in: TimeInterval?
}

struct CheckAuthResponse: Codable {
    let auth_info: AuthInfo

    struct AuthInfo: Codable {
        let auth: Int
        let userId: Int?
        let user: User?
    }

    struct User: Codable {
        let id: Int?
        let firstName: String?
        let lastName: String?
        let patronymic: String?
        let fullName: String?
        let initials: String?
        let login: String?
        let birthday: String?
        let groupName: String?
        let photoUrl: String?
        let userId: Int?
    }
}

struct StudentDetails: Codable {
    let id: Int?
    let manId: Int?
    let recordBook: String?
    let course: Int?
    let groupId: Int?
    let sourceFinancingStr: String?
    let isContract: Bool?
    let isBudget: Bool?
    let man: Man?

    struct Man: Codable {
        let lastname: String?
        let firstname: String?
        let patronymic: String?
        let gender: String?
        let birthDate: String?
        let email: String?
        let telephone: String?
        let login: String?
    }
}

struct Mark: Codable {
    let inDiplom: Int?
    let markName: String?
    let mark: Double?
    let semester: Int?
    let controlTypeName: String?
    let years: String?
    let course: Int?
    let lessonName: String?
    let creditUnit: Double?
    let hasDebt: Int?
}
