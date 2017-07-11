MODULE shared_types

    !/* external modules    */

    USE shared_constants

    !/*	setup	                */

    IMPLICIT NONE

!******************************************************************************
!******************************************************************************

    ! We create a type that resembles the dictionary with the optimizer options in PYTHON.
    TYPE OPTIMIZER_BFGS
        INTEGER(our_int)        :: maxiter

        REAL(our_dble)          :: stpmx
        REAL(our_dble)          :: gtol
        REAL(our_dble)          :: eps
    END TYPE

    TYPE OPTIMIZER_NEWUOA
        INTEGER(our_int)        :: maxfun
        INTEGER(our_int)        :: npt

        REAL(our_dble)          :: rhobeg
        REAL(our_dble)          :: rhoend
    END TYPE

    TYPE OPTIMIZER_BOBYQA
        INTEGER(our_int)        :: maxfun
        INTEGER(our_int)        :: npt

        REAL(our_dble)          :: rhobeg
        REAL(our_dble)          :: rhoend
    END TYPE

    TYPE OPTIMIZER_SLSQP
        INTEGER(our_int)        :: maxiter

        REAL(our_dble)          :: ftol
        REAL(our_dble)          :: eps
    END TYPE

    TYPE OPTIMIZER_COLLECTION
        TYPE(OPTIMIZER_BOBYQA)  :: bobyqa
        TYPE(OPTIMIZER_NEWUOA)  :: newuoa
        TYPE(OPTIMIZER_BFGS)    :: bfgs
        TYPE(OPTIMIZER_SLSQP)   :: slsqp
    END TYPE

    ! This container holds the specification for the preconditioning step.
    TYPE PRECOND_DICT
        REAL(our_dble)          :: minimum
        REAL(our_dble)          :: eps
        CHARACTER(10)           :: type
    END TYPE

    ! This container holds the specification for the ambiguity setup.
    TYPE AMBI_DICT
        LOGICAL                 :: mean

        CHARACTER(10)           :: measure
    END TYPE

    ! This container holds all the parameters that are potentially updated during the estimation step.
    TYPE OPTIMPARAS_DICT

        REAL(our_dble), ALLOCATABLE :: paras_bounds(:, :)
        REAL(our_dble), ALLOCATABLE :: type_shifts(:, :)
        REAL(our_dble), ALLOCATABLE :: type_shares(:)

        LOGICAL, ALLOCATABLE        :: paras_fixed(:)

        REAL(our_dble)          :: shocks_cholesky(4, 4)
        REAL(our_dble)          :: coeffs_common(2)
        REAL(our_dble)          :: coeffs_home(3)
        REAL(our_dble)          :: coeffs_edu(7)
        REAL(our_dble)          :: coeffs_a(13)
        REAL(our_dble)          :: coeffs_b(13)
        REAL(our_dble)          :: level(1)
        REAL(our_dble)          :: delta(1)

    END TYPE

    TYPE EDU_DICT

        INTEGER(our_int), ALLOCATABLE   :: start(:)
        INTEGER(our_int)                :: max

        REAL(our_dble), ALLOCATABLE     :: share(:)

    END TYPE

    TYPE COVARIATES_DICT

        INTEGER(our_int)                :: is_return_not_high_school
        INTEGER(our_int)                :: is_return_high_school
        INTEGER(our_int)                :: not_exp_a_lagged
        INTEGER(our_int)                :: not_exp_b_lagged
        INTEGER(our_int)                :: activity_lagged
        INTEGER(our_int)                :: is_young_adult
        INTEGER(our_int)                :: not_any_exp_a
        INTEGER(our_int)                :: not_any_exp_b
        INTEGER(our_int)                :: hs_graduate
        INTEGER(our_int)                :: co_graduate
        INTEGER(our_int)                :: edu_lagged
        INTEGER(our_int)                :: is_minor
        INTEGER(our_int)                :: is_adult
        INTEGER(our_int)                :: period
        INTEGER(our_int)                :: exp_a
        INTEGER(our_int)                :: exp_b
        INTEGER(our_int)                :: type
        INTEGER(our_int)                :: edu

    END TYPE

!******************************************************************************
!******************************************************************************
END MODULE
