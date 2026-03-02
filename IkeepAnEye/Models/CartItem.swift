import UIKit

struct CartItem: Identifiable {
    let id: UUID
    let product: Product
    let eyePhoto: EyePhoto?
    let compositeImage: UIImage?

    init(id: UUID = UUID(), product: Product, eyePhoto: EyePhoto? = nil, compositeImage: UIImage? = nil) {
        self.id = id
        self.product = product
        self.eyePhoto = eyePhoto
        self.compositeImage = compositeImage
    }
}
