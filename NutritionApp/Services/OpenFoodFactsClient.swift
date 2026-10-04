import Foundation

struct ScannedProductNutrition: Sendable, Equatable {
    var nameEN: String
    var nameDE: String
    var nutritionBasis: SnackNutritionBasis
    var carbsPerServing: Double
    var sodiumMgPerServing: Double
    var defaultPortionGrams: Double?
    var isLiquid: Bool
    var barcode: String
}

enum OpenFoodFactsClient {
    enum ClientError: Error, Equatable {
        case invalidBarcode
        case invalidResponse
        case productNotFound
        case missingNutrition
    }

    private static let baseURL = URL(string: "https://world.openfoodfacts.org/api/v2/product")!
    /// Open Food Facts asks API clients to identify themselves.
    private static let userAgent = "FuelZone/1.0 (iOS; support@fuelzone.app)"
    private static let validBarcodeLengths = 8...14

    static func fetchProduct(barcode rawBarcode: String, session: URLSession = .shared) async throws -> ScannedProductNutrition {
        let barcode = rawBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validBarcodeLengths.contains(barcode.count), barcode.allSatisfy(\.isASCIIDigit) else {
            throw ClientError.invalidBarcode
        }

        var request = URLRequest(url: baseURL.appendingPathComponent("\(barcode).json"))
        request.timeoutInterval = 15
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ClientError.invalidResponse }
        guard http.statusCode == 200 else {
            throw http.statusCode == 404 ? ClientError.productNotFound : ClientError.invalidResponse
        }
        let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
        guard decoded.status == 1, let product = decoded.product else {
            throw ClientError.productNotFound
        }
        return try product.toNutrition(barcode: barcode)
    }

    /// Parses an Open Food Facts `serving_size` such as "1 bar (40 g)", "40g", "250 ml" or "2 x 25 g".
    /// Returns the amount in grams (or millilitres for drinks) and whether it is a liquid.
    nonisolated static func servingAmount(from text: String) -> (amount: Double, isLiquid: Bool)? {
        let normalized = text.lowercased().replacingOccurrences(of: ",", with: ".")
        let pattern = #"(\d+(?:\.\d+)?)\s*(g|ml|cl|l)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(normalized.startIndex..., in: normalized)
        let matches = regex.matches(in: normalized, range: range)

        // "2 x 25 g": multiply a leading count with the unit amount.
        if let multiplied = multipliedAmount(in: normalized) { return multiplied }

        // Prefer the last amount with a unit ("1 bar (40 g)" → 40 g).
        guard let match = matches.last,
              let valueRange = Range(match.range(at: 1), in: normalized),
              let unitRange = Range(match.range(at: 2), in: normalized),
              let value = Double(normalized[valueRange]), value > 0 else { return nil }
        switch normalized[unitRange] {
        case "ml": return (value, true)
        case "cl": return (value * 10, true)
        case "l": return (value * 1000, true)
        default: return (value, false)
        }
    }

    nonisolated private static func multipliedAmount(in text: String) -> (amount: Double, isLiquid: Bool)? {
        let pattern = #"^\s*(\d+)\s*[x×]\s*(\d+(?:\.\d+)?)\s*(g|ml)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let countRange = Range(match.range(at: 1), in: text),
              let valueRange = Range(match.range(at: 2), in: text),
              let unitRange = Range(match.range(at: 3), in: text),
              let count = Double(text[countRange]),
              let value = Double(text[valueRange]) else { return nil }
        return (count * value, text[unitRange] == "ml")
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
    let productNameEn: String?
    let servingSize: String?
    let nutriments: OFFNutriments?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case productNameDe = "product_name_de"
        case productNameEn = "product_name_en"
        case servingSize = "serving_size"
        case nutriments
    }

    func toNutrition(barcode: String) throws -> ScannedProductNutrition {
        guard let carbs100 = nutriments?.carbohydrates100g, carbs100 >= 0 else {
            throw OpenFoodFactsClient.ClientError.missingNutrition
        }
        let fallbackName = nonEmpty(productNameEn) ?? nonEmpty(productName) ?? "Product \(barcode)"
        let sodiumGrams100 = nutriments?.sodium100g ?? nutriments?.salt100g.map { $0 / 2.5 } ?? 0
        let serving = servingSize.flatMap(OpenFoodFactsClient.servingAmount(from:))
        let portion = serving?.amount ?? inferredGramsFromServingCarbs(carbs100: carbs100)

        return ScannedProductNutrition(
            nameEN: fallbackName,
            nameDE: nonEmpty(productNameDe) ?? nonEmpty(productName) ?? fallbackName,
            nutritionBasis: .per100g,
            carbsPerServing: carbs100,
            sodiumMgPerServing: max(0, sodiumGrams100 * 1000),
            defaultPortionGrams: portion,
            isLiquid: serving?.isLiquid ?? false,
            barcode: barcode
        )
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
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
    let salt100g: Double?

    enum CodingKeys: String, CodingKey {
        case carbohydrates100g = "carbohydrates_100g"
        case carbohydratesServing = "carbohydrates_serving"
        case sodium100g = "sodium_100g"
        case salt100g = "salt_100g"
    }
}

private extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}
