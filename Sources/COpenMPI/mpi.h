#include <mpi.h>


#define ATTR_SWIFT_NAME(sname) __attribute__((swift_name(sname)))
#define ATTR_STATIC_INLINE static __inline__ __attribute__((always_inline))

/// Workaround for function-like macros in `mpi.h` header.
///
/// Swift compiler has a hard-time seeing through function-like macros OpenMPI is using in their top-level
/// `mpi.h` header. This macro is a somewhat ugly workaround for the problem.
///
/// The trick is to use LLVM attributes and decorate static inline methods as Swift getters of a computed
/// property. The inline methods simply return the constant macro value. By the way, this is also the way
/// regular, i.e. not function-like, macros are bridged into Swift. That's where I got the idea for
/// the workaround.
///
#define MPI_MACRO_GET(type, macro) ATTR_STATIC_INLINE \
    type macro##_f(void) ATTR_SWIFT_NAME("getter:" #macro "()") { \
        return macro; \
    }


MPI_MACRO_GET(MPI_Group, MPI_GROUP_NULL);
MPI_MACRO_GET(MPI_Comm, MPI_COMM_NULL);
MPI_MACRO_GET(MPI_Request, MPI_REQUEST_NULL);
MPI_MACRO_GET(MPI_Message, MPI_MESSAGE_NULL);
MPI_MACRO_GET(MPI_Op, MPI_OP_NULL);
MPI_MACRO_GET(MPI_Errhandler, MPI_ERRHANDLER_NULL);
MPI_MACRO_GET(MPI_Info, MPI_INFO_NULL);
MPI_MACRO_GET(MPI_Win, MPI_WIN_NULL);
MPI_MACRO_GET(MPI_File, MPI_FILE_NULL);
MPI_MACRO_GET(MPI_Info, MPI_INFO_ENV);
MPI_MACRO_GET(MPI_Comm, MPI_COMM_WORLD);
MPI_MACRO_GET(MPI_Comm, MPI_COMM_SELF);
MPI_MACRO_GET(MPI_Group, MPI_GROUP_EMPTY);
MPI_MACRO_GET(MPI_Message, MPI_MESSAGE_NO_PROC);
MPI_MACRO_GET(MPI_Op, MPI_MAX);
MPI_MACRO_GET(MPI_Op, MPI_MIN);
MPI_MACRO_GET(MPI_Op, MPI_SUM);
MPI_MACRO_GET(MPI_Op, MPI_PROD);
MPI_MACRO_GET(MPI_Op, MPI_LAND);
MPI_MACRO_GET(MPI_Op, MPI_BAND);
MPI_MACRO_GET(MPI_Op, MPI_LOR);
MPI_MACRO_GET(MPI_Op, MPI_BOR);
MPI_MACRO_GET(MPI_Op, MPI_LXOR);
MPI_MACRO_GET(MPI_Op, MPI_BXOR);
MPI_MACRO_GET(MPI_Op, MPI_MAXLOC);
MPI_MACRO_GET(MPI_Op, MPI_MINLOC);
MPI_MACRO_GET(MPI_Op, MPI_REPLACE);
MPI_MACRO_GET(MPI_Op, MPI_NO_OP);
MPI_MACRO_GET(MPI_Datatype, MPI_DATATYPE_NULL);
MPI_MACRO_GET(MPI_Datatype, MPI_BYTE);
MPI_MACRO_GET(MPI_Datatype, MPI_PACKED);
MPI_MACRO_GET(MPI_Datatype, MPI_CHAR);
MPI_MACRO_GET(MPI_Datatype, MPI_SHORT);
MPI_MACRO_GET(MPI_Datatype, MPI_INT);
MPI_MACRO_GET(MPI_Datatype, MPI_LONG);
MPI_MACRO_GET(MPI_Datatype, MPI_FLOAT);
MPI_MACRO_GET(MPI_Datatype, MPI_DOUBLE);
MPI_MACRO_GET(MPI_Datatype, MPI_LONG_DOUBLE);
MPI_MACRO_GET(MPI_Datatype, MPI_UNSIGNED_CHAR);
MPI_MACRO_GET(MPI_Datatype, MPI_SIGNED_CHAR);
MPI_MACRO_GET(MPI_Datatype, MPI_UNSIGNED_SHORT);
MPI_MACRO_GET(MPI_Datatype, MPI_UNSIGNED_LONG);
MPI_MACRO_GET(MPI_Datatype, MPI_UNSIGNED);
MPI_MACRO_GET(MPI_Datatype, MPI_FLOAT_INT);
MPI_MACRO_GET(MPI_Datatype, MPI_DOUBLE_INT);
MPI_MACRO_GET(MPI_Datatype, MPI_LONG_DOUBLE_INT);
MPI_MACRO_GET(MPI_Datatype, MPI_LONG_INT);
MPI_MACRO_GET(MPI_Datatype, MPI_SHORT_INT);
MPI_MACRO_GET(MPI_Datatype, MPI_2INT);
MPI_MACRO_GET(MPI_Datatype, MPI_WCHAR);
MPI_MACRO_GET(MPI_Datatype, MPI_LONG_LONG_INT);
MPI_MACRO_GET(MPI_Datatype, MPI_LONG_LONG);
MPI_MACRO_GET(MPI_Datatype, MPI_UNSIGNED_LONG_LONG);
MPI_MACRO_GET(MPI_Datatype, MPI_2COMPLEX);
MPI_MACRO_GET(MPI_Datatype, MPI_2DOUBLE_COMPLEX);
MPI_MACRO_GET(MPI_Datatype, MPI_INT8_T);
MPI_MACRO_GET(MPI_Datatype, MPI_UINT8_T);
MPI_MACRO_GET(MPI_Datatype, MPI_INT16_T);
MPI_MACRO_GET(MPI_Datatype, MPI_UINT16_T);
MPI_MACRO_GET(MPI_Datatype, MPI_INT32_T);
MPI_MACRO_GET(MPI_Datatype, MPI_UINT32_T);
MPI_MACRO_GET(MPI_Datatype, MPI_INT64_T);
MPI_MACRO_GET(MPI_Datatype, MPI_UINT64_T);
MPI_MACRO_GET(MPI_Datatype, MPI_AINT);
MPI_MACRO_GET(MPI_Datatype, MPI_OFFSET);
MPI_MACRO_GET(MPI_Datatype, MPI_C_BOOL);
MPI_MACRO_GET(MPI_Datatype, MPI_C_COMPLEX);
MPI_MACRO_GET(MPI_Datatype, MPI_C_FLOAT_COMPLEX);
MPI_MACRO_GET(MPI_Datatype, MPI_C_DOUBLE_COMPLEX);
MPI_MACRO_GET(MPI_Datatype, MPI_C_LONG_DOUBLE_COMPLEX);
MPI_MACRO_GET(MPI_Datatype, MPI_CXX_BOOL);
MPI_MACRO_GET(MPI_Datatype, MPI_CXX_COMPLEX);
MPI_MACRO_GET(MPI_Datatype, MPI_CXX_FLOAT_COMPLEX);
MPI_MACRO_GET(MPI_Datatype, MPI_CXX_DOUBLE_COMPLEX);
MPI_MACRO_GET(MPI_Datatype, MPI_CXX_LONG_DOUBLE_COMPLEX);
MPI_MACRO_GET(MPI_Datatype, MPI_COUNT);
MPI_MACRO_GET(MPI_Errhandler, MPI_ERRORS_ARE_FATAL);
MPI_MACRO_GET(MPI_Errhandler, MPI_ERRORS_RETURN);


#undef ATTR_SWIFT_NAME
#undef ATTR_STATIC_INLINE
#undef MPI_MACRO_GET
