import Foundation

struct ScannedProductNutrition: Sendable {
    var nameEN: String
    var nameDE: String
    var carbsPerServing: Double
    var sodiumMgPerServing: Double
    var barcode: String
}

enum OpenFoodFactsClient {
    enum ClientError: Error {
        case invalidResponse
        case productNotFound
    }

    private static let baseURL = "https://world.openfoodfacts.org/api/v2/product"

    static func fetchProduct(barcode: String) async throws -> ScannedProductNutrition {
        guard let url = URL(string: "\(baseURL)/\(barcode).json") else {
            throw ClientError.invalidResponse
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClientError.productNotFound
        }
        let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
        guard decoded.status == 1, let product = decoded.product else {
            throw ClientError.productNotFound
        }
        return product.toNutrition(barcode: barcode)
    }
}

// MARK: - API models

private struct OFFResponse: Decodable {
    let status: Int
    let product: OFFProduct?
}

private struct OFFProduct: Decodable {
    let productName: String?
    let productNameDe: String?
    let nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameDe = "product_name_de"
        case nutriments
    }

    func toNutrition(barcode: String) -> ScannedProductNutrition {
        let carbs = nutriments?.carbohydrates100g ?? nutriments?.carbohydratesServing ?? 0
        let sodiumG = nutriments?.sodium100g ?? (nutriments?.sodiumServing ?? 0)
        let name = productName ?? "Product \(barcode)"
        return ScannedProductNutrition(
            nameEN: name,
            nameDE: productNameDe ?? name,
            carbsPerServing: max(0, carbs),
            sodiumMgPerServing: max(0, sodiumG * 1000),
            barcode: barcode
        )
    }
}

private struct OFFNutriments: Decodable {
    let carbohydrates100g: Double?
    let carbohydratesServing: Double?
    let sodium100g: Double?
    let sodiumServing: Double?

    enum CodingKeys: String, CodingKey {
        case carbohydrates100g = "carbohydrates_100g"
        case carbohydratesServing = "carbohydrates_serving"
        case sodium100g = "sodium_100g"
        case sodiumServing = "sodium_serving"
    }
}
