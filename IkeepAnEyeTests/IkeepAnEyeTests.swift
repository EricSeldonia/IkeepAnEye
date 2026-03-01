import XCTest
@testable import IkeepAnEye

final class IkeepAnEyeTests: XCTestCase {

    // MARK: - UIImage+Crop

    func testVisionRectToUIKit() {
        let imageSize = CGSize(width: 400, height: 600)
        // Vision rect: bottom-left origin, normalized
        // x=0.1, y=0.2, w=0.4, h=0.3  (occupies lower-left area in Vision space)
        let visionRect = CGRect(x: 0.1, y: 0.2, width: 0.4, height: 0.3)
        let result = UIImage.visionRectToUIKit(visionRect, imageSize: imageSize)

        XCTAssertEqual(result.origin.x, 0.1 * 400, accuracy: 0.001)
        // UIKit y = (1 - y - h) * height = (1 - 0.2 - 0.3) * 600 = 0.5 * 600 = 300
        XCTAssertEqual(result.origin.y, 300, accuracy: 0.001)
        XCTAssertEqual(result.width,  0.4 * 400, accuracy: 0.001)
        XCTAssertEqual(result.height, 0.3 * 600, accuracy: 0.001)
    }

    func testCircularCroppedIsSquare() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 150))
        let image = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 150))
        }
        let circular = image.circularCropped
        XCTAssertEqual(circular.size.width, circular.size.height)
        XCTAssertEqual(circular.size.width, 100)  // min dimension
    }

    // MARK: - Address

    func testAddressFormatted() {
        let address = Address(
            fullName: "Jane Doe",
            line1: "123 Main St",
            line2: "Apt 4",
            city: "Springfield",
            state: "IL",
            postalCode: "62701",
            country: "US"
        )
        let formatted = address.formatted
        XCTAssert(formatted.contains("Jane Doe"))
        XCTAssert(formatted.contains("123 Main St"))
        XCTAssert(formatted.contains("Apt 4"))
        XCTAssert(formatted.contains("Springfield"))
    }

    // MARK: - Product

    func testProductFormattedPrice() {
        let product = Product(
            name: "Silver Iris Pendant",
            description: "Test",
            priceInCents: 14999,
            images: [],
            pendantAnchorX: 0.5,
            pendantAnchorY: 0.5,
            pendantDiameterFraction: 0.1,
            material: "Sterling Silver",
            chain: ChainDetails(length: "18 inches", style: "Cable"),
            isActive: true,
            sortOrder: 1,
            createdAt: .init(),
            updatedAt: .init()
        )
        XCTAssertEqual(product.formattedPrice, "$149.99")
    }
}
