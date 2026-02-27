import UIKit

struct CartItem: Identifiable {
    let id: UUID
    let product: Product
    let irisPhoto: IrisPhoto?
    let compositeImage: UIImage?

    init(id: UUID = UUID(), product: Product, irisPhoto: IrisPhoto? = nil, compositeImage: UIImage? = nil) {
        self.id = id
        self.product = product
        self.irisPhoto = irisPhoto
        self.compositeImage = compositeImage
    }
}
