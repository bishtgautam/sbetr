module MockBGCReactionsType

#include "bshr_assert.h"
  !
  ! !DESCRIPTION:
  ! This is an example on how to use polymorphism to create your own bgc modules that will be run with BeTR
  !
  ! HISTORY:
  ! Created by Jinyun Tang, Oct 2nd, 2014
  ! !USES:
  use bshr_log_mod             , only : errMsg => shr_log_errMsg
  use bshr_kind_mod            , only : r8 => shr_kind_r8
  use BeTR_decompMod           , only : bounds_type  => betr_bounds_type
  use BGCReactionsMod          , only : bgc_reaction_type
  use tracer_varcon            , only : bndcond_as_conc, bndcond_as_flux
  use BeTR_LandunitType        , only : lun => betr_lun
  use ColumnType               , only : col
  use BeTR_biogeophysInputType , only : betr_biogeophys_input_type
  implicit none

  private

  character(len=*), parameter :: mod_filename = &
       __FILE__

  public :: bgc_reaction_mock_run_type

  type, extends(bgc_reaction_type) :: &
       bgc_reaction_mock_run_type
  private
  contains
     procedure :: Init_betrbgc                          ! initialize betr bgc
     procedure :: set_boundary_conditions               ! set top/bottom boundary conditions for various tracers
     procedure :: calc_bgc_reaction                     ! doing bgc calculation
     procedure :: init_boundary_condition_type          ! initialize type of top boundary conditions
     procedure :: do_tracer_equilibration               ! do equilibrium tracer chemistry
     procedure :: InitCold                              ! do cold initialization
     procedure :: readParams                            ! read in parameters
     procedure :: lsm_betr_flux_state_receive       !
  end type bgc_reaction_mock_run_type

  interface bgc_reaction_mock_run_type
     module procedure constructor
  end interface bgc_reaction_mock_run_type

contains
  !-------------------------------------------------------------------------------
  type(bgc_reaction_mock_run_type) function constructor()
  !
  ! !DESCRIPTION:
  ! create an object of type bgc_reaction_mock_run_type.
  ! Right now it is purposely empty
    type(bgc_reaction_mock_run_type), allocatable :: bgc
    allocate(bgc)
    constructor = bgc
  end function constructor

  !-------------------------------------------------------------------------------
  subroutine init_boundary_condition_type(this, bounds, betrtracer_vars, tracerboundarycond_vars )
    !
    ! !DESCRIPTION:
    ! initialize boundary condition types
    !
    ! !USES:
    use BeTRTracerType        , only : betrtracer_type
    use TracerBoundaryCondType, only : tracerboundarycond_type
    use tracer_varcon         , only : bndcond_as_conc, bndcond_as_flux
    use BeTRTracerType        , only : betrtracer_type

    ! !ARGUMENTS:
    class(bgc_reaction_mock_run_type), intent(in) :: this
    type(BeTRtracer_type),             intent(in) :: betrtracer_vars
    type(bounds_type),                 intent(in) :: bounds
    type(tracerboundarycond_type),     intent(in) :: tracerboundarycond_vars

    ! !LOCAL VARIABLES:

    ! remove compiler warnings for unused dummy args
    if (this%dummy_compiler_warning) continue
    if (bounds%begc > 0) continue
    if (len(betrtracer_vars%betr_simname) > 0) continue
    tracerboundarycond_vars%topbc_type(:) = bndcond_as_conc

    !when bottom BC is not given, it is specified as constant flux
    ! FIXME(bja, 201604) Don't we need a bottom BC?
    !X!tracerboundarycond_vars%botbc_type(:) = bndcond_as_flux

  end subroutine init_boundary_condition_type

  !-------------------------------------------------------------------------------
  subroutine Init_betrbgc(this, bounds, lbj, ubj, betrtracer_vars)
    !
    ! DESCRIPTION:
    ! initialize the betrbgc
    !
    ! !USES:
    use BeTRTracerType , only : betrtracer_type
    use MathfuncMod    , only : addone

    ! !ARGUMENTS:
    class(bgc_reaction_mock_run_type), intent(in)    :: this
    type(bounds_type)                , intent(in)    :: bounds
    integer                          , intent(in)    :: lbj, ubj
    type(BeTRtracer_type )           , intent(inout) :: betrtracer_vars

    character(len=*), parameter                      :: subname ='Init_betrbgc'

    integer :: itemp_gwm
    integer :: itemp_g
    integer :: itemp_s
    integer :: itemp_gwm_grp
    integer :: dum
    integer :: itemp_grp, itemp_v, itemp_vgrp

    ! remove compiler warnings for unused dummy args
    if (this%dummy_compiler_warning)           continue
    if (bounds%begc > 0)                       continue
    if (ubj > lbj)                             continue
    if (len(betrtracer_vars%betr_simname) > 0) continue

    itemp_gwm     = 0;
    itemp_g       = 0 ;
    itemp_s       = 0;
    itemp_gwm_grp = 0

    betrtracer_vars%id_trc_n2  = addone(itemp_gwm); dum = addone(itemp_g); dum = addone(itemp_gwm_grp)
    betrtracer_vars%id_trc_o2  = addone(itemp_gwm); dum = addone(itemp_g); dum = addone(itemp_gwm_grp)
    betrtracer_vars%id_trc_ar  = addone(itemp_gwm); dum = addone(itemp_g); dum = addone(itemp_gwm_grp)
    betrtracer_vars%id_trc_co2x= addone(itemp_gwm); dum = addone(itemp_g); dum = addone(itemp_gwm_grp)
    betrtracer_vars%id_trc_ch4 = addone(itemp_gwm); dum = addone(itemp_g); dum = addone(itemp_gwm_grp)
    betrtracer_vars%id_trc_doc = addone(itemp_gwm); dum = addone(itemp_gwm_grp)

    betrtracer_vars%ngwmobile_tracers      = itemp_gwm ;  betrtracer_vars%ngwmobile_tracer_groups= itemp_gwm_grp
    betrtracer_vars%nsolid_passive_tracers = itemp_s   ;  betrtracer_vars%nsolid_passive_tracer_groups = itemp_s
    betrtracer_vars%nvolatile_tracer_groups= itemp_g
    betrtracer_vars%nmem_max               = 1

    call betrtracer_vars%Init()

    itemp_grp = 0    !group id
    itemp_v = 0      !volatile id
    itemp_vgrp = 0   !volatile group

    call betrtracer_vars%set_tracer(trc_id = betrtracer_vars%id_trc_n2, trc_name='N2'  ,      &
         is_trc_mobile=.true., is_trc_advective = .true., trc_group_id = addone(itemp_grp),   &
         trc_group_mem= 1,  is_trc_volatile=.true., trc_volatile_id = addone(itemp_v)     ,   &
         trc_volatile_group_id = addone(itemp_vgrp))

    call betrtracer_vars%set_tracer(trc_id = betrtracer_vars%id_trc_o2, trc_name='O2'  ,      &
         is_trc_mobile=.true., is_trc_advective = .true., trc_group_id = addone(itemp_grp),   &
         trc_group_mem = 1, is_trc_volatile=.true., trc_volatile_id = addone(itemp_v)     ,   &
         trc_volatile_group_id = addone(itemp_vgrp))

    call betrtracer_vars%set_tracer(trc_id = betrtracer_vars%id_trc_ar, trc_name='AR'  ,      &
         is_trc_mobile=.true., is_trc_advective = .true., trc_group_id = addone(itemp_grp),   &
         trc_group_mem = 1, is_trc_volatile=.true., trc_volatile_id = addone(itemp_v)     ,   &
         trc_volatile_group_id = addone(itemp_vgrp))

    call betrtracer_vars%set_tracer(trc_id = betrtracer_vars%id_trc_co2x, trc_name='CO2x',    &
         is_trc_mobile=.true., is_trc_advective = .true., trc_group_id = addone(itemp_grp)  , &
         trc_group_mem = 1, is_trc_volatile=.true., trc_volatile_id = addone(itemp_v)       , &
         trc_volatile_group_id = addone(itemp_vgrp) )

    call betrtracer_vars%set_tracer(trc_id = betrtracer_vars%id_trc_ch4, trc_name='CH4',      &
         is_trc_mobile=.true., is_trc_advective = .true., trc_group_id = addone(itemp_grp),   &
         trc_group_mem = 1, is_trc_volatile=.true., trc_volatile_id = addone(itemp_v)     ,   &
         trc_volatile_group_id = addone(itemp_vgrp))

    call betrtracer_vars%set_tracer(trc_id = betrtracer_vars%id_trc_doc, trc_name='DOC',      &
         is_trc_mobile=.true., is_trc_advective = .true., trc_group_id = addone(itemp_grp),   &
         trc_group_mem = 1)

  end subroutine Init_betrbgc

  !-------------------------------------------------------------------------------
  subroutine set_boundary_conditions(this, bounds, num_soilc, filter_soilc, dz_top, betrtracer_vars, &
       biophysforc, biogeo_flux, tracerboundarycond_vars)
    !
    ! !DESCRIPTION:
    ! set up boundary conditions for tracer movement
    !
    ! !USES:
    use betr_ctrl              , only : iulog  => biulog
    use TracerBoundaryCondType , only : tracerboundarycond_type
    use babortutils            , only : endrun
    use bshr_log_mod           , only : errMsg => shr_log_errMsg
    use BeTRTracerType         , only : betrtracer_type
    use betr_varcon            , only : rgas => brgas
    use BeTR_biogeoFluxType    , only : betr_biogeo_flux_type
    implicit none
    ! !ARGUMENTS:
    class(bgc_reaction_mock_run_type) , intent(in)    :: this                       !
    type(bounds_type)                 , intent(in)    :: bounds                     !
    integer                           , intent(in)    :: num_soilc                  ! number of columns in column filter_soilc
    integer                           , intent(in)    :: filter_soilc(:)            ! column filter_soilc
    type(betrtracer_type)             , intent(in)    :: betrtracer_vars            !
    real(r8)                          , intent(in)    :: dz_top(bounds%begc: )      !
    type(betr_biogeophys_input_type)  , intent(in)    :: biophysforc
    type(betr_biogeo_flux_type)       , intent(in)    :: biogeo_flux
    type(tracerboundarycond_type)     , intent(inout) :: tracerboundarycond_vars !

    ! !LOCAL VARIABLES:
    integer            :: fc, c
    character(len=255) :: subname = 'set_boundary_conditions'
    real(r8) :: irt   !the inverse of R*T
    SHR_ASSERT_ALL((ubound(dz_top)                == (/bounds%endc/)),   errMsg(mod_filename,__LINE__))

    ! remove compiler warnings for unused dummy args
    if (this%dummy_compiler_warning)      continue
    if (size(biogeo_flux%qflx_adv_col)>0) continue
    associate(                                                             &
         forc_pbot            => biophysforc%forc_pbot_downscaled_col    , &
         forc_tbot            => biophysforc%forc_t_downscaled_col       , &
         groupid              => betrtracer_vars%groupid                   &
         )

      do fc = 1, num_soilc
         c = filter_soilc(fc)
         irt = 1.e3_r8/(forc_tbot(c)*rgas)

         !eventually, the following code will be implemented using polymorphism
         tracerboundarycond_vars%tracer_gwdif_concflux_top_col(c,1:2,betrtracer_vars%id_trc_n2)   = forc_pbot(c)*0.78084_r8*irt  !mol m-3, contant boundary condition, as concentration
         tracerboundarycond_vars%tracer_gwdif_concflux_top_col(c,1:2,betrtracer_vars%id_trc_o2)   = forc_pbot(c)*0.20946_r8*irt  !mol m-3, contant boundary condition, as concentration
         tracerboundarycond_vars%tracer_gwdif_concflux_top_col(c,1:2,betrtracer_vars%id_trc_ar)   = forc_pbot(c)*0.009340_r8*irt !mol m-3, contant boundary condition, as concentration
         tracerboundarycond_vars%tracer_gwdif_concflux_top_col(c,1:2,betrtracer_vars%id_trc_co2x) = forc_pbot(c)*367e-6_r8*irt   !mol m-3, contant boundary condition, as concentration
         tracerboundarycond_vars%tracer_gwdif_concflux_top_col(c,1:2,betrtracer_vars%id_trc_ch4)  = forc_pbot(c)*1.79e-6_r8*irt  !mol m-3, contant boundary condition, as concentration
         tracerboundarycond_vars%tracer_gwdif_concflux_top_col(c,1:2,betrtracer_vars%id_trc_doc)  = 0._r8                        !mol m-3, contant boundary condition, as concentration

         tracerboundarycond_vars%bot_concflux_col(c,1,:)                                          = 0._r8                        !zero flux boundary condition for diffusion
         tracerboundarycond_vars%condc_toplay_col(c,groupid(betrtracer_vars%id_trc_n2))           = 2._r8*1.837e-5_r8/dz_top(c)  !m/s surface conductance
         tracerboundarycond_vars%condc_toplay_col(c,groupid(betrtracer_vars%id_trc_o2))           = 2._r8*1.713e-5_r8/dz_top(c)  !m/s surface conductance
         tracerboundarycond_vars%condc_toplay_col(c,groupid(betrtracer_vars%id_trc_ar))           = 2._r8*1.532e-5_r8/dz_top(c)  !m/s surface conductance
         tracerboundarycond_vars%condc_toplay_col(c,groupid(betrtracer_vars%id_trc_co2x))         = 2._r8*1.399e-5_r8/dz_top(c)  !m/s surface conductance
         tracerboundarycond_vars%condc_toplay_col(c,groupid(betrtracer_vars%id_trc_ch4))          = 2._r8*1.808e-5_r8/dz_top(c)  !m/s surface conductance
         tracerboundarycond_vars%condc_toplay_col(c,groupid(betrtracer_vars%id_trc_doc))          = 0._r8                        !m/s surface conductance
      enddo

    end associate
  end subroutine set_boundary_conditions

  !-------------------------------------------------------------------------------
  subroutine calc_bgc_reaction(this, bounds, lbj, ubj, num_soilc, filter_soilc,               &
       num_soilp,filter_soilp, jtops, dtime, betrtracer_vars, tracercoeff_vars,  biophysforc, &
       tracerstate_vars, tracerflux_vars, tracerboundarycond_vars, plant_soilbgc)
    !
    ! !DESCRIPTION:
    ! do bgc reaction
    !
    ! !USES:
    use TracerBoundaryCondType , only : tracerboundarycond_type
    use tracerfluxType         , only : tracerflux_type
    use tracerstatetype        , only : tracerstate_type
    use tracercoeffType        , only : tracercoeff_type
    use BetrTracerType         , only : betrtracer_type
    use PlantSoilBGCMod        , only : plant_soilbgc_type
    implicit none
    !ARGUMENTS
    class(bgc_reaction_mock_run_type) , intent(in)    :: this                       !
    type(bounds_type)                 , intent(in)    :: bounds                      ! bounds
    integer                           , intent(in)    :: num_soilc                   ! number of columns in column filter
    integer                           , intent(in)    :: filter_soilc(:)             ! column filter
    integer                           , intent(in)    :: num_soilp
    integer                           , intent(in)    :: filter_soilp(:)
    integer                           , intent(in)    :: jtops( : )                  ! top index of each column
    integer                           , intent(in)    :: lbj, ubj                    ! lower and upper bounds, make sure they are > 0
    real(r8)                          , intent(in)    :: dtime                       ! model time step
    type(betrtracer_type)             , intent(in)    :: betrtracer_vars             ! betr configuration information
    type(betr_biogeophys_input_type)  , intent(in)    :: biophysforc
    type(tracercoeff_type)            , intent(in)    :: tracercoeff_vars
    type(tracerstate_type)            , intent(inout) :: tracerstate_vars
    type(tracerflux_type)             , intent(inout) :: tracerflux_vars
    type(tracerboundarycond_type)     , intent(inout) :: tracerboundarycond_vars !
    class(plant_soilbgc_type)         , intent(inout) ::  plant_soilbgc

    character(len=*)                 , parameter     :: subname ='calc_bgc_reaction'
    
    ! remove compiler warnings for unused dummy args
    if (this%dummy_compiler_warning)                          continue
    if (bounds%begc > 0)                                      continue
    if (ubj > lbj)                                            continue
    if (size(jtops) > 0)                                      continue
    if (num_soilc > 0)                                        continue
    if (size(filter_soilc) > 0)                               continue
    if (num_soilp > 0)                                        continue
    if (size(filter_soilp) > 0)                               continue
    if (dtime > 0.0)                                          continue
    if (len(betrtracer_vars%betr_simname) > 0)                continue
    if (size(biophysforc%isoilorder) > 0)                     continue
    if (size(tracercoeff_vars%annsum_counter_col) > 0)        continue
    if (size(tracerstate_vars%tracer_conc_surfwater_col) > 0) continue
    if (size(tracerflux_vars%tracer_flx_top_soil_col) > 0)    continue
    if (size(tracerboundarycond_vars%jtops_col) > 0)          continue
    if (plant_soilbgc%dummy_compiler_warning)                 continue

  end subroutine calc_bgc_reaction

  !-------------------------------------------------------------------------------
  subroutine do_tracer_equilibration(this, bounds, lbj, ubj, jtops, num_soilc, filter_soilc, &
       betrtracer_vars, tracercoeff_vars, tracerstate_vars)
    !
    ! DESCRIPTION:
    ! requilibrate tracers that has solid and mobile phases
    ! using the theory of mass action.
    !
    ! !USES:
    !
    use tracerstatetype , only : tracerstate_type
    use tracercoeffType , only : tracercoeff_type
    use BeTRTracerType  , only : betrtracer_type
    implicit none
    ! !ARGUMENTS:
    class(bgc_reaction_mock_run_type) , intent(in)    :: this
    type(bounds_type)                 , intent(in)    :: bounds
    integer                           , intent(in)    :: lbj, ubj
    integer                           , intent(in)    :: jtops(bounds%begc: )        ! top label of each column
    integer                           , intent(in)    :: num_soilc
    integer                           , intent(in)    :: filter_soilc(:)
    type(betrtracer_type)             , intent(in)    :: betrtracer_vars
    type(tracercoeff_type)            , intent(in)    :: tracercoeff_vars
    type(tracerstate_type)            , intent(inout) :: tracerstate_vars
    !local variables
    character(len=255) :: subname = 'do_tracer_equilibration'

    SHR_ASSERT_ALL((ubound(jtops) == (/bounds%endc/)), errMsg(mod_filename,__LINE__))

    ! remove compiler warnings for unused dummy args
    if (this%dummy_compiler_warning)                          continue
    if (bounds%begc > 0)                                      continue
    if (ubj > lbj)                                            continue
    if (size(jtops) > 0)                                      continue
    if (num_soilc > 0)                                        continue
    if (size(filter_soilc) > 0)                               continue
    if (len(betrtracer_vars%betr_simname) > 0)                continue
    if (size(tracerstate_vars%tracer_conc_surfwater_col) > 0) continue
    if (size(tracercoeff_vars%annsum_counter_col) > 0)        continue

    !continue on the simulation type, an implementation of aqueous chemistry will be
    !employed to separate out the adsorbed phase
    !It should be noted that this formulation excludes the use of linear isotherm, which
    !can be integrated through the retardation factor

  end subroutine do_tracer_equilibration

  !-----------------------------------------------------------------------
  subroutine InitCold(this, bounds, betrtracer_vars, biophysforc, tracerstate_vars)
    !
    ! !DESCRIPTION:
    ! do cold initialization
    !
    ! !USES:
    use BeTRTracerType      , only : BeTRTracer_Type
    use tracerstatetype     , only : tracerstate_type
    use BeTR_PatchType      , only : pft  => betr_pft
    use betr_varcon         , only : spval => bspval, ispval => bispval
    use BeTR_landvarconType , only : landvarcon  => betr_landvarcon
    implicit none
    ! !ARGUMENTS:
    class(bgc_reaction_mock_run_type) , intent(in)    :: this
    type(bounds_type)                 , intent(in)    :: bounds
    type(BeTRTracer_Type)             , intent(in)    :: betrtracer_vars
    type(betr_biogeophys_input_type)  , intent(in)    :: biophysforc
    type(tracerstate_type)            , intent(inout) :: tracerstate_vars

    !
    ! !LOCAL VARIABLES:
    integer :: p, c, l, k, j
    integer :: fc                                        ! filter_soilc index
    integer               :: begc, endc
    integer               :: begg, endg
    !-----------------------------------------------------------------------

    ! remove compiler warnings for unused dummy args
    if (this%dummy_compiler_warning)          continue
    if (size(biophysforc%h2osoi_liq_col) > 0) continue

    begc = bounds%begc; endc= bounds%endc
    begg = bounds%begg; endg= bounds%endg
    !-----------------------------------------------------------------------


    do c = bounds%begc, bounds%endc
       l = col%landunit(c)
       if (lun%ifspecial(l)) then
          if(betrtracer_vars%ngwmobile_tracers>0)then
             tracerstate_vars%tracer_conc_mobile_col(c,:,:)        = spval
             tracerstate_vars%tracer_conc_surfwater_col(c,:)       = spval
             tracerstate_vars%tracer_conc_aquifer_col(c,:)         = spval
             tracerstate_vars%tracer_conc_grndwater_col(c,:)       = spval
          endif
          if(betrtracer_vars%ntracers > betrtracer_vars%ngwmobile_tracers)then
             tracerstate_vars%tracer_conc_solid_passive_col(c,:,:) = spval
          endif
          if(betrtracer_vars%nsolid_equil_tracers>0)then
             tracerstate_vars%tracer_conc_solid_equil_col(c, :, :) = spval
          endif
       endif
       tracerstate_vars%tracer_soi_molarmass_col(c,:)            = spval

       if (lun%itype(l) == landvarcon%istsoil .or. lun%itype(l) == landvarcon%istcrop) then
          !dual phase tracers

          tracerstate_vars%tracer_conc_mobile_col(c,:, :)          = 0._r8
          tracerstate_vars%tracer_conc_surfwater_col(c,:)          = 0._r8
          tracerstate_vars%tracer_conc_aquifer_col(c,:)            = 0._r8
          tracerstate_vars%tracer_conc_grndwater_col(c,:)          = 0._r8
          tracerstate_vars%tracer_conc_mobile_col(c,7, betrtracer_vars%id_trc_doc) = 1._r8  !point source
          !solid tracers
          if(betrtracer_vars%ngwmobile_tracers < betrtracer_vars%ntracers)then
             tracerstate_vars%tracer_conc_solid_passive_col(c,:,:) = 0._r8
          endif

          if(betrtracer_vars%nsolid_equil_tracers>0)then
             tracerstate_vars%tracer_conc_solid_equil_col(c, :, :) = 0._r8
          endif
          tracerstate_vars%tracer_soi_molarmass_col(c,:)          = 0._r8
       endif
    enddo

  end subroutine InitCold

  !-----------------------------------------------------------------------
  subroutine readParams(this, ncid, betrtracer_vars)
    !
    ! !DESCRIPTION:
    ! read in module specific parameters
    !
    ! !USES:
    use ncdio_pio      , only : file_desc_t
    use BeTRTracerType , only : BeTRTracer_Type
    implicit none
    ! !ARGUMENTS:
    class(bgc_reaction_mock_run_type) , intent(in)    :: this
    type(BeTRTracer_Type)             , intent(inout) :: betrtracer_vars
    type(file_desc_t)                 , intent(inout) :: ncid  ! pio netCDF file id

    ! remove compiler warnings for unused dummy args
    if (this%dummy_compiler_warning)           continue
    if (ncid%fh > 0)                           continue
    if (len(betrtracer_vars%betr_simname) > 0) continue

    !do nothing here
  end subroutine readParams

  !-------------------------------------------------------------------------------
  subroutine lsm_betr_flux_state_receive(this, bounds, num_soilc, filter_soilc,  &
       tracerstate_vars, tracerflux_vars,  betrtracer_vars)
    !
    ! !DESCRIPTION:
    ! do flux and state variable change between betr and lsm.
    !
    ! !USES:
    use bshr_kind_mod   , only : r8 => shr_kind_r8
    use tracerfluxType  , only : tracerflux_type
    use tracerstatetype , only : tracerstate_type
    use BeTRTracerType  , only : BeTRTracer_Type
    implicit none
    ! !ARGUMENTS:
    class(bgc_reaction_mock_run_type) , intent(in) :: this               !
    type(bounds_type)                 , intent(in) :: bounds             ! bounds
    integer                           , intent(in) :: num_soilc
    integer                           , intent(in) :: filter_soilc(:)
    type(betrtracer_type)             , intent(in) :: betrtracer_vars    ! betr configuration information
    type(tracerstate_type)            , intent(in) :: tracerstate_vars   !
    type(tracerflux_type)             , intent(in) :: tracerflux_vars    !

    ! remove compiler warnings for unused dummy args
    if (this%dummy_compiler_warning)                          continue
    if (bounds%begc > 0)                                      continue
    if (num_soilc > 0)                                        continue
    if (size(filter_soilc) > 0)                               continue
    if (len(betrtracer_vars%betr_simname) > 0)                continue
    if (size(tracerstate_vars%tracer_conc_surfwater_col) > 0) continue
    if (size(tracerflux_vars%tracer_flx_top_soil_col) > 0)    continue

  end subroutine lsm_betr_flux_state_receive

end module MockBGCReactionsType
