//
//  Request.swift
//  moobby
//
//  Created by Maula Izza Azizi on 19/05/26.
//

/// The ``APIRequest/Body`` of requests that send no body. Return `nil` for it; a non-nil value would send `{}`.
public struct EmptyBody: Encodable {}

