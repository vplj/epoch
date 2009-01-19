MODULE deck_control_block
  USE shared_data
  USE strings
IMPLICIT NONE
SAVE 
  INTEGER,PARAMETER :: ControlBlockElements =13
  LOGICAL, DIMENSION(ControlBlockElements) :: ControlBlockDone =.FALSE.
  CHARACTER(len=30),DIMENSION(ControlBlockElements) :: ControlBlockName = (/"nx","ny","npart",&
       "nsteps","t_end","x_start","x_end","y_start","y_end",&
         "dt_multiplier",&
         "data_dir","restart","restart_snapshot"/)

CONTAINS

  FUNCTION HandleControlDeck(Element,Value)

    CHARACTER(*),INTENT(IN) :: Element,Value
    INTEGER :: HandleControlDeck
    INTEGER :: loop,elementselected
    HandleControlDeck=ERR_UNKNOWN_ELEMENT

    elementselected=0

    DO loop=1,ControlBlockElements
       IF(StrCmp(Element,TRIM(ADJUSTL(ControlBlockName(loop))))) THEN
          elementselected=loop
          EXIT
       ENDIF
    ENDDO

    IF (elementselected .EQ. 0) RETURN
    IF (ControlBlockDone(elementselected)) THEN
       HandleControlDeck=ERR_PRESET_ELEMENT
       RETURN
    ENDIF
    ControlBlockDone(elementselected)=.TRUE.
    HandleControlDeck=ERR_NONE

    SELECT CASE (elementselected)
    CASE(1)
       nx=AsInteger(Value,HandleControlDeck)
    CASE(2)
       ny=AsInteger(Value,HandleControlDeck)
    CASE(3)
       npart_global=AsInteger(Value,HandleControlDeck)
    CASE(4)
       nsteps=AsInteger(Value,HandleControlDeck)
    CASE(5)
       t_end=AsReal(Value,HandleControlDeck)
    CASE(6)
       x_start=AsReal(Value,HandleControlDeck)
    CASE(7)
       x_end=AsReal(Value,HandleControlDeck)
    CASE(8)
       y_start=AsReal(Value,HandleControlDeck)
    CASE(9)
       y_end=AsReal(Value,HandleControlDeck)
    CASE(10)
       dt_multiplier=AsReal(Value,HandleControlDeck)
    CASE(11)
       data_dir=Value(1:MIN(LEN(Value),Data_Dir_Max_Length))
    CASE(12)
       restart=AsLogical(Value,HandleControlDeck)
    CASE(13)
       restart_snapshot=AsInteger(Value,HandleControlDeck)
    END SELECT

  END FUNCTION HandleControlDeck

  FUNCTION CheckControlBlock
    INTEGER :: CheckControlBlock,Index

    CheckControlBlock=ERR_NONE

    DO index=1,ControlBlockElements
       IF (.NOT. ControlBlockDone(index)) THEN
          IF (rank .EQ. 0) THEN
             PRINT *,"***ERROR***"
             PRINT *,"Required control block element ",TRIM(ADJUSTL(ControlBlockName(index))), " absent. Please create this entry in the input deck"
             WRITE(40,*) ""
             WRITE(40,*) "***ERROR***"
             WRITE(40,*) "Required control block element ",TRIM(ADJUSTL(ControlBlockName(index))), " absent. Please create this entry in the input deck"             
          ENDIF
          CheckControlBlock=ERR_MISSING_ELEMENTS
       ENDIF
    ENDDO
  END FUNCTION CheckControlBlock
END MODULE