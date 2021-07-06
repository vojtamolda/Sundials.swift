
/// Swift wrapper around ``SUNMatrix`` responsible for automatic memory management.
///
/// Raison d'être of this class is to leverage Swift's built-in ARC (Automatic Reference Counting) for
/// managing memory allocated in C. ARC calls the destructor once the variable gets out of scope and the
/// reference count hits 0. Destructor performs deallocation of the owned C ``pointer``. Unless the
/// pointer is passed to a C API that assumes ownership, memory leaks coming from pointers wrapped in
/// this class become virtually impossible.
///
/// The wrapper also provides access to ``isKnownUniquelyReferenced(...)`` call. This allows
/// the ``NVector`` struct to properly implement value semantics even though it stores a strong
/// reference to an instance of this wrapper and performs COW (Copy on Write) only when necessary.
///
/// Swift wrapper around ``N_Vector`` responsible for automatic memory management.
///
/// Raison d'être of this class is to leverage Swift's built-in ARC (Automatic Reference Counting) for
/// managing memory allocated in C. ARC calls the destructor once the variable gets out of scope and the
/// reference count hits 0. Destructor performs deallocation of the owned C ``pointer``. Unless the
/// pointer is passed to a C API that assumes ownership, memory leaks coming from pointers wrapped in
/// this class become virtually impossible.
///
/// The wrapper also provides access to ``isKnownUniquelyReferenced(...)`` call. This allows
/// the ``NVector`` struct to properly implement value semantics even though it stores a strong
/// reference to an instance of this wrapper and performs COW (Copy on Write) only when necessary.
///
/// Alternative way to look at the ``owned`` property is to consider it as a view in case the data are
/// not owned by the instance.
class ManagedPointer<CStruct: Cloneable & Destructible> {
    /// Pointer to managed interoperable C struct.
    var pointer: UnsafeMutablePointer<CStruct>
    /// Flag indicating ownership and responsibility for deallocation.
    let managed: Bool

    /// Creates reference counted wrapper that owns, i.e. eventually deallocates, `pointer`.
    init(manage pointer: UnsafeMutablePointer<CStruct>) {
        self.pointer = pointer
        managed = true
    }
    
    /// Creates reference counted wrapper that does not own, i.e. doesn't deallocate, `pointer`.
    init(borrow pointer: UnsafeMutablePointer<CStruct>) {
        self.pointer = pointer
        managed = false
    }

    func clone() -> ManagedPointer<CStruct> {
        let clone = pointer.pointee.clone()
        return ManagedPointer(manage: clone)
    }

    deinit {
        if managed { pointer.pointee.destroy() }
    }
}

/// A type that can create an exact copy of itself.
protocol Cloneable {
    /// Copies itself and returns a raw C pointer to the copy.
    ///
    /// - Note: In an ideal world, this method would  be non-mutating. However, _Sundials_ C API
    /// isn't const correct. I'm not sure if it is intentional but all `*Clone(...)` methods accept only
    /// a read-write pointer. Read-only, i.e. with const modifier, pointer should be enough for the cloning.
    mutating func clone() -> UnsafeMutablePointer<Self>
}

/// A type that can destroy itself, i.e. free its memory or other resources.
protocol Destructible {
    /// Releases allocated memory or other resources.
    mutating func destroy()
}
