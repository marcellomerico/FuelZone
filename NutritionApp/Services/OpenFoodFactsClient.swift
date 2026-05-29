import Foundation

struct ScannedProductNutrition: Sendable {
    var nameEN: String
    var nameDE: String
    var nutritionBasis: SnackNutritionBasis
    var carbsPerServing: Double
    var sodiumMgPerServing: Double
    var defaultPortionGrams: Double?
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
    let servingSize: String?
    let nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameDe = "product_name_de"
        case servingSize = "serving_size"
        case nutriments
    }

    func toNutrition(barcode: String) -> ScannedProductNutrition {
        let name = productName ?? "Product \(barcode)"
        let carbs100 = nutriments?.carbohydrates100g ?? 0
        let sodiumMg100 = max(0, (nutriments?.sodium100g ?? 0) * 1000)
        let portionGrams = parsedServingGrams()
            ?? inferredGramsFromServingCarbs(carbs100: carbs100)

        return ScannedProductNutrition(
            nameEN: name,
            nameDE: productNameDe ?? name,
            nutritionBasis: .per100g,
            carbsPerServing: max(0, carbs100),
            sodiumMgPerServing: sodiumMg100,
            defaultPortionGrams: portionGrams,
            barcode: barcode
        )
    }

    private func parsedServingGrams() -> Double? {
        guard let servingSize else { return nil }
        let digits = servingSize
            .replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." }
        if let value = Double(digits), value > 0 { return value }
        if servingSize.lowercased().contains("ml"),
           let ml = Double(digits), ml > 0 { return ml }
        return nil
    }

    private func inferredGramsFromServingCarbs(carbs100: Double) -> Double? {
        guard let servingCarbs = nutriments?.carbohydratesServing, servingCarbs > 0, carbs100 > 0 else {
            return nil
        }
        return servingCarbs * 100 / carbs100
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
