import CSundials


/// Swift equivalent of generic `N_Vector` type but with value semantics.
///
/// The wrapper also provides access to `isKnownUniquelyReferenced(...)` call. This allows
/// the `N_Vector` struct to properly implement value semantics even though it stores a strong
/// reference to an instance of this wrapper and performs COW (Copy on Write) only when necessary.
public struct Vector {
    private var storage: ManagedPointer<_generic_N_Vector>

    /// Immutable, i.e. read-only, access to the underlying `N_Vector` storage C pointer.
    ///
    /// - Warning: This is an unsafe API and incorrect use causes hard to track bugs. Using
    /// `pointer` in place of the read-write `mutablePointer` leads to "spooky action from the
    /// distance" kind of bugs. Two separate `Vector` variables that should be following value
    /// semantics end up pointing to the identical, shared storage. When this happens, altering one
    /// value changes the other and vice-versa.
    ///
    /// - Note: In an ideal world, the type would be `UnsafePointer<_generic_N_Vector>`.
    /// However, _Sundials_ C API isn't const correct. Therefore using the true read-only, non-mutable
    /// pointer would cause problems at literally every call site. Every caller would have to convert the
    /// pointer into a mutable version anyway. This would lead to a lot of boilerplate code that wouldn't
    /// be any safer than using `UnsafeMutablePointer<_generic_N_Vector>`, aka
    /// `N_Vector`, directly.
    var pointer: N_Vector {
        get {
            return storage.pointer
        }
    }
    
    /// Mutable, i.e. read-write, access to the underlying `N_Vector` storage C pointer.
    ///
    /// - Warning: This is an unsafe API and its incorrect use causes performance problems. Using
    /// `mutablePointer` in places where a read-only `pointer` suffices leads to unnecessary
    ///  defensive copying. The copying is triggered by duplicated reference to the identical `storage`
    ///  instance.
    var mutablePointer: N_Vector {
        mutating get {
            if !isKnownUniquelyReferenced(&storage) {
                storage = storage.clone()
            }
            return pointer
        }
    }
    
    private var array: UnsafeBufferPointer<Element> {
        get {
            let arrayBase = N_VGetArrayPointer(pointer)
            assert(arrayBase != nil, "Can't obtain N_Vector array pointer")
            return UnsafeBufferPointer(start: arrayBase, count: count)
        }
    }

    private var mutableArray: UnsafeMutableBufferPointer<Element> {
        mutating get {
            let arrayBase = N_VGetArrayPointer(mutablePointer)
            assert(arrayBase != nil, "Can't obtain N_Vector array pointer")
            return UnsafeMutableBufferPointer(start: arrayBase, count: count)
        }
    }
    
    /// Own the pointer.
    init(manage vector: N_Vector) {
        storage = ManagedPointer(manage: vector)
    }
    
    init(borrow vector: N_Vector) {
        storage = ManagedPointer(borrow: vector)
    }
    
    /// Creates a fixed size vector.
    public init(size: Int) {
        let nVector = N_VNew_Serial(Index(size))
        assert(nVector != nil, "Can't create new N_Vector.")
        self.init(manage: nVector!)
    }
    
    /// Creates vector by copying components from an array.
    public init<T>(copy components: [T]) where T: BinaryFloatingPoint {
        self.init(size: components.count)
        for (i, component) in components.enumerated() {
            self[Index(i)] = realtype(component)
        }
    }
}


// MARK: - Conformance to Standard Protocols

extension Vector: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Double...) {
        self.init(size: elements.count)
        for (i, element) in elements.enumerated() {
            self[Index(i)] = element
        }
    }
}

extension Vector: CustomReflectable {
    public var customMirror: Mirror {
        let elements = Array(array)
        return Mirror(reflecting: elements)
    }

}

extension Vector: Collection {
    public typealias Index = sunindextype
    public typealias Element = realtype

    public var startIndex: Index { 0 }
    public var endIndex: Index { N_VGetLength(storage.pointer) }
    
    public func index(after i: Index) -> Index {
        return i + 1
    }
    
    public subscript(position: Index) -> Element {
        _read {
            yield array[Int(position)]
        }
        _modify {
            yield &mutableArray[Int(position)]
        }
        set {
            mutableArray[Int(position)] = newValue
        }
    }
}

extension Vector: Equatable {
    public static func == (lhs: Vector, rhs: Vector) -> Bool {
        if lhs.count == 0 && rhs.count == 0 { return true }
        if lhs.count != rhs.count { return false }

        return lhs.array.elementsEqual(rhs.array)        
    }
}


// MARK: - Algebraic Operations

extension Vector: AdditiveArithmetic {
    public static let zero = Vector(size: 0)

    public static func + (lhs: Vector, rhs: Vector) -> Vector {
        if lhs == .zero { return +rhs }
        if rhs == .zero { return lhs }
        assert(rhs.count == rhs.count, "Can't add vectors of unequal size.")

        var sum = lhs
        N_VLinearSum(+1, lhs.pointer, +1, rhs.pointer, sum.mutablePointer)
        return sum
    }

    public static func - (lhs: Vector, rhs: Vector) -> Vector {
        if lhs == .zero { return -rhs }
        if rhs == .zero { return lhs }
        assert(rhs.count == rhs.count, "Can't subtract vectors of unequal size.")
        
        var difference = lhs
        N_VLinearSum(+1, lhs.pointer, -1, rhs.pointer, difference.mutablePointer)
        return difference
    }
}

extension Vector {
    public static prefix func + (rhs: Vector) -> Vector {
        return rhs
    }
    
    public static prefix func - (rhs: Vector) -> Vector {
        var negated = rhs
        N_VScale(-1, rhs.pointer, negated.mutablePointer)
        return negated
    }
    
    public static func += (lhs: inout Vector, rhs: Vector) {
        if lhs.count == 0 { lhs = +rhs; return }
        if rhs.count == 0 { return }
        assert(rhs.count == rhs.count, "Can't add vectors of unequal size.")

        N_VLinearSum(+1, lhs.pointer, +1, rhs.pointer, lhs.pointer)
    }

    public static func -= (lhs: inout Vector, rhs: Vector) {
        if lhs.count == 0 { lhs = -rhs; return }
        if rhs.count == 0 { return }
        assert(rhs.count == rhs.count, "Can't subtract vectors of unequal size.")
    
        N_VLinearSum(+1, lhs.pointer, -1, rhs.pointer, lhs.pointer)
    }
    
    public static func * <Scalar>(lhs: Vector, rhs: Scalar) -> Vector
    where Scalar: BinaryFloatingPoint {
        if lhs.count == 0 { return lhs }

        var scaled = lhs
        N_VScale(Element(rhs), lhs.pointer, scaled.mutablePointer)
        return scaled
    }

    public static func * <Scalar>(lhs: Scalar, rhs: Vector) -> Vector
    where Scalar: BinaryFloatingPoint {
        if rhs.count == 0 { return rhs }

        var scaled = rhs
        N_VScale(Element(lhs), rhs.pointer, scaled.mutablePointer)
        return scaled
    }
}


// MARK: - Differentiation

#if canImport(_Differentiation)
import _Differentiation

extension Vector: Differentiable { }
#endif


// MARK: - Memory Management

extension _generic_N_Vector: Cloneable & Destructible {
    mutating func clone() -> UnsafeMutablePointer<_generic_N_Vector> {
        withUnsafeMutablePointer(to: &self) { myself in
            let copy = N_VClone(myself)
            assert(copy != nil, "Can't clone N_Vector.")
            N_VAddConst(myself, 0, copy)
            return copy!
        }
    }

    mutating func destroy() {
        withUnsafeMutablePointer(to: &self) { myself in
            N_VDestroy(myself)
        }
    }
}
