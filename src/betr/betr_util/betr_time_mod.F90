module BeTR_TimeMod

  use bshr_kind_mod  , only : r8 => shr_kind_r8
  use bshr_kind_mod  , only : i8 => shr_kind_i8
  use betr_constants , only : stdout, betr_string_length_long

  implicit none

  character(len=*), parameter :: mod_filename = &
       __FILE__
  
  type, public:: betr_time_type
     ! NOTE(bja, 201603) all real variables have units of seconds!
     real(r8) :: delta_time
     real(r8) :: stop_time
     real(r8) :: time
     real(r8) :: restart_dtime
     integer  :: tstep
     integer :: nelapstep
   contains
     procedure, public :: Init
     procedure, public :: its_time_to_exit
     procedure, public :: update_time_stamp
     procedure, public :: set_nstep
     procedure, public :: get_nstep
     procedure, public :: get_days_per_year
     procedure, public :: get_step_size
     procedure, public :: proc_nextstep
     procedure, public :: proc_initstep
     procedure, private :: ReadNamelist
  end type betr_time_type

contains

  !-------------------------------------------------------------------------------
  subroutine Init(this, namelist_buffer)

    use betr_constants, only : betr_namelist_buffer_size

    implicit none

    class(betr_time_type), intent(inout) :: this
    character(len=betr_namelist_buffer_size), intent(in) :: namelist_buffer

    this%tstep = 1
    this%time  = 0._r8

    call this%ReadNamelist(namelist_buffer)

  end subroutine Init

  ! ----------------------------------------------------------------------

  subroutine ReadNamelist(this, namelist_buffer)
    !
    ! !DESCRIPTION:
    ! read namelist for betr configuration
    ! !USES:
    use babortutils    , only : endrun
    use bshr_log_mod   , only : errMsg => shr_log_errMsg
    use betr_constants , only : stdout, betr_string_length_long, betr_namelist_buffer_size

    implicit none
    ! !ARGUMENTS:
    class(betr_time_type), intent(inout) :: this
    character(len=betr_namelist_buffer_size), intent(in) :: namelist_buffer
    !
    ! !LOCAL VARIABLES:
    integer :: nml_error
    character(len=*), parameter :: subname = 'betr_time%ReadNamelist'
    character(len=betr_string_length_long) :: ioerror_msg
    real(r8) :: delta_time
    real(r8) :: stop_time
    real(r8) :: restart_dtime

    !-----------------------------------------------------------------------

    namelist / betr_time / delta_time, stop_time, restart_dtime

    ! FIXME(bja, 201603) Only reading time variables in seconds!
    ! Should enable other values with unit coversions.

    ! FIXME(bja, 201603) assign some defaults, should eventually remove
    ! when all input files are updated.

    delta_time = 1800._r8   !half hourly time step
    stop_time = delta_time*48._r8*365._r8*2._r8
    restart_dtime = delta_time * 2.0_r8

    ! ----------------------------------------------------------------------
    ! Read namelist from standard input.
    ! ----------------------------------------------------------------------

    if ( index(trim(namelist_buffer),'betr_time')/=0 )then
       ioerror_msg=''
       read(namelist_buffer, nml=betr_time, iostat=nml_error, iomsg=ioerror_msg)
       if (nml_error /= 0) then
          call endrun(msg="ERROR reading sbetr_driver namelist "//errmsg(mod_filename, __LINE__))
       end if
    end if

    if (.true.) then
       write(stdout, *)
       write(stdout, *) '--------------------'
       write(stdout, *)
       write(stdout, *) ' betr time :'
       write(stdout, *)
       write(stdout, *) ' betr_time namelist settings :'
       write(stdout, *)
       write(stdout, betr_time)
       write(stdout, *)
       write(stdout, *) '--------------------'
    endif

    this%delta_time = delta_time
    this%stop_time = stop_time
    this%restart_dtime = restart_dtime

  end subroutine ReadNamelist

  !-------------------------------------------------------------------------------
  !X!  function its_time_to_write_restart(this)result(ans)
  !X!  !
  !X!  ! DESCRIPTION
  !X!  ! decide if to write restart file
  !X!  !
  !X!
  !X!  implicit none
  !X!  type(betr_time_type), intent(in) :: this
  !X!  logical :: ans
  !X!
  !X!  character(len=80) :: subname = 'its_time_to_write_restart'
  !X!
  !X!
  !X!
  !X!  ans = (mod(this%time,this%restart_dtime) == 0)
  !X!  end function its_time_to_write_restart

  !-------------------------------------------------------------------------------
  function its_time_to_exit(this) result(ans)
    !
    ! DESCRIPTION
    ! decide if to exit the loop
    !

    implicit none
    class(betr_time_type), intent(in) :: this
    logical :: ans

    character(len=80) :: subname = 'its_time_to_exit'

    ans = (this%time >= this%stop_time)

  end function its_time_to_exit

  !-------------------------------------------------------------------------------
  subroutine update_time_stamp(this)
    !
    ! DESCRIPTION
    !

    implicit none

    class(betr_time_type), intent(inout) :: this

    character(len=80) :: subname='update_time_stamp'

    this%time = this%time + this%delta_time

    this%tstep = this%tstep + 1
    ! NOTE(bja, 201603) ???
    if(mod(this%tstep, 48 * 365) == 0) then
       this%tstep = 1
    end if

  end subroutine update_time_stamp

  !-------------------------------------------------------------------------------
  real(r8) function get_step_size(this) result(rc)

    ! Return the step size in seconds.

    implicit none

    class(betr_time_type), intent(in) :: this

    rc = this%delta_time
    return

  end function get_step_size

  !-------------------------------------------------------------------------------
  integer function get_nstep(this)

    ! Return the timestep number.
    implicit none

    class(betr_time_type), intent(in) :: this

    character(len=*), parameter :: sub = 'betr::get_nstep'

    get_nstep = this%nelapstep

  end function get_nstep


  !-------------------------------------------------------------------------------
  subroutine set_nstep(this, nstep)

    ! Return the timestep number.
    implicit none
    class(betr_time_type), intent(inout) :: this

    character(len=*), parameter :: sub = 'betr::get_nstep'
    integer, intent(in) :: nstep

    this%nelapstep = nstep
  end subroutine set_nstep

  !-------------------------------------------------------------------------------
  subroutine proc_nextstep(this)

    implicit none

    class(betr_time_type), intent(inout) :: this

    this%nelapstep = this%nelapstep + 1
  end subroutine proc_nextstep

  !-------------------------------------------------------------------------------
  subroutine proc_initstep(this)

    implicit none
    class(betr_time_type), intent(inout) :: this

    this%nelapstep = 0
  end subroutine proc_initstep

  !-------------------------------------------------------------------------------
  integer function get_days_per_year(this, offset)

    implicit none

    class(betr_time_type), intent(in) :: this
    integer, optional, intent(in) :: offset  ! Offset from current time in seconds.

    ! Positive for future times, negative
    ! for previous times.

    ! remove unused dummy arg compiler warning
    if (offset > 0) continue
    if (this%tstep > 0) continue

    !hardwire at the moment
    get_days_per_year = 365
  end function get_days_per_year

  !-------------------------------------------------------------------------------

end module BeTR_TimeMod
