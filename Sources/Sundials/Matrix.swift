import CSundials


/// Swift equivalent of `SUNMatrix` type but with value semantics.
///
/// The wrapper also provides access to `isKnownUniquelyReferenced(..)` call. This allows
/// the `SUNMatrix` struct to properly implement value semantics even though it stores a strong
/// reference to an instance of this wrapper and performs COW (Copy on Write) only when necessary.
public struct Matrix {
    private var storage: ManagedPointer<_generic_SUNMatrix>
    
    /// Immutable, i.e. read-only, access to the underlying `SUNMatrix` storage C pointer.
    ///
    /// - Warning: This is an unsafe API and incorrect use causes hard to track bugs. Using
    /// `pointer` in place of the read-write `mutablePointer` leads to "spooky action from the
    /// distance" kind of bugs. Two separate `Matrix` variables that should be following value
    /// semantics end up pointing to the identical, shared storage. When this happens, altering one
    /// value changes the other and vice-versa.
    ///
    /// - Note: In an ideal world, the type would be `UnsafePointer<_generic_SUNMatrix>`.
    /// However, _Sundials_ C API isn't const correct. Therefore using the true read-only, non-mutable
    /// pointer would cause problems at literally every call site. Every caller would have to convert the
    /// pointer into a mutable version anyway. This would lead to a lot of boilerplate code that wouldn't
    /// be any safer than using `UnsafeMutablePointer<_generic_SUNMatrix>`, aka
    /// `SUNMatrix`, directly.
    var pointer: SUNMatrix {
        get {
            return storage.pointer
        }
    }
    
    /// Mutable, i.e. read-write, access to the underlying `SUNMatrix` storage C pointer.
    ///
    /// - Warning: This is an unsafe API and its incorrect use causes performance problems. Using
    /// `mutablePointer` in places where a read-only `pointer` suffices leads to unnecessary
    ///  defensive copying. The copying is triggered by duplicated reference to the identical `storage`
    ///  instance.
    var mutablePointer: SUNMatrix {
        mutating get {
            if !isKnownUniquelyReferenced(&storage) {
                storage = storage.clone()
            }
            return pointer
        }
    }
    
    // TODO: Docs
    public var rows: Index {
        SUNDenseMatrix_Rows(pointer)
    }
    
    // TODO: Docs
    public var columns: Index {
        SUNDenseMatrix_Columns(pointer)
    }
    
    public init(manage matrix: SUNMatrix) {
        storage = ManagedPointer(manage: matrix)
    }

    public init(borrow matrix: SUNMatrix) {
        storage = ManagedPointer(borrow: matrix)
    }
    
    // TODO: Docs
    public init(rows m: Int, columns n: Int) {
        if m == 0 || n == 0 {
            let template = SUNDenseMatrix(1, 1)
            assert(template != nil, "Can't create new template Matrix.")
            defer { SUNMatDestroy(template) }

            let zeroMatrix = SUNMatNewEmpty()
            assert(zeroMatrix != nil, "Can't create new zero SUNMatrix.")
            let flag = SUNMatCopyOps(template, zeroMatrix)
            assert(flag == SUNMAT_SUCCESS, "Can't copy template ops Matrix.")
        
            let content = SUNMatrixContent_Dense.allocate(capacity: 1)
            content.pointee.M = sunindextype(m)
            content.pointee.N = sunindextype(n)
            content.pointee.ldata = sunindextype(m * n)
            content.pointee.data = nil
            content.pointee.cols = nil
            zeroMatrix!.pointee.content = UnsafeMutableRawPointer(content)

            self.init(manage: zeroMatrix!)
            return
        }
 
        let sunMatrix = SUNDenseMatrix(sunindextype(m), sunindextype(n))
        assert(sunMatrix != nil, "Can't create new SUNMatrix.")
        self.init(manage: sunMatrix!)
    }
    
    // TODO: Docs
    public subscript(row: Index, column: Index) -> realtype {
        _read {
            let column = SUNDenseMatrix_Column(pointer, column)
            assert(column != nil, "Can't access column." )
            yield column![Int(row)]
        }
        _modify {
            let column = SUNDenseMatrix_Column(mutablePointer, column)
            assert(column != nil, "Can't access column." )
            yield &column![Int(row)]
        }
        set {
            let column = SUNDenseMatrix_Column(mutablePointer, column)
            assert(column != nil, "Can't access column." )
            column![Int(row)] = newValue
        }
    }
}


// MARK: - Conformance to Standard Protocols

extension Matrix: Collection {
    public typealias Index = sunindextype
    public typealias Element = UnsafeBufferPointer<realtype>

    public var startIndex: Index { 0 }
    public var endIndex: Index { columns }
    
    public func index(after i: Index) -> Index {
        return i + 1
    }

    public subscript(column: Index) -> Element {
        _read {
            let column = SUNDenseMatrix_Column(pointer, column)
            yield UnsafeBufferPointer(start: column, count: Int(rows))
        }
        set {
            assert(newValue.count == rows, "Can't replace column.")
            let column = SUNDenseMatrix_Column(pointer, column)
            let columnBuffer = UnsafeMutableBufferPointer(start: column, count: Int(rows))
            
            for (i, value) in zip(columnBuffer.indices, newValue) {
                columnBuffer[i] = value
            }
        }
    }
}

extension Matrix: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: [Double]...) {
        let equalLengths = elements.allSatisfy { $0.count == elements[0].count}
        assert(equalLengths, "Vectors of unequal length can't form a Matrix.")
        
        self.init(rows: elements.count, columns: elements[0].count)
        for (i, element) in elements.enumerated() {
            for (j, value) in element.enumerated() {
                self[Index(i), Index(j)] = value
            }
        }
    }
}

extension Matrix: Equatable {
    public static func == (lhs: Matrix, rhs: Matrix) -> Bool {
        if lhs.rows != rhs.rows { return false }
        if lhs.columns != rhs.columns { return false }
        
        let count = SUNDenseMatrix_LData(lhs.pointer)
        let lhsData = SUNDenseMatrix_Data(lhs.pointer)
        let rhsData = SUNDenseMatrix_Data(rhs.pointer)
        
        if lhsData == nil && rhsData == nil { return true }
        if lhsData == nil || rhsData == nil { return false }
        
        let lhsBuffer = UnsafeBufferPointer(start: lhsData!, count: Int(count))
        let rhsBuffer = UnsafeBufferPointer(start: rhsData!, count: Int(count))
    
        return lhsBuffer.elementsEqual(rhsBuffer)
    }
}


// MARK: - Algebraic Operations

extension Matrix {
    public static prefix func + (rhs: Matrix) -> Matrix {
        return rhs
    }
    
    public static prefix func - (rhs: Matrix) -> Matrix {
        var zero = rhs
        var flag = SUNMatZero(zero.mutablePointer)
        assert(flag == SUNMAT_SUCCESS, "Matrix zeroing failed.")

        var negated = rhs
        flag = SUNMatScaleAdd(-1, negated.mutablePointer, zero.pointer)
        assert(flag == SUNMAT_SUCCESS, "Matrix scaling operation failed.")
        
        return negated
    }

    public static func += (lhs: inout Matrix, rhs: Matrix) {
        if lhs.rows == 0 && lhs.columns == 0 { lhs = +rhs; return }
        if rhs.rows == 0 && rhs.columns == 0 { return }
        assert(lhs.rows == rhs.rows, "Can't add matrices of unequal size.")
        assert(lhs.columns == rhs.columns, "Can't add matrices of unequal size.")

        let flag = SUNMatScaleAdd(+1, lhs.mutablePointer, rhs.pointer)
        assert(flag == SUNMAT_SUCCESS, "Matrix scaling operation failed.")
    }

    public static func -= (lhs: inout Matrix, rhs: Matrix) {
        if lhs.rows == 0 && lhs.columns == 0 { lhs = -rhs; return }
        if rhs.rows == 0 && rhs.columns == 0 { return }
        assert(lhs.rows == rhs.rows, "Can't add matrices of unequal size.")
        assert(lhs.columns == rhs.columns, "Can't add matrices of unequal size.")

        let negRhs = -rhs
        let flag = SUNMatScaleAdd(+1, lhs.mutablePointer, negRhs.pointer)
        assert(flag == SUNMAT_SUCCESS, "Matrix scaling operation failed.")
    }
}

extension Matrix: AdditiveArithmetic {
    public static let zero = Matrix(rows: 0, columns: 0)

    public static func + (lhs: Matrix, rhs: Matrix) -> Matrix {
        if lhs == .zero { return +rhs }
        if rhs == .zero { return lhs }
        assert(lhs.rows == rhs.rows, "Can't add matrices of unequal size.")
        assert(lhs.columns == rhs.columns, "Can't add matrices of unequal size.")

        var result = lhs
        result += rhs
        return result
    }

    public static func - (lhs: Matrix, rhs: Matrix) -> Matrix {
        if lhs == .zero { return -rhs }
        if rhs == .zero { return lhs }
        assert(lhs.rows == rhs.rows, "Can't add matrices of unequal size.")
        assert(lhs.columns == rhs.columns, "Can't add matrices of unequal size.")

        var result = lhs
        result -= rhs
        return result
    }
}


// MARK: - Differentiation

#if canImport(_Differentiation)
import _Differentiation

extension Matrix: Differentiable { }
#endif


// MARK: - Memory Management

extension _generic_SUNMatrix: Cloneable & Destructible {
    mutating func clone() -> UnsafeMutablePointer<_generic_SUNMatrix> {
        withUnsafeMutablePointer(to: &self) { myself in
            let copy = SUNMatClone(myself)
            assert(copy != nil, "Can't clone SUNMatrix.")
            let flag = SUNMatCopy(myself, copy)
            assert(flag == SUNMAT_SUCCESS, "Can't copy SUNMatrix values.")
            return copy!
        }
    }

    mutating func destroy() {
        withUnsafeMutablePointer(to: &self) { myself in
            SUNMatDestroy(myself)
        }
    }
}
