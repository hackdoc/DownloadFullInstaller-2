//
//  SUCatalog.swift
//
//  Created by Armin Briegel on 2021-06-09
//

import Foundation

class SUCatalog: ObservableObject {
    var thisComponent: String { return String(describing: self) }

    @Published var catalog: Catalog?
    var products: [String: Product]? { return catalog?.products }

    @Published var installers = [Product]()
    var uniqueInstallersList: [String] = []

    @Published var isLoading = false
    @Published var hasLoaded = false

    init() {
        load()
    }

    func load() {
        uniqueInstallersList = []
        let catalogURLArray: [URL] = catalogURL(for: Prefs.seedProgram, for: Prefs.osNameID)

        catalogURLArray.forEach {
            let sessionConfig = URLSessionConfiguration.ephemeral
            let session = URLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)

            let task = session.dataTask(with: $0) { data, response, error in

                if error != nil {
                    print("### \(self.thisComponent) : \(error!.localizedDescription)")
                    return
                }

                let httpResponse = response as! HTTPURLResponse
                if httpResponse.statusCode != 200 {
//                    print("### \(self.thisComponent) : \(httpResponse.statusCode)")
                } else {
                    if data != nil {
//                        print("### \(self.thisComponent) : \(String(decoding: data!, as: UTF8.self))")
                        DispatchQueue.main.async {
                            self.decode(data: data!)
                        }
                    }
                }
            }
            isLoading = true
            hasLoaded = false
            self.catalog = nil
            self.installers = [Product]()
            task.resume()
        }

    }

    private func decode(data: Data) {
        isLoading = false
        hasLoaded = true

        let decoder = PropertyListDecoder()
        catalog = try! decoder.decode(Catalog.self, from: data)

        if let products = products {

            for (productKey, product) in products {
                product.key = productKey
                if let metainfo = product.extendedMetaInfo {
                    if metainfo.sharedSupport != nil {
                        if !uniqueInstallersList.contains(productKey) {
                            // this is an installer, add to list
                            uniqueInstallersList.append(productKey)
                            installers.append(product)
                            product.loadDistribution()
                        }
                    }
                }

            }

//            print("### \(self.thisComponent) : \(products.count) products found")
//            print("### \(self.thisComponent) : \(self.installers.count) installer pkgs found")

            sortInstallers()
        }
    }
    
    func sortInstallers() {
        let sortOrder = Prefs.sortOrder
        
        switch sortOrder {
        case .dateDescending:
            installers.sort { $0.postDate > $1.postDate }
        case .dateAscending:
            installers.sort { $0.postDate < $1.postDate }
        case .versionOrder:
            sortByVersionOrder()
        }
    }
    
    private func sortByVersionOrder() {
        // 定义版本排序的优先级，按照用户要求的顺序：Tahoe、Sequoia、Sonoma、Ventura、Monterey、Big Sur
        let versionPriority: [String: Int] = [
            "25": 1, // Tahoe
            "24": 2, // Sequoia
            "23": 3, // Sonoma
            "22": 4, // Ventura
            "21": 5, // Monterey
            "20": 6, // Big Sur
            "19": 7, // Catalina
            "18": 8, // Mojave
            "17": 9, // High Sierra
            "16": 10, // Sierra
            "15": 11, // El Capitan
            "14": 12, // Yosemite
            "13": 13, // Mavericks
            "12": 14, // Mountain Lion
            "11": 15, // Lion
        ]
        
        installers.sort { product1, product2 in
            // 获取两个产品的版本号
            let version1 = product1.darwinVersion
            let version2 = product2.darwinVersion
            
            // 获取优先级，如果没有找到则使用默认值100
            let priority1 = versionPriority[version1] ?? 100
            let priority2 = versionPriority[version2] ?? 100
            
            // 如果优先级不同，按优先级排序
            if priority1 != priority2 {
                return priority1 < priority2
            }
            
            // 如果优先级相同，按发布日期降序排序（最新的在前）
            return product1.postDate > product2.postDate
        }
    }
}
