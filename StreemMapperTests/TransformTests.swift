@testable import StreemMapper
import XCTest

private struct Example: Mappable, Equatable {
    let key: String
    let value: Int

    init(key: String, value: Int) {
        self.key = key
        self.value = value
    }

    init(map: Mapper) throws {
        try key = map.from(field: "string")
        try value = map.from(field: "value")
    }
}

private func == (lhs: Example, rhs: Example) -> Bool {
    return lhs.key == rhs.key && lhs.value == rhs.value
}

final class TransformTests: XCTestCase {
    func testToDictionary() {
        struct Test: Mappable {
            let dictionary: [String: Example]

            init(map: Mapper) throws {
                try dictionary = map.from(field: "examples", transformation: Transform.toDictionary(key: { $0.key }))
            }
        }

        let JSON = [
            "examples":
            [
                [
                    "string": "hi",
                    "value": 1
                ],
                [
                    "string": "bye",
                    "value": 2
                ]
            ]
        ]

        let test = Test.from(JSON: JSON)
        XCTAssertTrue(test?.dictionary.count == 2)
        XCTAssertTrue(test?.dictionary["hi"] == Example(key: "hi", value: 1))
        XCTAssertTrue(test?.dictionary["bye"] == Example(key: "bye", value: 2))
    }

    func testToDictionaryInvalid() {
        struct Test: Mappable {
            let dictionary: [String: Example]

            init(map: Mapper) throws {
                try dictionary = map.from(field: "examples", transformation: Transform.toDictionary(key: { $0.key }))
            }
        }

        do {
            _ = try Test(map: Mapper(JSON: ["examples": 1]))
            XCTFail("Dictionary parsing should throw")
        } catch MapperError.convertibleError(let value, let type) {
            XCTAssert(value as? Int == 1)
            XCTAssert(type == [[AnyHashable: Any]].self)
        } catch {
            XCTFail("Dictionary parsing throw the wrong error")
        }
    }

    func testToDictionaryOneInvalid() {
        struct Test: Mappable {
            let dictionary: [String: Example]

            init(map: Mapper) throws {
                try dictionary = map.from(field: "examples", transformation: Transform.toDictionary(key: { $0.key }))
            }
        }

        let JSON: [AnyHashable: Any] = ["examples": [
                    ["string": "hi", "value": 1],
                        ["string": "bye"]
                      ]
                   ]

        let test = try? Test(map: Mapper(JSON: JSON))
        XCTAssertNil(test)
    }

    func testMissingFieldErrorFromTransformation() {
        do {
            let map = Mapper(JSON: [:])
            let _: String = try map.from(field: "foo", transformation: { _ in return "hi" })
            XCTFail("Missing field parsing should throw")
        } catch MapperError.missingFieldError(let field) {
            XCTAssert(field == "foo")
        } catch {
            XCTFail("Missing field parsing threw the wrong erro")
        }
    }
}
