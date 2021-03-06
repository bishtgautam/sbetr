module CNNitrogenFluxType
  use clm_varcon             , only : spval, ispval
  use shr_kind_mod           , only : r8 => shr_kind_r8
  use decompMod              , only : bounds_type
  use clm_varpar             , only : nlevdecomp_full, ndecomp_pools
implicit none

  type, public :: nitrogenflux_type
     real(r8), pointer :: smin_no3_leached_col                      (:)     ! col soil mineral NO3 pool loss to leaching (gN/m2/s)
     real(r8), pointer :: smin_no3_runoff_col                       (:)     ! col soil mineral NO3 pool loss to runoff (gN/m2/s)
     real(r8), pointer :: f_n2o_denit_col                           (:)     ! col flux of N2o from denitrification [gN/m^2/s]
     real(r8), pointer :: f_n2o_nit_col                             (:)     ! col flux of N2o from nitrification [gN/m^2/s]
     real(r8), pointer :: f_nit_col                                 (:)
     real(r8), pointer :: f_denit_col                               (:)
     real(r8), pointer :: supplement_to_sminn_vr_col                (:,:)
     real(r8), pointer :: soyfixn_to_sminn_col                      (:)
     real(r8), pointer :: fert_to_sminn_col                         (:)
     real(r8), pointer :: m_decomp_npools_to_fire_vr_col            (:,:,:)
     real(r8), pointer :: ndep_to_sminn_col                         (:)
     real(r8), pointer :: dwt_livecrootn_to_cwdn_col                (:,:)
     real(r8), pointer :: phenology_n_to_litr_lig_n_col             (:,:)
     real(r8), pointer :: nfix_to_sminn_col                         (:)
     real(r8), pointer :: dwt_deadcrootn_to_cwdn_col                (:,:)
     real(r8), pointer :: dwt_frootn_to_litr_lig_n_col              (:,:)
     real(r8), pointer :: phenology_n_to_litr_cel_n_col             (:,:)
     real(r8), pointer :: phenology_n_to_litr_met_n_col             (:,:)
     real(r8), pointer :: gap_mortality_n_to_cwdn_col               (:,:)
     real(r8), pointer :: gap_mortality_n_to_litr_lig_n_col         (:,:)
     real(r8), pointer :: dwt_frootn_to_litr_cel_n_col              (:,:)
     real(r8), pointer :: dwt_frootn_to_litr_met_n_col              (:,:)
     real(r8), pointer :: harvest_n_to_cwdn_col                     (:,:)
     real(r8), pointer :: harvest_n_to_litr_lig_n_col               (:,:)
     real(r8), pointer :: gap_mortality_n_to_litr_cel_n_col         (:,:)
     real(r8), pointer :: gap_mortality_n_to_litr_met_n_col         (:,:)
     real(r8), pointer :: fire_mortality_n_to_cwdn_col              (:,:)
     real(r8), pointer :: m_n_to_litr_lig_fire_col                  (:,:)
     real(r8), pointer :: harvest_n_to_litr_cel_n_col               (:,:)
     real(r8), pointer :: harvest_n_to_litr_met_n_col               (:,:)
     real(r8), pointer :: m_n_to_litr_cel_fire_col                  (:,:)
     real(r8), pointer :: m_n_to_litr_met_fire_col                  (:,:)
  contains

    procedure, public  :: Init
    procedure, private :: InitCold
    procedure, private :: InitAllocate
  end type nitrogenflux_type

contains

  !------------------------------------------------------------------------
  subroutine Init(this, bounds)

    class(nitrogenflux_type) :: this
    type(bounds_type), intent(in) :: bounds

    call this%InitAllocate ( bounds )

    call this%InitCold ( bounds )

  end subroutine Init
  !------------------------------------------------------------------------
  subroutine InitAllocate(this, bounds)
    !
    ! !DESCRIPTION:
    ! Initialize module data structure
    !
    ! !USES:
    use shr_infnan_mod , only : nan => shr_infnan_nan, assignment(=)
    !
    ! !ARGUMENTS:
    class(nitrogenflux_type) :: this
    type(bounds_type), intent(in) :: bounds
    !
    ! !LOCAL VARIABLES:
    integer :: begp, endp
    integer :: begc, endc
    !------------------------------------------------------------------------

    begp = bounds%begp; endp= bounds%endp
    begc = bounds%begc; endc= bounds%endc
    allocate(this%smin_no3_runoff_col         (begc:endc))                   ; this%smin_no3_runoff_col              (:)   = nan
    allocate(this%smin_no3_leached_col        (begc:endc))                   ; this%smin_no3_leached_col             (:)   = nan
    allocate(this%f_n2o_denit_col             (begc:endc))                   ; this%f_n2o_denit_col                  (:)   = nan
    allocate(this%f_n2o_nit_col               (begc:endc))                   ; this%f_n2o_nit_col                    (:)   = nan
    allocate(this%f_nit_col                   (begc:endc))                   ; this%f_nit_col                        (:)   = nan
    allocate(this%f_denit_col                 (begc:endc))                   ; this%f_denit_col                      (:)   = nan
  end subroutine InitAllocate

  !-----------------------------------------------------------------------
  subroutine initCold(this, bounds)
    !
    ! !USES:
    use spmdMod    , only : masterproc
    use fileutils  , only : getfil
    use clm_varctl , only : nsrest, nsrStartup
    use ncdio_pio
    !
    ! !ARGUMENTS:
    class(nitrogenflux_type) :: this
    type(bounds_type), intent(in) :: bounds
    !
    ! !LOCAL VARIABLES:
    integer               :: g,l,c,p,n,j,m            ! indices
    real(r8) ,pointer     :: gdp (:)                  ! global gdp data (needs to be a pointer for use in ncdio)
    real(r8) ,pointer     :: peatf (:)                ! global peatf data (needs to be a pointer for use in ncdio)
    integer  ,pointer     :: soilorder_rdin (:)       ! global soil order data (needs to be a pointer for use in ncdio)
    integer  ,pointer     :: abm (:)                  ! global abm data (needs to be a pointer for use in ncdio)
    real(r8) ,pointer     :: gti (:)                  ! read in - fmax (needs to be a pointer for use in ncdio)
    integer               :: dimid                    ! dimension id
    integer               :: ier                      ! error status
    type(file_desc_t)     :: ncid                     ! netcdf id
    logical               :: readvar
    character(len=256)    :: locfn                    ! local filename
    integer               :: begc, endc
    integer               :: begg, endg


    do p = bounds%begp,bounds%endp

    enddo

  end subroutine initCold


  !-----------------------------------------------------------------------
  subroutine SetValues ( this, &
       num_patch, filter_patch, value_patch, &
       num_column, filter_column, value_column)
    !
    ! !DESCRIPTION:
    ! Set nitrogen flux variables
    !
    ! !ARGUMENTS:
    ! !ARGUMENTS:
    class (nitrogenflux_type) :: this
    integer , intent(in) :: num_patch
    integer , intent(in) :: filter_patch(:)
    real(r8), intent(in) :: value_patch
    integer , intent(in) :: num_column
    integer , intent(in) :: filter_column(:)
    real(r8), intent(in) :: value_column

    integer :: fi, i

    do fi = 1,num_column
       i = filter_column(fi)
       this%smin_no3_leached_col(i)       = value_column
       this%smin_no3_runoff_col(i)        = value_column
    enddo
  end subroutine SetValues
end module CNNitrogenFluxType
