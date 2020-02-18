import Foundation
import Combine
import Common
import CypherPoetNetStack


public protocol NumbersAPIServicing {
    var session: URLSession { get }
    var apiQueue: DispatchQueue { get }
    
    
    func fetchNumberFact(
        at endpoint: Endpoint,
        using decoder: JSONDecoder
    ) -> AnyPublisher<NumberFact, NumbersAPIServiceError>
    
    
    func fetchRandomYearFact(
        using decoder: JSONDecoder
    ) -> AnyPublisher<NumberFact, NumbersAPIServiceError>
        
    
    func fetchRandomDateFact(
        using decoder: JSONDecoder
    ) -> AnyPublisher<NumberFact, NumbersAPIServiceError>
    
    
    func fetchRandomNumberTrivia(
        using decoder: JSONDecoder
    ) -> AnyPublisher<NumberFact, NumbersAPIServiceError>
    
    
    func fetchRandomMathFact(
        using decoder: JSONDecoder
    ) -> AnyPublisher<NumberFact, NumbersAPIServiceError>
}



// MARK: - Default Implementation
extension NumbersAPIServicing {
    
    public func fetchNumberFact(
        at endpoint: Endpoint,
        using decoder: JSONDecoder
    ) -> AnyPublisher<NumberFact, NumbersAPIServiceError> {
        guard let url = endpoint.url else {
            preconditionFailure("Unable to make url for endpoint")
        }
        
        return session
            .dataTaskPublisher(for: url)
            .receive(on: apiQueue)
            .mapError( { NetStackError.requestFailed(error: $0) })
            .tryMap { (data: Data, response: URLResponse) in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetStackError.missingResponse
                }
                
                if case let .failure(error) = NetStackError.parseFrom(data, and: httpResponse) {
                    throw error
                }
                
                guard
                    let number = Int(httpResponse.value(forHTTPHeaderField: "X-Numbers-API-Number") ?? ""),
                    let numberFactCategoryValue = httpResponse.value(forHTTPHeaderField: "X-Numbers-API-Type"),
                    let numberFactCategory = NumberFact.Category(rawValue: numberFactCategoryValue),
                    let numberFactText = String(data: data, encoding: .utf8)
                else {
                    throw NumbersAPIServiceError.parsing(response: httpResponse, data: data)
                }
                
                return NumberFact(
                    number: number,
                    category: numberFactCategory,
                    text: numberFactText
                )
            }
            .mapError { error in
                if let error = error as? NumbersAPIServiceError {
                    return error
                } else if let error = error as? NetStackError {
                    return NumbersAPIServiceError.network(error: error)
                } else {
                    return .generic(error: error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    
    public func fetchRandomYearFact(
        using decoder: JSONDecoder = NumberFact.Decoder.default
    ) -> AnyPublisher<NumberFact, NumbersAPIServiceError> {
        fetchNumberFact(at: Endpoint.NumbersAPI.randomYearFact, using: decoder)
    }
    
    
    public func fetchRandomDateFact(using decoder: JSONDecoder) -> AnyPublisher<NumberFact, NumbersAPIServiceError> {
        fetchNumberFact(at: Endpoint.NumbersAPI.randomDateFact, using: decoder)
    }
    
    
    public func fetchRandomNumberTrivia(using decoder: JSONDecoder) -> AnyPublisher<NumberFact, NumbersAPIServiceError> {
        fetchNumberFact(at: Endpoint.NumbersAPI.randomTriviaFact, using: decoder)
    }
    
    
    public func fetchRandomMathFact(using decoder: JSONDecoder) -> AnyPublisher<NumberFact, NumbersAPIServiceError> {
        fetchNumberFact(at: Endpoint.NumbersAPI.randomMathFact, using: decoder)
    }
}
