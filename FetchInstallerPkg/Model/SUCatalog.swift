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

            // Sort installers according to user preference
            sortInstallers()
        }

    }

    /// Sort installers according to Prefs.sortOrder
    func sortInstallers() {
        switch Prefs.sortOrder {
        case .postDate:
            installers.sort { $0.postDate > $1.postDate }

        case .productVersion:
            installers.sort { a, b in
                // compare semantic-style productVersion first, fallback to postDate
                let va = versionComponents(from: a.productVersion)
                let vb = versionComponents(from: b.productVersion)
                if va.count == 0 && vb.count == 0 {
                    return a.postDate > b.postDate
                } else if va.count == 0 {
                    return false
                } else if vb.count == 0 {
                    return true
                } else {
                    return compareVersionComponents(va, vb)
                }
            }

        case .buildVersion:
            installers.sort { a, b in
                let av = a.buildVersion ?? ""
                let bv = b.buildVersion ?? ""
                if av.isEmpty && bv.isEmpty {
                    return a.postDate > b.postDate
                } else if av.isEmpty {
                    return false
                } else if bv.isEmpty {
                    return true
                } else {
                    // use localizedStandardCompare to respect numeric parts
                    let ord = (av as NSString).localizedStandardCompare(bv)
                    if ord == .orderedSame {
                        return a.postDate > b.postDate
                    }
                    return ord == .orderedDescending
                }
            }
        }
    }

    private func versionComponents(from s: String?) -> [Int] {
        guard let s = s else { return [] }
        // split by dots and non-digit, keep numeric parts
        let parts = s.split{ !$0.isNumber && $0 != "." }.map { String($0) }
        var comps: [Int] = []
        for part in parts {
            let nums = part.split(separator: ".").map { String($0) }
            for n in nums {
                if let iv = Int(n) { comps.append(iv) }
            }
        }
        return comps
    }

    private func compareVersionComponents(_ a: [Int], _ b: [Int]) -> Bool {
        let n = max(a.count, b.count)
        for i in 0..<n {
            let ai = i < a.count ? a[i] : 0
            let bi = i < b.count ? b[i] : 0
            if ai != bi { return ai > bi }
        }
        return false
    }
}
