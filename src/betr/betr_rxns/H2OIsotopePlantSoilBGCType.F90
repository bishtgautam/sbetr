module H2OIsotopePlantSoilBGCType


  use PlantSoilBGCMod , only : plant_soilbgc_type

  implicit none

  private

  public :: plant_soilbgc_h2oiso_run_type

  type, extends(plant_soilbgc_type) :: &
    plant_soilbgc_h2oiso_run_type
  private
    contains
    procedure :: Init_plant_soilbgc
    procedure :: plant_soilbgc_summary
    procedure :: integrate_vr_flux_to_2D
    procedure :: lsm_betr_plant_soilbgc_recv
    procedure :: lsm_betr_plant_soilbgc_send
  end type plant_soilbgc_h2oiso_run_type


  interface plant_soilbgc_h2oiso_run_type
    module procedure constructor
  end interface plant_soilbgc_h2oiso_run_type

  contains

  !-------------------------------------------------------------------------------
  type(plant_soilbgc_h2oiso_run_type) function constructor()
  !
  ! !DESCRIPTION:
  ! create an object of type plant_soilbgc_h2oiso_run_type.
  ! Right now it is purposely empty

    type(plant_soilbgc_h2oiso_run_type), allocatable :: plants
    
    allocate(plants)
    constructor = plants

  end function constructor

  !-------------------------------------------------------------------------------
  subroutine Init_plant_soilbgc(this, bounds, lbj, ubj)

  !
  ! !DESCRIPTION:
  ! template for init_betrbgc
  !
  ! !USES:
  use BeTR_decompMod             , only : betr_bounds_type
  implicit none
  ! !ARGUMENTS:
  class(plant_soilbgc_h2oiso_run_type) , intent(in) :: this
  type(betr_bounds_type)               , intent(in) :: bounds
  integer                              , intent(in) :: lbj, ubj

  ! remove compiler warnings for unused dummy args
  if (this%dummy_compiler_warning) continue
  if (bounds%begc > 0)             continue
  if (lbj > 0)                     continue
  if (ubj > 0)                     continue

  end subroutine Init_plant_soilbgc


  !----------------------------------------------------------------------
  subroutine plant_soilbgc_summary(this,bounds, lbj, ubj, numf, &
       filter, dz, betrtracer_vars, tracerflux_vars)

  ! !USES:
  use BeTRTracerType , only : BeTRtracer_type
  use tracerfluxType , only : tracerflux_type
  use BeTR_decompMod , only : betr_bounds_type
  use bshr_kind_mod  , only : r8 => shr_kind_r8
  implicit none
  ! !ARGUMENTS:
  class(plant_soilbgc_h2oiso_run_type) , intent(in) :: this
  type(betr_bounds_type)               , intent(in) :: bounds
  integer                              , intent(in) :: lbj, ubj
  integer                              , intent(in) :: numf
  integer                              , intent(in) :: filter(:)
  real(r8)                             , intent(in) :: dz(bounds%begc:bounds%endc,1:ubj)
  type(BeTRtracer_type )               , intent(in) :: betrtracer_vars
  type(tracerflux_type)                , intent(in) :: tracerflux_vars

  ! remove compiler warnings for unused dummy args
  if (this%dummy_compiler_warning)                       continue
  if (bounds%begc > 0)                                   continue
  if (numf > 0)                                          continue
  if (size(filter) > 0)                                  continue
  if (lbj > 0)                                           continue
  if (ubj > 0)                                           continue
  if (size(dz) > 0)                                      continue
  if (len(betrtracer_vars%betr_simname) > 0)             continue
  if (size(tracerflux_vars%tracer_flx_top_soil_col) > 0) continue

  end subroutine plant_soilbgc_summary


  !----------------------------------------------------------------------

  subroutine integrate_vr_flux_to_2D(this, bounds, numf, filter)

  use BeTR_decompMod             , only : betr_bounds_type
  ! !ARGUMENTS:
  implicit none
  class(plant_soilbgc_h2oiso_run_type) , intent(in) :: this
  type(betr_bounds_type)               , intent(in) :: bounds
  integer                              , intent(in) :: numf
  integer                              , intent(in) :: filter(:)

  ! remove compiler warnings for unused dummy args
  if (this%dummy_compiler_warning) continue
  if (bounds%begc > 0)             continue
  if (numf > 0)                    continue
  if (size(filter) > 0)            continue

  end subroutine integrate_vr_flux_to_2D

  !----------------------------------------------------------------------

  subroutine lsm_betr_plant_soilbgc_recv(this, bounds, numf, filter, biogeo_fluxes)
  !
  !DESCRIPTION
  !return plant nutrient yield
  use BeTR_decompMod      , only : betr_bounds_type
  use BeTR_biogeoFluxType , only : betr_biogeo_flux_type
  ! !ARGUMENTS:
  implicit none
  class(plant_soilbgc_h2oiso_run_type) , intent(in)    :: this
  type(betr_bounds_type)               , intent(in)    :: bounds
  integer                              , intent(in)    :: numf
  integer                              , intent(in)    :: filter(:)
  type(betr_biogeo_flux_type)          , intent(inout) :: biogeo_fluxes

  ! remove compiler warnings for unused dummy args
  if (this%dummy_compiler_warning)       continue
  if (bounds%begc > 0)                   continue
  if (numf > 0)                          continue
  if (size(filter) > 0)                  continue
  if (size(biogeo_fluxes%qflx_adv_col)>0)continue
  end subroutine lsm_betr_plant_soilbgc_recv


  !----------------------------------------------------------------------

  subroutine lsm_betr_plant_soilbgc_send(this, bounds, numf, filter,  &
    biogeo_states, biogeo_fluxes, ecophyscon_vars)
  !
  !DESCRIPTION
  ! initialize feedback variables for plant soil bgc interactions
  !
  !USES
  use BeTR_biogeoStateType , only : betr_biogeo_state_type
  use BeTR_biogeoFluxType  , only : betr_biogeo_flux_type
  use BeTR_decompMod       , only : betr_bounds_type
  use BeTR_EcophysConType  , only : betr_ecophyscon_type
  implicit none
  ! !ARGUMENTS:
  class(plant_soilbgc_h2oiso_run_type) , intent(in) :: this
  type(betr_bounds_type)               , intent(in) :: bounds
  integer                              , intent(in) :: numf
  integer                              , intent(in) :: filter(:)
  type(betr_biogeo_state_type)         , intent(in) :: biogeo_states
  type(betr_biogeo_flux_type)          , intent(in) :: biogeo_fluxes
  type(betr_ecophyscon_type)           , intent(in) :: ecophyscon_vars

  if (this%dummy_compiler_warning)       continue
  if (bounds%begc > 0)                   continue
  if (numf > 0)                          continue
  if (size(filter)>0)                    continue
  if (size(biogeo_states%zwts_col)>0)    continue
  if(size(biogeo_fluxes%qflx_adv_col)>0) continue
  if(size(ecophyscon_vars%noveg)>0)      continue
  end subroutine lsm_betr_plant_soilbgc_send

end module H2OIsotopePlantSoilBGCType
