module ReactionsFactory
  !
  ! !DESCRIPTION:
  !  factory to load the specific bgc reaction modules
  !
  ! History:
  !  Created by Jinyun Tang, Oct 2, 2014
  !
  !
  ! !USES:
  !
  use bshr_kind_mod   , only : r8 => shr_kind_r8
  use bshr_log_mod    , only : errMsg => shr_log_errMsg
  use BGCReactionsMod , only : bgc_reaction_type
  use PlantSoilBGCMod , only : plant_soilbgc_type
  implicit none

  character(len=*), parameter :: mod_filename = &
       __FILE__
  
  private

  public :: create_betr_def_application

contains

  subroutine create_betr_def_application(bgc_reaction, plant_soilbgc, method, yesno)
  !DESCRIPTION
  !create betr applications
  !
  implicit none
  !arguments  
  class(bgc_reaction_type),  allocatable, intent(out) :: bgc_reaction
  class(plant_soilbgc_type), allocatable, intent(out) :: plant_soilbgc
  character(len=*),                       intent(in)  :: method

  logical, intent(out) :: yesno
  yesno = is_reaction_exist(method)
  if(yesno)then
    allocate(bgc_reaction, source=create_bgc_reaction_type(method))
    allocate(plant_soilbgc, source=create_plant_soilbgc_type(method))
  endif

  end subroutine create_betr_def_application
!-------------------------------------------------------------------------------

  function create_bgc_reaction_type(method) result(bgc_reaction)
    !
    ! !DESCRIPTION:
    ! create and return an object of bgc_reaction
    !
    ! !USES:
    use BGCReactionsMod            , only : bgc_reaction_type
    use MockBGCReactionsType       , only : bgc_reaction_mock_run_type
    use H2OIsotopeBGCReactionsType , only : bgc_reaction_h2oiso_type
    use babortutils                , only : endrun
    use betr_ctrl                  , only : iulog  => biulog
    implicit none
    ! !ARGUMENTS:
    class(bgc_reaction_type) , allocatable :: bgc_reaction
    character(len=*)         , intent(in)  :: method
    !local variables
    character(len=*)         , parameter   :: subname = 'create_bgc_reaction_type'

    select case(trim(method))
    case ("mock_run")
       allocate(bgc_reaction, source=bgc_reaction_mock_run_type())
    case ("h2oiso")
       allocate(bgc_reaction, source=bgc_reaction_h2oiso_type())
    case default
       write(iulog,*)subname //' ERROR: unknown method: ', method
       call endrun(msg=errMsg(mod_filename, __LINE__))
    end select
  end function create_bgc_reaction_type
  !-------------------------------------------------------------------------------

  function create_plant_soilbgc_type(method)result(plant_soilbgc)
  !DESCRIPTION
  !create plant soil bgc type
  !
  !USES
  use PlantSoilBGCMod            , only : plant_soilbgc_type
  use MockPlantSoilBGCType       , only : plant_soilbgc_mock_run_type
  use H2OIsotopePlantSoilBGCType , only : plant_soilbgc_h2oiso_run_type
  use babortutils                , only : endrun
  use betr_ctrl                  , only : iulog  => biulog
  implicit none
  ! !ARGUMENTS:
  class(plant_soilbgc_type) , allocatable :: plant_soilbgc
  character(len=*)          , intent(in)  :: method
  character(len=*)          , parameter   :: subname = 'create_standalone_plant_soilbgc_type'

  select case(trim(method))
  case ("mock_run")
     allocate(plant_soilbgc, source=plant_soilbgc_mock_run_type())
  case ("h2oiso")
     allocate(plant_soilbgc, source=plant_soilbgc_h2oiso_run_type())
  case default
     write(*, *)subname //' ERROR: unknown method: ', method
     call endrun(msg=errMsg(mod_filename, __LINE__))
  end select

  end function create_plant_soilbgc_type
  !-------------------------------------------------------------------------------
  function is_reaction_exist(method)result(yesno)
  !DESCRIPTION
  !determine if it is a default betr application
  implicit none
  character(len=*), intent(in) :: method
  character(len=*), parameter  :: subname = 'is_reaction_exist'
  !local variable
  logical :: yesno
  select case(trim(method))
  case ("mock_run")
     yesno = .true.
  case ("h2oiso")
     yesno = .true.
  case default
     write(*, *)subname //' ERROR: unknown default method: ', method
     yesno = .false.
  end select

  end function is_reaction_exist
end module ReactionsFactory
