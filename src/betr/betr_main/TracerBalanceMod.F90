module TracerBalanceMod

!
! !DESCRIPTION:
! module contains subroutines to do
! tracer mass balance check

  use bshr_kind_mod   , only : r8 => shr_kind_r8
  use bshr_log_mod    , only : errMsg => shr_log_errMsg
  use BeTR_decompMod  , only : bounds_type  => betr_bounds_type
  use BeTRTracerType  , only : betrtracer_type
  use TracerFluxType  , only : TracerFlux_type
  use TracerStateType , only : TracerState_type
  use BeTR_ColumnType , only : col => betr_col
  use betr_ctrl       , only : iulog  => biulog

  implicit none

  private

  character(len=*), parameter :: mod_filename = &
       __FILE__

  public :: begin_betr_tracer_massbalance
  public :: betr_tracer_massbalance_check

  contains



    !--------------------------------------------------------------------------------
    subroutine begin_betr_tracer_massbalance(bounds, lbj, ubj, numf, filter, &
         betrtracer_vars, tracerstate_vars, tracerflux_vars)
      !
      ! !DESCRIPTION:
      ! Preparing for tracer mass balance check
      !
      ! !USES:
      use tracer_varcon            , only : nlevtrc_soil  => betr_nlevtrc_soil

      implicit none
      ! !ARGUMENTS:
      type(bounds_type)      , intent(in)    :: bounds
      integer                , intent(in)    :: lbj, ubj
      integer                , intent(in)    :: numf                        ! number of columns in column filter
      integer                , intent(in)    :: filter(:)                   ! column filter
      type(BeTRtracer_type)  , intent(in)    :: betrtracer_vars
      type(TracerFlux_type)  , intent(in)    :: tracerflux_vars
      type(TracerState_type) , intent(inout) :: tracerState_vars


      ! !LOCAL VARIABLES:
      character(len=256) :: subname='begin_betr_tracer_massbalance'
      integer :: fc, c

      call tracerflux_vars%Reset(bounds, numf, filter)
      call betr_tracer_mass_summary(bounds, lbj, ubj, numf, filter, betrtracer_vars, tracerstate_vars, &
           tracerstate_vars%beg_tracer_molarmass_col)

    end subroutine begin_betr_tracer_massbalance

    !--------------------------------------------------------------------------------
    subroutine betr_tracer_massbalance_check(betr_time, bounds, lbj, ubj, numf, filter, &
         betrtracer_vars, tracerstate_vars, tracerflux_vars)
      !
      ! !DESCRIPTION:
      ! do mass balance check for betr tracers
      !
      ! for solid phase tracers, the only source/sink is biogeochemical production/consumption
      ! and it is currently assumed no solid phase input from atmospheric precipitation (either dry or wet)
      ! the equilibrium fraction is always associated with the (dual)-phase mobile tracer.
      ! However the situation is different for water isotopes, because ice is also part of the
      ! mass budget, and by assuming equilibrium partitioning, the chemical source/sink for ice is not tracked explicitly.
      !
      ! !USES:

      use babortutils   , only : endrun
      use betr_ctrl     , only : iulog  => biulog
      use betr_varcon   , only : namec  => bnamec
      use tracer_varcon , only : catomw,natomw
      use BeTR_TimeMod  , only : betr_time_type

      implicit none

      ! !ARGUMENTS:
      class(betr_time_type)  , intent(in)    :: betr_time
      type(bounds_type)      , intent(in)    :: bounds
      integer                , intent(in)    :: lbj, ubj
      integer                , intent(in)    :: numf             ! number of columns in column filter
      integer                , intent(in)    :: filter(:)        ! column filter
      type(BeTRtracer_type)  , intent(in)    :: betrtracer_vars
      type(TracerFlux_type)  , intent(in)    :: tracerflux_vars
      type(TracerState_type) , intent(inout) :: tracerState_vars

      ! !LOCAL VARIABLES:
      integer  :: jj, fc, c, kk
      real(r8) :: dtime
      real(r8) :: atw
      real(r8) :: err_rel, bal_beg, bal_end, bal_flx
      real(r8), parameter :: err_min = 1.e-8_r8
      real(r8), parameter :: err_min_rel=1.e-3_r8
      associate(                                                                            &
           beg_tracer_molarmass      => tracerstate_vars%beg_tracer_molarmass_col         , &
           end_tracer_molarmass      => tracerstate_vars%end_tracer_molarmass_col         , &
           tracer_flx_infl           => tracerflux_vars%tracer_flx_infl_col               , &
           tracer_flx_netpro         => tracerflux_vars%tracer_flx_netpro_col             , &
           tracer_flx_netphyloss     => tracerflux_vars%tracer_flx_netphyloss_col         , &
           is_mobile                 => betrtracer_vars%is_mobile                         , &
           errtracer                 => tracerstate_vars%errtracer_col                    , &
           ngwmobile_tracers         => betrtracer_vars%ngwmobile_tracers                 , &
           tracernames               => betrtracer_vars%tracernames                       , &
           ntracers                  => betrtracer_vars%ntracers                            &
           )

        call betr_tracer_mass_summary(bounds, lbj, ubj, numf, filter, betrtracer_vars, tracerstate_vars, &
             end_tracer_molarmass)

        dtime = betr_time%get_step_size()

        do fc = 1, numf
           c = filter(fc)
           !summarize the fluxes
           call tracerflux_vars%flux_summary(betr_time, c, betrtracer_vars)

           do kk = 1, ngwmobile_tracers
              errtracer(c,kk) = beg_tracer_molarmass(c,kk)-end_tracer_molarmass(c,kk)  &
                   + tracer_flx_netpro(c,kk)-tracer_flx_netphyloss(c,kk)
              if(abs(errtracer(c,kk))<err_min)then
                 err_rel=1.e-4_r8
              else
                 err_rel = errtracer(c,kk)/max(abs(beg_tracer_molarmass(c,kk)),abs(end_tracer_molarmass(c,kk)))
              endif

              if(abs(err_rel)>err_min_rel)then
                 write(iulog,*)'error exceeds the tolerance for tracer '//tracernames(kk), ' err=',errtracer(c,kk), ' col=',c
                 write(iulog,*)'nstep=', betr_time%get_nstep()
                 write(iulog,'(4(A,5X,E20.10))')'netpro=',tracer_flx_netpro(c,kk),' netphyloss=',tracer_flx_netphyloss(c,kk),&
                      ' begm=',beg_tracer_molarmass(c,kk), &
                      ' endm=',end_tracer_molarmass(c,kk)
                 call tracerflux_vars%flux_display(c,kk,betrtracer_vars)
                 call endrun(decomp_index=c, clmlevel=namec, msg=errMsg(mod_filename, __LINE__))
              endif
           enddo
           bal_beg=0._r8
           bal_end=0._r8
           bal_flx=0._r8
           do kk = ngwmobile_tracers+1, ntracers
              errtracer(c,kk) = beg_tracer_molarmass(c,kk)-end_tracer_molarmass(c,kk) + tracer_flx_netpro(c,kk)
              if(abs(errtracer(c,kk))>err_min)then
                 write(iulog,*)'error exceeds the tolerance for tracer '//tracernames(kk), 'err=',errtracer(c,kk), 'col=',c
                 write(iulog,*) betr_time%get_nstep(),is_mobile(kk)
                 write(iulog,*) 'begmss=', beg_tracer_molarmass(c,kk), 'endmass=', end_tracer_molarmass(c,kk), &
                      ' netpro=', tracer_flx_netpro(c,kk)
                 call endrun(decomp_index=c, clmlevel=namec, msg=errMsg(mod_filename, __LINE__))
              endif
           enddo

           call tracerflux_vars%Temporal_average(c,dtime)
        enddo

      end associate

    end subroutine betr_tracer_massbalance_check

    !--------------------------------------------------------------------------------

    subroutine betr_tracer_mass_summary(bounds, lbj, ubj, numf, filter, betrtracer_vars, tracerstate_vars, tracer_molarmass_col)
      !
      ! !DESCRIPTION:
      ! summarize the column tracer mass
      !
      ! !USES:
      use tracerstatetype , only : tracerstate_type
      use tracer_varcon   , only : nlevtrc_soil  => betr_nlevtrc_soil


      implicit none
      ! !ARGUMENTS:
      type(bounds_type)       , intent(in)    :: bounds
      integer                 , intent(in)    :: lbj, ubj
      integer                 , intent(in)    :: numf                        ! number of columns in column filter
      integer                 , intent(in)    :: filter(:)                   ! column filter
      type(betrtracer_type)   , intent(in)    :: betrtracer_vars             ! betr configuration information
      class(tracerstate_type) , intent(inout) :: tracerstate_vars            ! tracer state variables data structure
      real(r8)                , intent(inout) :: tracer_molarmass_col(bounds%begc:bounds%endc, 1:betrtracer_vars%ntracers)
      ! !LOCAL VARIABLES:
      integer :: jj, fc, c, kk

      ! remove unused dummy args compiler warnings
      if (lbj > 0) continue
      if (ubj > 0) continue
      
      associate(                                                                            &
           tracer_conc_mobile        => tracerstate_vars%tracer_conc_mobile_col           , &
           tracer_conc_solid_equil   => tracerstate_vars%tracer_conc_solid_equil_col      , &
           tracer_conc_solid_passive => tracerstate_vars%tracer_conc_solid_passive_col    , &
           tracer_conc_frozen        => tracerstate_vars%tracer_conc_frozen_col           , &
           dz                        => col%dz                                            , &
           ngwmobile_tracers         => betrtracer_vars%ngwmobile_tracers                 , &
           ntracers                  => betrtracer_vars%ntracers                          , &
           is_adsorb                 => betrtracer_vars%is_adsorb                         , &
           nsolid_passive_tracers    => betrtracer_vars%nsolid_passive_tracers            , &
           adsorbid                  => betrtracer_vars%adsorbid                          , &
           is_frozen                 => betrtracer_vars%is_frozen                         , &
           frozenid                  => betrtracer_vars%frozenid                            &
           )
        do jj = 1,   ngwmobile_tracers
           do fc = 1, numf
              c = filter(fc)

              tracer_molarmass_col(c,jj) = tracerstate_vars%int_mass_mobile_col(1,nlevtrc_soil,c,jj,dz(c,1:nlevtrc_soil))

              if(is_adsorb(jj))then
                 tracer_molarmass_col(c,jj) = tracer_molarmass_col(c,jj) + &
                      tracerstate_vars%int_mass_adsorb_col(1,nlevtrc_soil,c,adsorbid(jj),dz(c,1:nlevtrc_soil))
              endif
              if(is_frozen(jj))then
                 tracer_molarmass_col(c,jj) = tracer_molarmass_col(c,jj) + &
                      tracerstate_vars%int_mass_frozen_col(1,nlevtrc_soil,c,frozenid(jj),dz(c,1:nlevtrc_soil))
              endif
           enddo
        enddo
        do jj = 1, nsolid_passive_tracers
           kk = jj + ngwmobile_tracers
           do fc = 1, numf
              c = filter(fc)
              tracer_molarmass_col(c,kk) = tracerstate_vars%int_mass_solid_col(1,nlevtrc_soil,c,jj, dz(c,1:nlevtrc_soil))
           enddo
        enddo
      end associate
    end subroutine betr_tracer_mass_summary
end module TracerBalanceMod
