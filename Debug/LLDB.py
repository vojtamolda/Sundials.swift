import lldb
from abc import ABC
from pathlib import Path
from lldb import SBValue, SBDebugger, SBExpressionOptions, SBTypeSummaryOptions


# MARK: - Abstract Interfaces

class SummaryProvider(ABC):
    """
    Abstract base class that provides a custom type summary.

    Type summaries are used, for example, to generate output of `p` LLDB
    command. Summaries are also displayed next to every variable in the
    Debug Area in XCode.
    """

    @classmethod
    def summary(cls, value: SBValue, _: dict,
                options: SBTypeSummaryOptions) -> str:
        """ Returns a custom summary of the `value`. """
        raise NotImplementedError()


class SyntheticWrapper(ABC):
    """
    Abstract base class that replaces children by a synthetic wrapper.

    Customizing the children members of a type can shorten or simplify output
    of the `po` LLDB command. It also helps to reduce visual clutter in the
    Debug Area in XCode.
    """

    def __init__(self, value: SBValue, _: dict):
        """ Constructs a synthetic wrapper for a raw `value`. """
        pass
    
    def has_children(self) -> bool:
        """ Returns a flag indicating whether the type has children. """
        non_empty = self.num_children() > 0
        return non_empty
    
    def num_children(self) -> int:
        """ Returns number of synthetic children. """
        return 0
    
    def get_child_at_index(self, index: int) -> None:
        """
        Get a child value by index from a value.

        Structs, unions, classes, arrays and pointers have child
        values that can be access by index.

        Structs and unions access child members using a zero based index
        for each child member.

        Classes reserve the first indexes for base classes that have
        members (empty base classes are omitted), and all members of the
        current class will then follow the base classes.

        Pointers differ depending on what they point to. If the pointer
        points to a simple type, the child at index zero is the only child
        value available, unless synthetic_allowed is true, in which case the
        pointer will be used as an array and can create 'synthetic' child
        values using positive or negative indexes. If the pointer points to
        an aggregate type (an array, class, union, struct), then the pointee
        is transparently skipped and any children are going to be the indexes
        of the child values within the aggregate type. For example if
        we have a `Point` type and we have a `SBValue` that contains a
        pointer to a 'Point' type, then the child at index zero will be
        the `x` member, and the child at index 1 will be the `y` member
        (the child at index zero won't be a 'Point' instance).

        If you actually need an `SBValue` that represents the type pointed
        to by a `SBValue` for which `GetType().IsPointeeType()` returns true,
        regardless of the pointee type, you can do that with the `SBValue.`
        `Dereference(...)` method (or the equivalent `deref` property).

        Arrays have a preset number of children that can be accessed by
        index and will return invalid child values for indexes that are
        out of bounds.
        """
        return None
    
    def get_child_index(self, name: str) -> None:
        """
        Returns the child member index.

        Matches children of this object only and will match base classes and
        member names if this is a clang typed object.
        """
        return None


# MARK: - Debugging Wrappers

class Vector(SummaryProvider, SyntheticWrapper):
    """
    Class that implements array-like behavior for `Vector` type in LLDB.
    
    Synthetic children that are equal to the vector components hide the
    internal implementation and C internals of the `Vector` type. The type is
    conveniently exposed to the debugger as if it was a regular Swift built-in
    array.
    """

    @classmethod
    def summary(cls, value: SBValue, _: dict,
                options: SBTypeSummaryOptions) -> str:
        vector = Vector(value)
        pointer = vector.GetExpressionPath(".pointer").GetValueAsUnsigned()
        return f"0x{pointer:x} ({vector.num_children()} values)"
    
    def __init__(self, value: SBValue, _: dict = {}):
        self.name = value.GetName()
        self.frame = value.GetFrame()
        self.value = value

    def GetExpressionPath(self, path: str) -> SBValue:
        return self.frame.EvaluateExpression(f"{self.name}{path}")

    def CreateExpressionPathValue(self, name: str, path: str) -> SBValue:
        return self.value.CreateValueFromExpression(name, f"{self.name}{path}")

    def num_children(self) -> int:
        count = self.GetExpressionPath(".count")
        return count.signed
    
    def get_child_at_index(self, index: int) -> SBValue:
        if index not in range(self.num_children()):
            return None
        child = self.CreateExpressionPathValue(f"[{index}]", f"[{index}]")
        return child


class Matrix(SummaryProvider):
    """
    Class that implements custom summary for `Matrix` type in LLDB.
    """
    
    @classmethod
    def summary(cls, value: SBValue, _: dict,
                options: SBTypeSummaryOptions) -> str:
        matrix = Matrix(value)
        pointer = matrix.GetExpressionPath(".pointer").GetValueAsUnsigned()
        content = matrix.GetExpressionPath(".pointer.pointee.content!")
        contentValue = content.GetValue()

        if contentValue:
            type = matrix.target.FindFirstType("sunindextype")
            offset = type.GetByteSize()
            address = int(contentValue, 16)
            rows = (matrix.value
                .CreateValueFromAddress("rows", address, type)
                .GetValueAsUnsigned()
            )
            cols = (matrix.value
                .CreateValueFromAddress("cols", address + offset, type)
                .GetValueAsUnsigned()
            )
        else:
            rows = 0
            cols = 0

        return f"0x{pointer:x} ({rows}×{cols} values)"

    def __init__(self, value: SBValue, _: dict = {}):
        self.name = value.GetName()
        self.frame = value.GetFrame()
        self.target = value.GetTarget()
        self.value = value

    def GetExpressionPath(self, path: str) -> SBValue:
        return self.frame.EvaluateExpression(f"{self.name}{path}")


# MARK: - Initialization

def __lldb_init_module(debugger: SBDebugger, _: dict):
    """
    Function that enables all the "debugging sugar" defined in this file. It
    is called automatically by LLDB, when the module is imported.
    
    The import command is:
    ```
    command script import "/path/to/this/script.py"
    ```
    """
    stem = Path(__file__).stem
    debugger.HandleCommand("type category define Sundials")

    for cls in [Vector, Matrix]:
        if issubclass(cls, SummaryProvider):
            debugger.HandleCommand(
                f"type summary add Sundials.{cls.__qualname__} " \
                f"--python-function {stem}.{cls.__qualname__}.summary " \
                f"--category Sundials"
            )
        if issubclass(cls, SyntheticWrapper):
            debugger.HandleCommand(
                f"type synthetic add Sundials.{cls.__qualname__} " \
                f"--python-class {stem}.{cls.__qualname__} " \
                f"--category Sundials"
            )

    debugger.HandleCommand("type category enable Sundials")
