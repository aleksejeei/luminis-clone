//
//  APICaller.swift
//  YSTU_APP
//
//  Created by Alex Neumark on 23.09.2024.
//


import Foundation

struct Constants {
    static let defaultGroup = "ЦПИ-11"
    static let selectedGroupKey = "selectedGroup"
    static let baseURL = "https://gg-api.ystuty.ru/s"
}

enum APIError: Error {
    case failedToGetData
}

class APICaller {
    static let shared = APICaller()

    var selectedGroup: String {
        get { UserDefaults.standard.string(forKey: Constants.selectedGroupKey) ?? Constants.defaultGroup }
        set { UserDefaults.standard.set(newValue, forKey: Constants.selectedGroupKey) }
    }

    private let queue = DispatchQueue(label: "APICaller.schedule")
    private var itemsCache: (group: String, items: [Item])?
    private var isFetchingSchedule = false
    private var pendingScheduleRequests: [(Date, (Result<[Lesson], Error>) -> Void)] = []

    func getSchedule(for date: Date, completion: @escaping (Result<[Lesson], Error>) -> Void) {
        queue.async {
            if let cache = self.itemsCache, cache.group == self.selectedGroup {
                completion(.success(self.filterLessons(for: date, from: cache.items)))
                return
            }

            self.pendingScheduleRequests.append((date, completion))
            guard !self.isFetchingSchedule else { return }
            self.isFetchingSchedule = true
            self.fetchSchedule(group: self.selectedGroup)
        }
    }

    private func fetchSchedule(group: String) {
        let encoded = group.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? group
        guard let url = URL(string: "\(Constants.baseURL)/schedule/v1/schedule/group/\(encoded)") else {
            finishScheduleFetch(group: group, items: nil, error: APIError.failedToGetData)
            return
        }

        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
            if let error = error {
                print("Network error: \(error)")
                self.finishScheduleFetch(group: group, items: nil, error: error)
                return
            }

            guard let data = data else {
                print("No data received")
                self.finishScheduleFetch(group: group, items: nil, error: APIError.failedToGetData)
                return
            }

            do {
                let results = try JSONDecoder().decode(LessonsResponse.self, from: data)
                print("Received \(results.items.count) items from API")
                self.finishScheduleFetch(group: group, items: results.items, error: nil)
            } catch {
                print("Decoding error: \(error)")
                self.finishScheduleFetch(group: group, items: nil, error: error)
            }
        }

        task.resume()
    }

    private func finishScheduleFetch(group: String, items: [Item]?, error: Error?) {
        queue.async {
            self.isFetchingSchedule = false
            if let items = items {
                self.itemsCache = (group, items)
            }

            let pending = self.pendingScheduleRequests
            self.pendingScheduleRequests = []
            for (date, completion) in pending {
                if let items = items {
                    completion(.success(self.filterLessons(for: date, from: items)))
                } else {
                    completion(.failure(error ?? APIError.failedToGetData))
                }
            }
        }
    }
    
    private func filterLessons(for date: Date, from items: [Item]) -> [Lesson] {
        let calendar = Calendar.current
        var lessonsForSelectedDay: [Lesson] = []
        
        for item in items {
            for day in item.days {
                // Преобразуем строку даты в объект Date
                if let dayDate = day.info.formDateFromString() {
                    if calendar.isDate(dayDate, inSameDayAs: date) {
                        lessonsForSelectedDay.append(contentsOf: day.lessons)
                    }
                } else {
                    print("Failed to parse date: \(day.info.date ?? "nil")")
                }
            }
        }
        
        print("Filtered \(lessonsForSelectedDay.count) lessons for date: \(date)")
        return lessonsForSelectedDay
    }
    
    func getGroupsList(completion: @escaping (Result<[GroupSection], Error>) -> Void) {
        guard let url = URL(string: "\(Constants.baseURL)/schedule/v1/schedule/actual_groups?additional=false") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        let task = URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let results = try JSONDecoder().decode(GroupsListResponse.self, from: data)
                let sections = results.items.compactMap { item -> GroupSection? in
                    guard let name = item.name, let groups = item.groups else { return nil }
                    return GroupSection(title: name, groups: groups)
                }
                completion(.success(sections))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }

}

    
