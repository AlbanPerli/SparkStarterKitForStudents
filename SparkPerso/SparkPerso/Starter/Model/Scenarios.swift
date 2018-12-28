//
//  Scenarios.swift
//
//  Created by AL on 23/02/2018
//  Copyright (c) . All rights reserved.
//

import Foundation

public class Scenarios {

  // MARK: Declaration for string constants to be used to decode and also serialize.
  private struct SerializationKeys {
    static let name = "name"
    static let infos = "infos"
  }

  // MARK: Properties
  public var name: String?
  public var infos: [Infos]?

  // MARK: SwiftyJSON Initializers
  /// Initiates the instance based on the object.
  ///
  /// - parameter object: The object of either Dictionary or Array kind that was passed.
  /// - returns: An initialized instance of the class.
  public convenience init(object: Any) {
    self.init(json: JSON(object))
  }

  /// Initiates the instance based on the JSON that was passed.
  ///
  /// - parameter json: JSON object from SwiftyJSON.
  public required init(json: JSON) {
    name = json[SerializationKeys.name].string
    if let items = json[SerializationKeys.infos].array { infos = items.map { Infos(json: $0) } }
  }

  /// Generates description of the object in the form of a NSDictionary.
  ///
  /// - returns: A Key value pair containing all valid values in the object.
  public func dictionaryRepresentation() -> [String: Any] {
    var dictionary: [String: Any] = [:]
    if let value = name { dictionary[SerializationKeys.name] = value }
    if let value = infos { dictionary[SerializationKeys.infos] = value.map { $0.dictionaryRepresentation() } }
    return dictionary
  }

}
