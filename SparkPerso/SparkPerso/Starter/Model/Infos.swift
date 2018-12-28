//
//  Infos.swift
//
//  Created by AL on 23/02/2018
//  Copyright (c) . All rights reserved.
//

import Foundation

public class Infos {

  // MARK: Declaration for string constants to be used to decode and also serialize.
  private struct SerializationKeys {
    static let durationInSeconds = "durationInSeconds"
    static let movementDirection = "movementDirection"
  }

  // MARK: Properties
  public var durationInSeconds: Float?
  public var movementDirection: Int?

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
    durationInSeconds = json[SerializationKeys.durationInSeconds].float
    movementDirection = json[SerializationKeys.movementDirection].int
  }

  /// Generates description of the object in the form of a NSDictionary.
  ///
  /// - returns: A Key value pair containing all valid values in the object.
  public func dictionaryRepresentation() -> [String: Any] {
    var dictionary: [String: Any] = [:]
    if let value = durationInSeconds { dictionary[SerializationKeys.durationInSeconds] = value }
    if let value = movementDirection { dictionary[SerializationKeys.movementDirection] = value }
    return dictionary
  }

}
