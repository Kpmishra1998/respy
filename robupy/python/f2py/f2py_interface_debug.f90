!*******************************************************************************
!*******************************************************************************
!
!   This subroutine is just a wrapper for selected functions of the ROBUFORT 
!   library. Its sole purpose is to serve as a wrapper for debugging purposes.
!
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_solve_fortran_bare(mapping_state_idx, periods_emax, & 
                periods_payoffs_future, periods_payoffs_ex_post, &
                periods_payoffs_systematic, states_all, states_number_period, & 
                coeffs_a, coeffs_b, coeffs_edu, coeffs_home, shocks, edu_max, & 
                delta, edu_start, is_debug, is_interpolated, level, measure, & 
                min_idx, num_draws_emax, num_periods, num_points, & 
                is_ambiguous, disturbances_emax, max_states_period)
    
    !
    ! The presence of max_states_period breaks the equality of interfaces. 
    ! However, this is required so that the size of the return arguments is
    ! known from the beginning.
    !

    !/* external libraries      */

    USE robufort_library

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    INTEGER, INTENT(OUT)            :: mapping_state_idx(num_periods, num_periods, num_periods, min_idx, 2)
    INTEGER, INTENT(OUT)            :: states_all(num_periods, max_states_period, 4)
    INTEGER, INTENT(OUT)            :: states_number_period(num_periods)

    DOUBLE PRECISION, INTENT(OUT)   :: periods_payoffs_systematic(num_periods, max_states_period, 4)
    DOUBLE PRECISION, INTENT(OUT)   :: periods_payoffs_ex_post(num_periods, max_states_period, 4)
    DOUBLE PRECISION, INTENT(OUT)   :: periods_payoffs_future(num_periods, max_states_period, 4)
    DOUBLE PRECISION, INTENT(OUT)   :: periods_emax(num_periods, max_states_period)

    INTEGER, INTENT(IN)             :: max_states_period
    INTEGER, INTENT(IN)             :: num_draws_emax
    INTEGER, INTENT(IN)             :: num_periods
    INTEGER, INTENT(IN)             :: num_points
    INTEGER, INTENT(IN)             :: edu_start
    INTEGER, INTENT(IN)             :: edu_max
    INTEGER, INTENT(IN)             :: min_idx

    DOUBLE PRECISION, INTENT(IN)    :: disturbances_emax(:, :, :)
    DOUBLE PRECISION, INTENT(IN)    :: coeffs_home(:)
    DOUBLE PRECISION, INTENT(IN)    :: coeffs_edu(:)
    DOUBLE PRECISION, INTENT(IN)    :: shocks(:, :)
    DOUBLE PRECISION, INTENT(IN)    :: coeffs_a(:)
    DOUBLE PRECISION, INTENT(IN)    :: coeffs_b(:)
    DOUBLE PRECISION, INTENT(IN)    :: level
    DOUBLE PRECISION, INTENT(IN)    :: delta 
 
    LOGICAL, INTENT(IN)             :: is_interpolated
    LOGICAL, INTENT(IN)             :: is_ambiguous
    LOGICAL, INTENT(IN)             :: is_debug

    CHARACTER(10), INTENT(IN)       :: measure

    !/* internal objects        */

        ! This container are required as output arguments cannot be of 
        ! assumed-shape type
    
    INTEGER, ALLOCATABLE            :: mapping_state_idx_int(:, :, :, :, :)
    INTEGER, ALLOCATABLE            :: states_number_period_int(:)
    INTEGER, ALLOCATABLE            :: states_all_int(:, :, :)

    DOUBLE PRECISION, ALLOCATABLE   :: periods_payoffs_systematic_int(:, :, :)
    DOUBLE PRECISION, ALLOCATABLE   :: periods_payoffs_ex_post_int(:, :, : )
    DOUBLE PRECISION, ALLOCATABLE   :: periods_payoffs_future_int(:, :, :)
    DOUBLE PRECISION, ALLOCATABLE   :: periods_emax_int(:, :)

!-------------------------------------------------------------------------------
! Algorithm
!------------------------------------------------------------------------------- 
   
    CALL solve_fortran_bare(mapping_state_idx_int, periods_emax_int, & 
            periods_payoffs_future_int, periods_payoffs_ex_post_int, &
            periods_payoffs_systematic_int, states_all_int, & 
            states_number_period_int, coeffs_a, coeffs_b, coeffs_edu, & 
            coeffs_home, shocks, edu_max, delta, edu_start, is_debug, & 
            is_interpolated, level, measure, min_idx, num_draws_emax, &
            num_periods, num_points, is_ambiguous, disturbances_emax)

    ! Assign to initial objects for return to PYTHON
    periods_payoffs_systematic = periods_payoffs_systematic_int   
    periods_payoffs_ex_post = periods_payoffs_ex_post_int  
    periods_payoffs_future = periods_payoffs_future_int
    states_number_period = states_number_period_int 
    mapping_state_idx = mapping_state_idx_int 
    periods_emax = periods_emax_int 
    states_all = states_all_int

END SUBROUTINE
!******************************************************************************
!******************************************************************************
SUBROUTINE wrapper_normal_pdf(rslt, x, mean, sd)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)      :: rslt

    DOUBLE PRECISION, INTENT(IN)       :: x
    DOUBLE PRECISION, INTENT(IN)       :: mean
    DOUBLE PRECISION, INTENT(IN)       :: sd

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------

    rslt = normal_pdf(x, mean, sd)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_pinv(rslt, A, m)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: rslt(m, m)

    DOUBLE PRECISION, INTENT(IN)    :: A(m, m)
    
    INTEGER, INTENT(IN)             :: m

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------

    rslt = pinv(A, m)
    
END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_svd(U, S, VT, A, m)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: S(m) 
    DOUBLE PRECISION, INTENT(OUT)   :: U(m, m)
    DOUBLE PRECISION, INTENT(OUT)   :: VT(m, m)

    DOUBLE PRECISION, INTENT(IN)    :: A(m, m)
    
    INTEGER, INTENT(IN)             :: m

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    CALL svd(U, S, VT, A, m)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_get_payoffs_ambiguity(emax_simulated, payoffs_ex_post, &
                future_payoffs, num_draws_emax, eps_relevant, period, k, &
                payoffs_systematic, edu_max, edu_start, mapping_state_idx, &
                states_all, num_periods, periods_emax, delta, is_debug, &
                shocks, level, measure)

    !/* external libraries      */

    USE robufort_ambiguity

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: payoffs_ex_post(4)
    DOUBLE PRECISION, INTENT(OUT)   :: future_payoffs(4)
    DOUBLE PRECISION, INTENT(OUT)   :: emax_simulated

    INTEGER, INTENT(IN)             :: mapping_state_idx(:,:,:,:,:)
    INTEGER, INTENT(IN)             :: states_all(:,:,:)
    INTEGER, INTENT(IN)             :: num_periods
    INTEGER, INTENT(IN)             :: edu_start
    INTEGER, INTENT(IN)             :: num_draws_emax
    INTEGER, INTENT(IN)             :: edu_max
    INTEGER, INTENT(IN)             :: period
    INTEGER, INTENT(IN)             :: k

    DOUBLE PRECISION, INTENT(IN)    :: payoffs_systematic(:)
    DOUBLE PRECISION, INTENT(IN)    :: shocks(:, :)
    DOUBLE PRECISION, INTENT(IN)    :: eps_relevant(:, :)
    DOUBLE PRECISION, INTENT(IN)    :: periods_emax(:,:)
    DOUBLE PRECISION, INTENT(IN)    :: delta
    DOUBLE PRECISION, INTENT(IN)    :: level

    LOGICAL, INTENT(IN)             :: is_debug

    CHARACTER(10), INTENT(IN)       :: measure

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    CALL get_payoffs_ambiguity(emax_simulated, payoffs_ex_post, &
                future_payoffs, num_draws_emax, eps_relevant, period, k, &
                payoffs_systematic, edu_max, edu_start, mapping_state_idx, &
                states_all, num_periods, periods_emax, delta, is_debug, &
                shocks, level, measure)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_criterion_approx_gradient(rslt, x, eps, num_draws_emax, &
                eps_relevant, period, k, payoffs_systematic, edu_max, &
                edu_start, mapping_state_idx, states_all, num_periods, &
                periods_emax, delta)

    !/* external libraries      */

    USE robufort_ambiguity

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: rslt(2)

    DOUBLE PRECISION, INTENT(IN)    :: payoffs_systematic(:)
    DOUBLE PRECISION, INTENT(IN)    :: eps_relevant(:, :)
    DOUBLE PRECISION, INTENT(IN)    :: periods_emax(:,:)
    DOUBLE PRECISION, INTENT(IN)    :: delta
    DOUBLE PRECISION, INTENT(IN)    :: x(:)
    DOUBLE PRECISION, INTENT(IN)    :: eps

    INTEGER, INTENT(IN)             :: mapping_state_idx(:,:,:,:,:)
    INTEGER, INTENT(IN)             :: states_all(:,:,:)
    INTEGER, INTENT(IN)             :: num_draws_emax
    INTEGER, INTENT(IN)             :: num_periods
    INTEGER, INTENT(IN)             :: edu_start
    INTEGER, INTENT(IN)             :: edu_max
    INTEGER, INTENT(IN)             :: period
    INTEGER, INTENT(IN)             :: k

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------

    rslt = criterion_approx_gradient(x, eps, num_draws_emax, eps_relevant, &
            period, k, payoffs_systematic, edu_max, edu_start, & 
            mapping_state_idx, states_all, num_periods, periods_emax, delta)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_simulate_emax(emax_simulated, payoffs_ex_post, &
                future_payoffs, num_periods, num_draws_emax, period, k, &
                eps_relevant_emax, payoffs_systematic, edu_max, edu_start, &
                periods_emax, states_all, mapping_state_idx, delta)

    !/* external libraries      */

    USE robufort_emax

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: payoffs_ex_post(4)
    DOUBLE PRECISION, INTENT(OUT)   :: future_payoffs(4)
    DOUBLE PRECISION, INTENT(OUT)   :: emax_simulated

    DOUBLE PRECISION, INTENT(IN)    :: eps_relevant_emax(:,:)
    DOUBLE PRECISION, INTENT(IN)    :: payoffs_systematic(:)
    DOUBLE PRECISION, INTENT(IN)    :: periods_emax(:,:)
    DOUBLE PRECISION, INTENT(IN)    :: delta

    INTEGER, INTENT(IN)             :: mapping_state_idx(:,:,:,:,:)
    INTEGER, INTENT(IN)             :: states_all(:,:,:)
    INTEGER, INTENT(IN)             :: num_draws_emax
    INTEGER, INTENT(IN)             :: num_periods
    INTEGER, INTENT(IN)             :: edu_start
    INTEGER, INTENT(IN)             :: edu_max
    INTEGER, INTENT(IN)             :: period
    INTEGER, INTENT(IN)             :: k

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------

    CALL simulate_emax(emax_simulated, payoffs_ex_post, future_payoffs, &
            num_periods, num_draws_emax, period, k, eps_relevant_emax, &
            payoffs_systematic, edu_max, edu_start, periods_emax, states_all, &
            mapping_state_idx, delta)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_criterion(emax_simulated, x, num_draws_emax, eps_relevant, &
                period, k, payoffs_systematic, edu_max, edu_start, & 
                mapping_state_idx, states_all, num_periods, periods_emax, & 
                delta)

    !/* external libraries      */

    USE robufort_ambiguity

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: emax_simulated

    DOUBLE PRECISION, INTENT(IN)    :: payoffs_systematic(:)
    DOUBLE PRECISION, INTENT(IN)    :: eps_relevant(:, :)
    DOUBLE PRECISION, INTENT(IN)    :: periods_emax(:,:)
    DOUBLE PRECISION, INTENT(IN)    :: delta
    DOUBLE PRECISION, INTENT(IN)    :: x(:)

    INTEGER , INTENT(IN)            :: mapping_state_idx(:,:,:,:,:)
    INTEGER , INTENT(IN)            :: states_all(:,:,:)
    INTEGER, INTENT(IN)             :: num_draws_emax
    INTEGER, INTENT(IN)             :: num_periods
    INTEGER, INTENT(IN)             :: edu_start
    INTEGER, INTENT(IN)             :: edu_max
    INTEGER, INTENT(IN)             :: period
    INTEGER, INTENT(IN)             :: k

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------

    emax_simulated = criterion(x, num_draws_emax, eps_relevant, period, k, &
                        payoffs_systematic, edu_max, edu_start, &
                        mapping_state_idx, states_all, num_periods, &
                        periods_emax, delta)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_divergence_approx_gradient(rslt, x, cov, level, eps)

    !/* external libraries      */

    USE robufort_ambiguity

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(IN)   :: cov(4,4)
    DOUBLE PRECISION, INTENT(OUT)  :: rslt(2)
    DOUBLE PRECISION, INTENT(IN)   :: level
    DOUBLE PRECISION, INTENT(IN)   :: x(2)
    DOUBLE PRECISION, INTENT(IN)   :: eps

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    rslt = divergence_approx_gradient(x, cov, level, eps)

END SUBROUTINE 
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_multivariate_normal(draws, mean, covariance, & 
                num_draws_emax, dim)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    INTEGER, INTENT(IN)             :: num_draws_emax
    INTEGER, INTENT(IN)             :: dim

    DOUBLE PRECISION, INTENT(OUT)   :: draws(num_draws_emax, dim)
    DOUBLE PRECISION, INTENT(IN)    :: covariance(dim, dim)
    DOUBLE PRECISION, INTENT(IN)    :: mean(dim)

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    CALL multivariate_normal(draws, mean, covariance)
    
END SUBROUTINE 
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_standard_normal(draw, dim)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    INTEGER, INTENT(IN)             :: dim
    
    DOUBLE PRECISION, INTENT(OUT)   :: draw(dim)

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    CALL standard_normal(draw)

END SUBROUTINE 
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_determinant(det, A)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: det

    DOUBLE PRECISION, INTENT(IN)    :: A(:, :)

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    det = determinant(A)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_cholesky(factor, matrix, n)

    !/* external libraries      */

    USE robufort_auxiliary
    
    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: factor(n,n)

    DOUBLE PRECISION, INTENT(IN)    :: matrix(:,:)

    INTEGER, INTENT(IN)             :: n

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------

    CALL cholesky(factor, matrix)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_inverse(inv, A, n)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: inv(n, n)

    DOUBLE PRECISION, INTENT(IN)    :: A(:, :)

    INTEGER, INTENT(IN)             :: n

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------

    inv = inverse(A, n)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_trace(rslt, A)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT) :: rslt

    DOUBLE PRECISION, INTENT(IN)  :: A(:,:)

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    rslt = trace_fun(A)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_divergence(div, x, cov, level)

    !/* external libraries      */

    USE robufort_ambiguity

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: div(1)

    DOUBLE PRECISION, INTENT(IN)    :: cov(4,4)
    DOUBLE PRECISION, INTENT(IN)    :: level
    DOUBLE PRECISION, INTENT(IN)    :: x(2)

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    div = divergence(x, cov, level)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_get_clipped_vector(Y, X, lower_bound, upper_bound, & 
                num_values)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: Y(num_values)

    DOUBLE PRECISION, INTENT(IN)    :: X(num_values)
    DOUBLE PRECISION, INTENT(IN)    :: lower_bound
    DOUBLE PRECISION, INTENT(IN)    :: upper_bound 

    INTEGER, INTENT(IN)             :: num_values

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    CALL get_clipped_vector(Y, X, lower_bound, upper_bound, num_values)


END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_get_r_squared(r_squared, Y, P, num_agents)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: r_squared

    DOUBLE PRECISION, INTENT(IN)    :: Y(num_agents)
    DOUBLE PRECISION, INTENT(IN)    :: P(num_agents)
    
    INTEGER, INTENT(IN)              :: num_agents

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    CALL get_r_squared(r_squared, Y, P, num_agents)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_point_predictions(Y, X, coeffs, num_agents)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)       :: Y(num_agents)

    DOUBLE PRECISION, INTENT(IN)        :: coeffs(:)
    DOUBLE PRECISION, INTENT(IN)        :: X(:,:)
    
    INTEGER, INTENT(IN)                 :: num_agents

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    CALL point_predictions(Y, X, coeffs, num_agents)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_get_predictions(predictions, endogenous, exogenous, maxe, & 
                is_simulated, num_points, num_states)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)               :: predictions(num_states)

    DOUBLE PRECISION, INTENT(IN)                :: exogenous(:, :)
    DOUBLE PRECISION, INTENT(IN)                :: endogenous(:)
    DOUBLE PRECISION, INTENT(IN)                :: maxe(:)

    INTEGER, INTENT(IN)                         :: num_states
    INTEGER, INTENT(IN)                         :: num_points

    LOGICAL, INTENT(IN)                         :: is_simulated(:)

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------

    CALL get_predictions(predictions, endogenous, exogenous, maxe, & 
            is_simulated, num_points, num_states)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_random_choice(sample, candidates, num_candidates, num_points)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    INTEGER, INTENT(OUT)            :: sample(num_points)

    INTEGER, INTENT(IN)             :: candidates(:)
    INTEGER, INTENT(IN)             :: num_candidates
    INTEGER, INTENT(IN)             :: num_points

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------

     CALL random_choice(sample, candidates, num_candidates, num_points)


END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_get_coefficients(coeffs, Y, X, num_covars, num_agents)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)   :: coeffs(num_covars)

    DOUBLE PRECISION, INTENT(IN)    :: Y(:)
    DOUBLE PRECISION, INTENT(IN)    :: X(:,:)
    
    INTEGER, INTENT(IN)             :: num_covars
    INTEGER, INTENT(IN)             :: num_agents

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    CALL get_coefficients(coeffs, Y, X, num_covars, num_agents)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_get_endogenous_variable(exogenous_variable, period, &
                num_periods, num_states, delta, periods_payoffs_systematic, &
                edu_max, edu_start, mapping_state_idx, periods_emax, &
                states_all, is_simulated, num_draws_emax, shocks, level, &
                is_ambiguous, is_debug, measure, maxe, eps_relevant)

    !/* external libraries      */

    USE robufort_library

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)       :: exogenous_variable(num_states)

    DOUBLE PRECISION, INTENT(IN)        :: periods_payoffs_systematic(:, :, :)
    DOUBLE PRECISION, INTENT(IN)        :: periods_emax(:, :)
    DOUBLE PRECISION, INTENT(IN)        :: eps_relevant(:, :)
    DOUBLE PRECISION, INTENT(IN)        :: shocks(4, 4)
    DOUBLE PRECISION, INTENT(IN)        :: maxe(:)
    DOUBLE PRECISION, INTENT(IN)        :: delta
    DOUBLE PRECISION, INTENT(IN)        :: level
 
    INTEGER, INTENT(IN)                 :: mapping_state_idx(:, :, :, :, :)    
    INTEGER, INTENT(IN)                 :: states_all(:, :, :)    
    INTEGER, INTENT(IN)                 :: num_draws_emax
    INTEGER, INTENT(IN)                 :: num_periods
    INTEGER, INTENT(IN)                 :: num_states
    INTEGER, INTENT(IN)                 :: edu_start
    INTEGER, INTENT(IN)                 :: edu_max
    INTEGER, INTENT(IN)                 :: period

    LOGICAL, INTENT(IN)                 :: is_simulated(:)
    LOGICAL, INTENT(IN)                 :: is_ambiguous
    LOGICAL, INTENT(IN)                 :: is_debug
    
    CHARACTER(10), INTENT(IN)           :: measure

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    CALL get_endogenous_variable(exogenous_variable, period, num_periods, &
            num_states, delta, periods_payoffs_systematic, edu_max, &
            edu_start, mapping_state_idx, periods_emax, states_all, &
            is_simulated, num_draws_emax, shocks, level, is_ambiguous, & 
            is_debug, measure, maxe, eps_relevant)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_get_exogenous_variables(independent_variables, maxe, &
                period, num_periods, num_states, delta, & 
                periods_payoffs_systematic, shifts, edu_max, edu_start, &
                mapping_state_idx, periods_emax, states_all)

    !/* external libraries      */

    USE robufort_emax

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)        :: independent_variables(num_states, 9)
    DOUBLE PRECISION, INTENT(OUT)        :: maxe(num_states)


    DOUBLE PRECISION, INTENT(IN)        :: periods_payoffs_systematic(:, :, :)
    DOUBLE PRECISION, INTENT(IN)        :: periods_emax(:, :)
    DOUBLE PRECISION, INTENT(IN)        :: shifts(:)
    DOUBLE PRECISION, INTENT(IN)        :: delta
 
    INTEGER, INTENT(IN)                 :: mapping_state_idx(:, :, :, :, :)    
    INTEGER, INTENT(IN)                 :: states_all(:, :, :)    
    INTEGER, INTENT(IN)                 :: num_periods
    INTEGER, INTENT(IN)                 :: num_states
    INTEGER, INTENT(IN)                 :: edu_start
    INTEGER, INTENT(IN)                 :: edu_max
    INTEGER, INTENT(IN)                 :: period

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    CALL get_exogenous_variables(independent_variables, maxe,  period, &
            num_periods, num_states, delta, periods_payoffs_systematic, &
            shifts, edu_max, edu_start, mapping_state_idx, periods_emax, &
            states_all)
            
END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_get_simulated_indicator(is_simulated, num_points, & 
                num_states, period, num_periods, is_debug)

    !/* external libraries      */

    USE robufort_auxiliary

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    LOGICAL, INTENT(OUT)            :: is_simulated(num_states)

    INTEGER, INTENT(IN)             :: num_periods
    INTEGER, INTENT(IN)             :: num_states
    INTEGER, INTENT(IN)             :: num_points
    INTEGER, INTENT(IN)             :: period

    LOGICAL, INTENT(IN)             :: is_debug

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    is_simulated = get_simulated_indicator(num_points, num_states, period, & 
                        num_periods, is_debug)

END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
SUBROUTINE wrapper_get_payoffs(emax_simulated, payoffs_ex_post, future_payoffs, &
                num_draws_emax, eps_relevant, period, k, payoffs_systematic, &
                edu_max, edu_start, mapping_state_idx, states_all, num_periods, & 
                periods_emax, delta, is_debug, shocks, level, is_ambiguous, & 
                measure)


    !/* external libraries      */

    USE robufort_library

    !/* setup                   */

    IMPLICIT NONE

    !/* external objects        */

    DOUBLE PRECISION, INTENT(OUT)       :: payoffs_ex_post(4)
    DOUBLE PRECISION, INTENT(OUT)       :: future_payoffs(4)
    DOUBLE PRECISION, INTENT(OUT)       :: emax_simulated

    DOUBLE PRECISION, INTENT(IN)        :: payoffs_systematic(:)
    DOUBLE PRECISION, INTENT(IN)        :: eps_relevant(:, :)
    DOUBLE PRECISION, INTENT(IN)        :: periods_emax(:, :)
    DOUBLE PRECISION, INTENT(IN)        :: shocks(:, :)
    DOUBLE PRECISION, INTENT(IN)        :: delta
    DOUBLE PRECISION, INTENT(IN)        :: level

    INTEGER, INTENT(IN)                 :: mapping_state_idx(:, :, :, :, :)
    INTEGER, INTENT(IN)                 :: states_all(:, :, :)
    INTEGER, INTENT(IN)                 :: num_draws_emax
    INTEGER, INTENT(IN)                 :: num_periods
    INTEGER, INTENT(IN)                 :: edu_start
    INTEGER, INTENT(IN)                 :: edu_max
    INTEGER, INTENT(IN)                 :: period
    INTEGER, INTENT(IN)                 :: k 

    LOGICAL, INTENT(IN)                 :: is_ambiguous
    LOGICAL, INTENT(IN)                 :: is_debug

    CHARACTER(10), INTENT(IN)           :: measure

!-------------------------------------------------------------------------------
! Algorithm
!-------------------------------------------------------------------------------
    
    CALL get_payoffs(emax_simulated, payoffs_ex_post, future_payoffs, &
                num_draws_emax, eps_relevant, period, k, payoffs_systematic, &
                edu_max, edu_start, mapping_state_idx, states_all, &
                num_periods, periods_emax, delta, is_debug, shocks, level, &
                is_ambiguous, measure)
    
END SUBROUTINE
!*******************************************************************************
!*******************************************************************************
