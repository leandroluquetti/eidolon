import Foundation
import RxSwift
import Stripe

protocol Tokenable {
    var tokenId: String { get }
    var card: STPCard? { get }
}

extension STPToken: Tokenable { }

protocol Clientable {
    func createToken(withCard card: STPCardParams, completion: ((Tokenable?, Error?) -> Void)?)
}
extension STPAPIClient: Clientable {
    func createToken(withCard card: STPCardParams, completion: ((Tokenable?, Error?) -> Void)?) {
        self.createToken(withCard: card) { (token, error) in
            completion?(token, error)
        }
    }
}

class StripeManager: NSObject {
    var stripeClient: Clientable = STPAPIClient.shared()

    func registerCard(digits: String, month: UInt, year: UInt, securityCode: String, postalCode: String) -> Observable<Tokenable> {
        let card = STPCardParams()
        card.number = digits
        card.expMonth = month
        card.expYear = year
        card.cvc = securityCode
        card.addressZip = postalCode

        return Observable.create { [weak self] observer in
            guard let me = self else {
                observer.onCompleted()
                return Disposables.create()
            }

            me.stripeClient.createToken(withCard: card) { (token, error) in
                if let token = token {
                    observer.onNext(token)
                    observer.onCompleted()
                } else {
                    observer.onError(error!)
                }
            }

            return Disposables.create()
        }
    }

    func stringIsCreditCard(_ cardNumber: String) -> Bool {
        return STPCard.validateNumber(cardNumber)
    }
}

extension STPCardBrand {
    var name: String? {
        switch self {
        case .visa:
            return "Visa"
        case .amex:
            return "American Express"
        case .masterCard:
            return "MasterCard"
        case .discover:
            return "Discover"
        case .JCB:
            return "JCB"
        case .dinersClub:
            return "Diners Club"
        default:
            return nil
        }
    }
}
