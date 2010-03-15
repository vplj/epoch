MODULE iocontrol

  USE input
  USE output

  IMPLICIT NONE

CONTAINS

  SUBROUTINE cfd_open(filename, cfd_rank_in, cfd_comm_in, mode, step, time, &
      jobid)

    CHARACTER(LEN=*), INTENT(IN) :: filename
    INTEGER, INTENT(IN) :: cfd_comm_in, cfd_rank_in, mode
    INTEGER, OPTIONAL, INTENT(IN) :: step
    REAL(num), OPTIONAL, INTENT(IN) :: time
    TYPE(jobid_type), OPTIONAL, INTENT(IN) :: jobid
    INTEGER :: ostep = 0
    DOUBLE PRECISION :: otime = 0

    cfd_comm = cfd_comm_in
    cfd_rank = cfd_rank_in

    IF (mode .EQ. c_cfd_write) THEN
      cfd_mode = MPI_MODE_CREATE + MPI_MODE_WRONLY
      cfd_writing = .TRUE.

      ! Creating a new file of the current version, so set the header offset
      ! to reflect current version
      header_offset = header_offset_this_version

      IF (PRESENT(step)) ostep = step

      IF (PRESENT(time)) otime = DBLE(time)

      IF (PRESENT(jobid)) THEN
        cfd_jobid = jobid
      ELSE
        cfd_jobid%start_seconds = 0
        cfd_jobid%start_milliseconds = 0
      ENDIF

      ! We are opening a file to be created, so use the destructive file
      ! opening command
      CALL cfd_open_clobber(filename, ostep, otime)
    ELSE
      cfd_mode = MPI_MODE_RDONLY
      cfd_writing = .FALSE.

      ! We're opening a file which already exists, so don't damage it
      CALL cfd_open_read(filename)
    ENDIF

  END SUBROUTINE cfd_open



  SUBROUTINE cfd_close

    ! No open file
    IF (cfd_filehandle .EQ. -1) RETURN

    ! If writing
    IF (cfd_writing) THEN
      ! Go to place where the empty value for nblocks is
      current_displacement = header_offset - 4
      CALL MPI_FILE_SET_VIEW(cfd_filehandle, current_displacement, &
          MPI_INTEGER, MPI_INTEGER, "native", MPI_INFO_NULL, cfd_errcode)

      IF (cfd_rank .EQ. default_rank) &
          CALL MPI_FILE_WRITE(cfd_filehandle, nblocks, 1, MPI_INTEGER, &
              cfd_status, cfd_errcode)
    ENDIF

    CALL MPI_BARRIER(comm, cfd_errcode)

    CALL MPI_FILE_CLOSE(cfd_filehandle, cfd_errcode)

    ! Set cfd_filehandle to -1 to show that the file is closed
    cfd_filehandle = -1

  END SUBROUTINE cfd_close



  SUBROUTINE cfd_set_max_string_length(maxlen)

    INTEGER, INTENT(IN) :: maxlen

    max_string_len = maxlen

  END SUBROUTINE cfd_set_max_string_length



  SUBROUTINE cfd_set_default_rank(rank_in)

    INTEGER, INTENT(IN) :: rank_in

    default_rank = rank_in

  END SUBROUTINE cfd_set_default_rank



  FUNCTION cfd_get_nblocks()

    INTEGER :: cfd_get_nblocks

    cfd_get_nblocks = nblocks

  END FUNCTION cfd_get_nblocks



  FUNCTION cfd_get_jobid()

    TYPE(jobid_type) :: cfd_get_jobid

    cfd_get_jobid = cfd_jobid

  END FUNCTION cfd_get_jobid

END MODULE iocontrol
