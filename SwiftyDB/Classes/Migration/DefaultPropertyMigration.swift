//
//  PropertyMigration.swift
//  SwiftyDB
//
//  Created by Øyvind Grimnes on 10/09/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation

/* Represents the migration of a single property */

internal class DefaultPropertyMigration: PropertyMigration {
    
    let propertyName: String
    var newPropertyName: String?
    
    var migration: _Migration
    
    var transformation: ((StorableValue?) -> StorableValue?)?
    
    init(propertyName: String, migration: _Migration) {
        self.propertyName = propertyName
        self.migration    = migration
    }
    
    func rename(to name: String) -> PropertyMigration {
        self.newPropertyName = name
        
        migration.operations.append(
            .rename(propertyName, name)
        )
        
        return self
    }
    
    func transformFromType<U : StorableProperty, V : StorableProperty>(_ type: U.Type, transformer: @escaping (U?) -> V?) -> PropertyMigration {
        let transformation: (StorableValue?) -> V.StorableValueType? = { storableValue in
            let previousValue: U? = self.valueFrom(storableValue: storableValue)
            
            return transformer(previousValue)?.storableValue
        }
        
        addTransformation(transformation)
        
        return self
    }
    
    
    // MARK: - Raw representables
    
    func transformFromType<U : RawRepresentable, V : RawRepresentable>(_ type: U.Type, transformer: @escaping (U?) -> V?) -> PropertyMigration where U.RawValue: StorableProperty, V.RawValue: StorableProperty {
        
        let transformation: (StorableValue?) -> V.RawValue.StorableValueType? = { storableValue in
            let previousValue: U? = self.rawRepresentableFrom(storableValue: storableValue)
            
            return transformer(previousValue)?.rawValue.storableValue
        }
        
        addTransformation(transformation)
        
        return self
    }
    
    func transformFromType<U : RawRepresentable, V : StorableProperty>(_ type: U.Type, transformer: @escaping (U?) -> V?) -> PropertyMigration where U.RawValue : StorableProperty {
        let transformation: (StorableValue?) -> V.StorableValueType? = { storableValue in
            let previousValue: U? = self.rawRepresentableFrom(storableValue: storableValue)
            
            return transformer(previousValue)?.storableValue
        }
        
        addTransformation(transformation)
        
        return self
    }
    
    func transformFromType<U : StorableProperty, V : RawRepresentable>(_ type: U.Type, transformer: @escaping (U?) -> V?) -> PropertyMigration where V.RawValue : StorableProperty {
        let transformation: (StorableValue?) -> V.RawValue.StorableValueType? = { storableValue in
            let previousValue: U? = self.valueFrom(storableValue: storableValue)
            
            return transformer(previousValue)?.rawValue.storableValue
        }
        
        addTransformation(transformation)
        
        return self
    }
    
    
    // MARK: - Helpers
    
    fileprivate func addTransformation(_ transformation: @escaping (StorableValue?) -> StorableValue?) {
        migration.operations.append(
            .transform(newPropertyName ?? propertyName, transformation)
        )
    }
    

    fileprivate func valueFrom<T: StorableProperty>(storableValue: StorableValue?) -> T? {
        guard let storableValue = storableValue as? T.StorableValueType else {
            return nil
        }
        
        return T.from(storableValue: storableValue)
    }
    
    fileprivate func rawRepresentableFrom<T: RawRepresentable>(storableValue: StorableValue?) -> T? where T.RawValue: StorableProperty {
        guard let storableValue = storableValue as? T.RawValue.StorableValueType else {
            return nil
        }
        
        let rawValue = T.RawValue.from(storableValue: storableValue)
        
        return T.init(rawValue: rawValue)
    }
}
