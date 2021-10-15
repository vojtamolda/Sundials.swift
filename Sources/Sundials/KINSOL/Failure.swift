import CSundials


extension KINSOL {

    /// Failure modes of the _KINSOL_ solver, i.e. all things that can go wrong.
    public enum Failure: Int32, RawRepresentable, Error {
        /// The _KINSOL_ memory block pointer was NULL.
        case memoryNull
        /// An input parameter was invalid.
        case illInput
        /// The _KINSOL_ memory was not allocated by a call to `KINCreate`.
        case noMalloc
        /// A memory allocation failed.
        case memoryFailure
        
        ///The line search algorithm was unable to find an iterate sufficiently distinct from the current
        ///iterate, or could not find an iterate satisfying the sufficient decrease condition.
        case lineSearchNonConvergent
        /// The maximum number of nonlinear iterations has been reached.
        case maximumIterationsReached
        /// Five consecutive steps have been taken that satisfy the inequality
        /// `L2Norm|D•p| > 0.99 * mxnewtstep`, where `p` denotes the current step and
        /// `mxnewtstep` is a scalar upper bound on the scaled step length. Such a failure may mean
        /// that `L2Norm|D•f(u)|` asymptotes from above to a positive value, or the real scalar
        /// `mxnewtstep` is too small.
        case maximumNewtonStepExceeded5Times
        /// The line search algorithm was unable to satisfy the “beta-condition” for `MXNBCF+1`
        /// nonlinear iterations (not necessarily consecutive), which may indicate the algorithm is
        /// making poor progress.
        case lineSearchBetaConditionFailure

        /// The user-supplied routine `psolve` encountered a recoverable error, but the preconditioner
        /// is already current.
        case linearSolverNoRecovery
        /// The _KINLS_ initialization routine `linit` encountered an error.
        case kinlsInitFailure
        /// The _KINLS_ setup routine `lsetup` encountered an error; i.e., the user-supplied routine
        /// `pset` (used to set up the preconditioner data) encountered an unrecoverable error.
        case kinlsSetupFailure
        /// The _KINLS_ solve routine `lsolve` encountered an error; i.e., the user-supplied routine
        /// `psolve` (used to to solve the preconditioned linear system) encountered an unrecoverable
        /// error.
        case kinlsSolverFailure
        
        /// The problem system function failed in an unrecoverable manner.
        case problemSystemFunctionError
        /// The problem system function failed recoverably at the first call.
        case firstStepProblemSystemFunctionError
        /// The problem system function had repeated recoverable errors. No recovery is possible.
        case problemSystemFunctionRepeatedRecoverableErrors
        
        /// A vector operation has failed.
        case vectorOperationError
        
        /// Unknown error, possibly not yet implemented in Swift.
        case unknown
        
        public var rawValue: Int32 {
            return 0
        }
        
        public init?(rawValue: Int32) {
            let nonErrorFlags = [
                KIN_SUCCESS, KIN_INITIAL_GUESS_OK,
                KIN_STEP_LT_STPTOL, KIN_WARNING
            ]
            if nonErrorFlags.contains(rawValue) {
                return nil
            }
            
            switch rawValue {
            case KIN_ILL_INPUT:
                self = .memoryNull
            case KIN_ILL_INPUT:
                self = .illInput
            case KIN_NO_MALLOC:
                self = .noMalloc
            case KIN_MEM_FAIL:
                self = .memoryFailure
            
            case KIN_LINESEARCH_NONCONV:
                self = .lineSearchNonConvergent
            case KIN_MAXITER_REACHED:
                self = .maximumIterationsReached
            case KIN_MXNEWT_5X_EXCEEDED:
                self = .maximumNewtonStepExceeded5Times
            case KIN_LINESEARCH_BCFAIL:
                self = .lineSearchBetaConditionFailure

            case KIN_LINSOLV_NO_RECOVERY:
                self = .linearSolverNoRecovery
            case KIN_LINIT_FAIL:
                self = .kinlsInitFailure
            case KIN_LSETUP_FAIL:
                self = .kinlsSetupFailure
            case KIN_LSOLVE_FAIL:
                self = .kinlsSolverFailure
            
            case KIN_SYSFUNC_FAIL:
                self = .problemSystemFunctionError
            case KIN_FIRST_SYSFUNC_ERR:
                self = .firstStepProblemSystemFunctionError
            case KIN_REPTD_SYSFUNC_ERR:
                self = .problemSystemFunctionRepeatedRecoverableErrors
                
            case KIN_VECTOROP_ERR:
                self = .vectorOperationError
            
            default:
                self = .unknown
                
            }
        }
    }

}
