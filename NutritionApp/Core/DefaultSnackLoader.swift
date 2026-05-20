import Foundation

enum DefaultSnackLoader {
    static func loadBuiltInSnacks() throws -> [Snack] {
        guard let url = Bundle.main.url(forResource: "DefaultSnacks", withExtension: "json") else {
            throw LoaderError.missingResource
        }
        let data = try Data(contentsOf: url)
        let file = try JSONDecoder().decode(DefaultSnacksFile.self, from: data)
        return file.snacks.map { $0.toSnack() }
    }

    enum LoaderError: Error {
        case missingResource
    }
}
