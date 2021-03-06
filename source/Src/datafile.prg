#IF 0                           DataFile.prg

  Purpose:  Data File Classes

Revisions:  October 27, 2015 - Ken Green - Original

     Uses:  kOSFiles.prg - OS's File operations library
            zSetMgr.prg - Class for saving/restoring a table's state

****************************** Class Definitions ****************************

* CHUNKS Class Definition - CHUNKS.DBF Data File Class (base: Custom)
* CODEFILE Class Definition - CODEFILE.DBF Data File Class (base: Custom)
* SUMMARY Class Definition - SUMMARY.DBF Data File Class (base: Custom)
* CALLS Class Definition - CALLS.DBF Data File Class (base: Custom)
* LINES Class Definition - LINES.DBF Data File Class (base: Custom)
* LOG Class Definition - LOG.DBF Data File Class (base: Custom)
* PROJECT Class Definition - PROJECT.DBF Data File Class (base: Custom)
* TempTabl Class Definition - TEMPTABL.DBF Data File Class (base: Custom)

*****************************************************************************
#ENDIF

* Includes
#INCLUDE INC\APPINCL.H

****************************** Class Definitions ****************************

* CHUNKS Class Definition - CHUNKS.DBF Data File Class (base: Custom)
DEFINE CLASS CHUNKS AS TempTabl

    * This file contains one record for each chunk of code; that is: bare PRG
    *   chunks, functions, procedures or methods. It includes the full text of
    *   the chunk prefaced by the uses and times.
 
    * Standard Properties
    Name = 'CHUNKS'

    * Custom Properties:
    cDBFDir   = ''              && Directory for DBF
    cDBFName  = 'CHUNKS'       && The DBF name (no extension or period)
    cAlias    = ''
    nRecCount = 0
    bDeleteWhenClosed = .T.

    * Total Processing time (secs)
    nOATime   = 0

    * Custom Method List:
    *- CreateTable() - Create our temporary table
    *- GetAnchorText() - Return the HTML Anchor text for a backlink

    * Method Code:

    *- CreateTable() - Create our temporary table
    FUNCTION CreateTable(oLINES, oForm)
        LOCAL cFile

        * Create our table
        SELECT 0
        cFile = THIS.cDBFDir + THIS.cDBFName
        CREATE TABLE (cFile) (FILE C(80), ;
          PROCEDURE C(35), ;
          CLASS C(15), ;
          DISPORDER C(5), ;
          CHUNKTYPE C(1), ;
          CAPSPROC C(50), ;
          TOT_SECS N(9,4), ;
          ACTBEGLN I, ;
          ACTENDLN I, ;
          LINKNAME C(50), ;
          BACKLINKS M, ;
          CODETEXT M)
        INDEX ON UPPER(FILE + CLASS + PROCEDURE) TAG FILE
        INDEX ON DISPORDER TAG DISPORDER
        SET ORDER TO FILE
        THIS.cAlias = ALIAS()

        * Return our record count
        RETURN THIS.nRecCount
    ENDFUNC

    *- GetAnchorText() - Return the HTML Anchor text for a backlink
    FUNCTION GetAnchorText(cLinkIn)
        LOCAL cDisp, cAnchor

        * Save the current record
        THIS.PushState()

        * We're passed a backlink that we're to put into an HTML anchor but we
        *   need to use the CAPSPROC for the text
        LOCATE FOR LINKNAME = cLinkIn
        cDisp = TRIM(CAPSPROC)
        cAnchor = [<a href="#] + cLinkIn + [">] + TRIM(CAPSPROC) + [</a>]

        * Done
        THIS.PopState()
        RETURN cAnchor
    ENDFUNC
ENDDEFINE

* CODEFILE Class Definition - CODEFILE.DBF Data File Class (base: Custom)
DEFINE CLASS CODEFILE AS TempTabl

    * This file has all lines of a given program file. Field Notes:
    *   CODETYPE - Defines sections of code chunks:
    *       'B'are PRG Code
    *       'F'unction or Procedure
    *       'C'lass
    *       'M'ethod of class (either function or procedure)
    *   BREAKPT - defines start and end points of chunks (excluding comments)
    *       'S' - Start of B, one function/procedure, class, method
    *       ' ' - Middle of that (may not exist if only 1 line in chunk)
    *       'E' - End of that (may not exist if only 1 line in chunk)

    * Properties:
    Name = 'CODEFILE'
    cDBFDir   = ''              && Directory for DBF
    cDBFName  = 'CODEFILE'      && The DBF name (no extension or period)
    cAlias    = ''
    nRecCount = 0
    bDeleteWhenClosed = .T.
    cFileName = ''              && Current program file

    * FindFirst property
    cFoundTerm = ''

    * What margin are we going to use
    cMargin = SPACE(4)

    * Custom Method List:
    *- CreateTable() - Create our temporary table
    *- LoadFilesCode() - Load a file's code into our table
    *- SetTypeFields() - Set the CODETYPE and BREAKPT fields
    *- MarkFunctSection() - Mark CODETYPE as 'F' for the function/procs section
    *- MarkClassSection() - Mark CODETYPE as 'C' or 'M' for the class section
    *- FindFirst() - Return the record number of the first found string
    *- GetActualCodeLines() - Return a chunk's actual beginning and ending lines
    *- Zap() - Blow away our table
    *- Destroy() - Close ourselves and optionally delete us

    * Method Code:

    *- CreateTable() - Create our temporary table
    FUNCTION CreateTable()
        LOCAL cFile

        * Create our table
        SELECT 0
        cFile = THIS.cDBFDir + THIS.cDBFName
        CREATE TABLE (cFile) (LINE C(200), ;
          CODETYPE C(1), ;
          BREAKPT C(1), ;
          USES I, ;
          TOT_SECS N(9,4))
        THIS.cAlias = ALIAS()

        * Return our record count
        RETURN THIS.nRecCount
    ENDFUNC

    *- LoadFilesCode() - Load a file's code into our table
    FUNCTION LoadFilesCode(cFileNm, cFileText)
        LOCAL cAlias, aCodeLines[1], nX, M.LINE, nRecs

        * Select ourselves and clear out anything that's there
        THIS.PushState()
        SET FILTER TO
        IF RECCOUNT() > 0
            THIS.Zap()
        ENDIF

        * Note our filename (used in Zap()
        IF NOT EMPTY(cFileNm)
            THIS.cFileName = cFileNm
        ELSE
            THIS.cFileName = ''
        ENDIF

        * Put each line of the file into our table
        cAlias = THIS.cAlias
        ALINES(aCodeLines, cFileText)
        FOR nX = 1 TO ALEN(aCodeLines)
            M.LINE = aCodeLines[nX]
            INSERT INTO (cAlias) FROM MEMVAR
        ENDFOR

        * Set our CODETYPE and BREAKPT fields
        THIS.SetTypeFields()

        * Done
        nRecs = RECCOUNT()
        THIS.PopState()
        RETURN nRecs
    ENDFUNC

    *- SetTypeFields() - Set the CODETYPE and BREAKPT fields
    FUNCTION SetTypeFields()
        LOCAL nLine

        * First thing we have to do is mark records between #IF 0 and #ENDIF
        *   as 'H'idden
        GO TOP
        nLine = 1
        DO WHILE nLine > 0 AND nLine < RECCOUNT()
            nLine = THIS.FindFirst(nLine, '#IF 0')
            IF nLine < 1
                EXIT
            ENDIF

            * Mark these as 'H'idden
            GOTO nLine
            REPLACE CODETYPE WITH 'H'
            SKIP
            nLine = THIS.FindFirst(nLine, '#ENDIF')
            IF nLine < 1
                REPLACE CODETYPE WITH 'H' WHILE NOT EOF()
            ELSE
                REPLACE CODETYPE WITH 'H' WHILE RECNO() <= nLine
            ENDIF
            nLine = RECNO()

            * Any more?
        ENDDO
        SET FILTER TO CODETYPE <> 'H'

        * We start with the 'B'are PRG Code section, by default. That ends at
        *   the first function/procedure/class statement
        GO TOP
        nLine = THIS.FindFirst(1, 'PROC', 'FUNC', 'DEFI~CLAS')
        IF nLine < 1

            * This is all a procedural prg
            REPLACE CODETYPE WITH 'B', BREAKPT WITH 'S'
            SKIP
            REPLACE ALL CODETYPE WITH 'B' WHILE NOT EOF()
            GO BOTTOM
            REPLACE BREAKPT WITH 'E'
            RETURN
        ENDIF

        * Here, nLine >= 1; Mark our start and end of the 'B'are section if OK
        IF nLine > 1
            REPLACE CODETYPE WITH 'B', BREAKPT WITH 'S'
            SKIP
            IF nLine > 2
                REPLACE CODETYPE WITH 'B' WHILE RECNO() < nLine
                IF RECNO() > nLine - 1
                    GOTO (nLine - 1)
                ENDIF
                REPLACE CODETYPE WITH 'B', BREAKPT WITH 'E'
                SKIP
            ENDIF
        ENDIF

        * Handle our function/procedures section
        IF THIS.cFoundTerm = 'PROC' OR THIS.cFoundTerm = 'FUNC'
            THIS.MarkFunctSection('F')
        ENDIF

        * Handle our classes section
        IF THIS.cFoundTerm = 'DEFI'
            THIS.MarkClassSection()
        ENDIF
    ENDFUNC

    *- MarkFunctSection() - Mark CODETYPE as 'F' for the function/procs section
    FUNCTION MarkFunctSection(cTypeLtr, nEnd, bAreMethods)
        LOCAL nEndRec, nLine

        * We end at either EOF or at a DEFINE CLASS record
        nLine = RECNO()
        IF PCOUNT() = 2
            nEndRec = nEnd
        ELSE

            * The function section will end at the next DEFINE CLASS...
            nEndRec = THIS.FindFirst(nLine, 'DEFI~CLAS')
            IF nEndRec < 1
                nEndRec = RECCOUNT()
            ENDIF
        ENDIF

        * Here we have one or more functions/procedures. We're pointed to the
        *   first one. Point just past the first record for the next search.
        DO WHILE nLine > 0 AND nLine <= nEndRec

            * We're pointed to our first function/proc record
            REPLACE CODETYPE WITH cTypeLtr, BREAKPT WITH 'S'
            SKIP
            nLine = RECNO()

            * Now, find its end point which could be at the start of one or the
            *   start of a class.
            nLine = THIS.FindFirst(nLine, 'ENDP', 'ENDFU', 'PROC', 'FUNC', ;
              'DEFI~CLAS', 'PROT~FUNC', 'PROT~PROC', 'HIDD~FUNC', 'HIDD~PROC')

            * Mark the rest of this chunk
            REPLACE CODETYPE WITH cTypeLtr WHILE RECNO() < nLine
            IF THIS.cFoundTerm = 'END'
                REPLACE CODETYPE WITH cTypeLtr, BREAKPT WITH 'E'
            ELSE

                * Here, we're pointed to the start of a new chunk
                IF RECNO() > nLine - 1
                    GOTO (nLine - 1)
                ENDIF
                REPLACE CODETYPE WITH cTypeLtr, BREAKPT WITH 'E'
            ENDIF
            SKIP        && Point to the start of the next chunk

            * We're done if at EOF() or at the start of a class definition
            IF THIS.cFoundTerm = 'DEFI' OR EOF()
                EXIT
            ENDIF

            * Setup for the next function/proc
            nLine = THIS.FindFirst(nLine, 'PROC', 'FUNC', 'PROT~FUNC', ;
              'PROT~PROC', 'HIDD~FUNC', 'HIDD~PROC', 'DEFI~CLAS')
            DO CASE
            CASE THIS.cFoundTerm = 'DEFI' OR EOF()
                EXIT
            CASE nLine > 0 AND nLine <= nEndRec
                GOTO nLine
            ENDCASE
        ENDDO

        * Done
    ENDFUNC

    *- MarkClassSection() - Mark CODETYPE as 'C' or 'M' for the class section
    FUNCTION MarkClassSection()
        LOCAL nLine, nBegRec, nEndRec

        * Here we have one or more classes.
        DO WHILE NOT EOF()

            * We may not yet be pointed to the start of a class record
            nLine = RECNO()
            IF UPPER( LTRIM(LINE)) <> 'DEFI' OR NOT 'CLAS' $ UPPER(LINE)
                nLine = THIS.FindFirst(nLine, 'DEFI~CLAS')
                IF nLine > 0
                    GOTO nLine
                ELSE    && No classes
                    RETURN
                ENDIF
            ENDIF

            * Now, we're pointed to our first class record.
            nBegRec = RECNO()
            REPLACE CODETYPE WITH 'C', BREAKPT WITH 'S'
            SKIP
            nLine = RECNO()

            * We end at either EOF or ENDDEFINE or at another DEFINE CLASS
            nLine = THIS.FindFirst(nLine, 'DEFI~CLAS', 'ENDDE')
            IF nLine < 1
                nEndRec = RECCOUNT()
            ELSE
                nEndRec = nLine
                GOTO nEndRec
                REPLACE CODETYPE WITH 'C', BREAKPT WITH 'E'
                GOTO nBegRec + 1
                nLine = RECNO()
            ENDIF

            * Now, we're pointed just past the first class. Within this class
            *   there may be a bunch of methods. Go handle them
            IF nLine > 0
                nLine = THIS.FindFirst(nLine, 'PROC', 'FUNC', 'DEFI~CLAS', 'ENDDE', ;
                  'PROT~FUNC', 'PROT~PROC', 'HIDD~FUNC', 'HIDD~PROC')
                IF nLine < nEndRec
                    GOTO nLine
                    THIS.MarkFunctSection('M', nEndRec-1, .T.)
                ENDIF
            ENDIF

            * Go to our last record and keep boing
            GOTO nEndRec
            SKIP
        ENDDO

        * Done
    ENDFUNC

    *- FindFirst() - Return the record number of the first found string
    FUNCTION FindFirst(nStart, cTerm1, cTerm2, cTerm3, cTerm4, cTerm5, cTerm6, cTerm7, cTerm8, cTerm9)
        LOCAL nTermsPassed, nFnd, nX, cRow, cTerm

        * Go thru each term starting as appropriate
        THIS.cFoundTerm = ''
        nTermsPassed = PCOUNT() - 1
        nFnd = -1
        FOR nX = 1 TO nTermsPassed
            cRow = TRANSFORM(nX)

            * Get our look-for term but check for a must-have clause
            cMustHave = EVAL('cTerm' + cRow)
            cTerm = goStr.ExtrToken(@cMustHave, '~')

            * Do the search
            GOTO nStart
            IF EMPTY(cMustHave)
                LOCATE FOR UPPER( LTRIM(LINE) ) = cTerm WHILE NOT EOF()
            ELSE
                LOCATE FOR UPPER( LTRIM(LINE) ) = cTerm AND ;
                  cMustHave $ UPPER(LINE) WHILE NOT EOF()
            ENDIF
            IF FOUND()

                * We want to record the earliest record found
                IF nFnd = -1 OR RECNO() < nFnd
                    nFnd = RECNO()
                    THIS.cFoundTerm = cTerm
                ENDIF
            ENDIF
        ENDFOR

        * Point to our starting record and we're done
        GOTO nStart
        RETURN nFnd
    ENDFUNC

    *- GetActualCodeLines() - Return a chunk's actual beginning and ending lines
    FUNCTION GetActualCodeLines(nBegLn, nEndLn, nOASecs, nActualEnd, cType)
        LOCAL cComm, nActualBeg

        * We're passed the first and last line numbers of executed code. We're
        *   to find and return the earliest lines of the chunk.
        THIS.PushState()

        * Go backwards to find the start; then include comments
        GOTO nBegLn
        cType = CODETYPE
        IF cType = 'B'

            * Just backup 5 lines
            SKIP -5
            DO WHILE EMPTY(LINE)
                SKIP
            ENDDO
        ELSE
            SKIP -1
            DO WHILE CODETYPE = cType AND BREAKPT <> 'S'
                SKIP -1
            ENDDO

            * Starting from this line, find the start of a function/method and
            *   note the passed time
            IF cType <> 'B'
                REPLACE TOT_SECS WITH nOASecs
            ENDIF

            * Backup for any comments
            cComm = '&'
            cComm = cComm + '&'
            SKIP -1
            DO WHILE LTRIM(LINE) = '*' OR LTRIM(LINE) = cComm
                SKIP -1
            ENDDO

            * Skip any blank lines
            IF EMPTY(LINE)
                SKIP
            ENDIF
        ENDIF
        nActualBeg = RECNO()

        * Now, find the end point of the chunk
        GOTO nEndLn
        IF cType = 'B'

            * Just skip up to 5 lines
            FOR nX = 1 TO 5
                DO CASE
                CASE BREAKPT = 'E'
                    EXIT
                CASE CODETYPE <> cType OR BREAKPT = 'S'
                    SKIP -1
                    EXIT
                ENDCASE
                SKIP
            ENDFOR
            DO WHILE EMPTY(LINE)
                SKIP -1
            ENDDO
        ELSE
            DO WHILE CODETYPE = cType AND NOT BREAKPT $ 'ES'
                SKIP
                IF CODETYPE <> cType OR BREAKPT = 'S'
                    SKIP -1
                    EXIT
                ENDIF
            ENDDO
        ENDIF
        nActualEnd = RECNO()

        * Done
        THIS.PopState()
        RETURN nActualBeg
    ENDFUNC

    *- Zap() - Blow away our table
    FUNCTION Zap()
        LOCAL cAlias, cFileNm
        SET FILTER TO
        IF NOT EMPTY(THIS.cFileName)
            cFileNm = JUSTSTEM(THIS.cFileName)
            IF UPPER(cFileNm) + ',' $ 'CODEFILE,SUMMARY,CALLS,LINES,LOG,'
                cFileNm = cFileNm + '_Code'
            ENDIF
            COPY TO (THIS.cDBFDir + cFileNm)
        ENDIF
        ZAP
    ENDFUNC

    *- Destroy() - Close ourselves and optionally delete us
    FUNCTION Destroy()
        LOCAL cAlias
        THIS.bDeleteWhenClosed = .T.    && Always kill; Zap() copyies to file
        cAlias = THIS.cAlias
        IF (NOT EMPTY(cAlias)) AND USED(cAlias)
            THIS.Select()
            THIS.Zap()
        ENDIF
        DODEFAULT()
    ENDFUNC
ENDDEFINE

* SUMMARY Class Definition - SUMMARY.DBF Data File Class (base: Custom)
DEFINE CLASS SUMMARY AS TempTabl

    * This file summarizes unique lines from the LINES table. Note that LINES.DBF
    *   can have multiple instances of the same line due to being called from
    *   different functions that may, or may not, have different stack levels.
    *   Here, we only ever want one instance of a line.

    * Standard Properties
    Name = 'SUMMARY'

    * Custom Properties:
    cDBFDir   = ''              && Directory for DBF
    cDBFName  = 'SUMMARY'       && The DBF name (no extension or period)
    cAlias    = ''
    nRecCount = 0
    bDeleteWhenClosed = .T.

    * Total Processing time (secs)
    nOATime   = 0

    * Custom Method List:
    *- CreateTable() - Create our temporary table
    *- AddLINESSummary() - Sum LINES' calling procs/functions to SUMMARY.DBF

    * Method Code:

    *- CreateTable() - Create our temporary table
    FUNCTION CreateTable(oLINES, oForm)
        LOCAL cFile

        * Create our table
        SELECT 0
        cFile = THIS.cDBFDir + THIS.cDBFName
        CREATE TABLE (cFile) (FILE C(80), ;
          PROCEDURE C(35), ;
          CLASS C(15), ;
          STACK_LVL I, ;
          TOT_SECS N(9,4), ;
          LINENUM I)
        INDEX ON UPPER(FILE + CLASS + PROCEDURE) TAG FILE
        INDEX ON STACK_LVL TAG STACK
        INDEX ON UPPER(CLASS + '.' + PROCEDURE) TAG PROCNAME
        SET ORDER TO FILE
        THIS.cAlias = ALIAS()

        * Sum up LINES' calling procedures/functions into SUMMARY.DBF
        THIS.AddLINESSummary(oLINES, oForm)

        * Return our record count
        RETURN THIS.nRecCount
    ENDFUNC

    *- AddLINESSummary() - Sum LINES' calling procs/functions to SUMMARY.DBF
    FUNCTION AddLINESSummary(oLINES, oForm)
        LOCAL nChecked, nAdded, M.EXEC_TIME, M.CLASS, M.PROCEDURE, M.LINE, ;
          M.FILE, M.STACK_LVL, cMsg

        * Go thru each record in LINES adding times to SUMMARY
        oLINES.Select()
        STORE 0 TO nChecked, nAdded
        cMsg = '    Records Checked: 0, Added: 0'
        oForm.DisplayMsg(cMsg, .T.)
        SCAN
            nChecked = nChecked + 1
            SCATTER MEMVAR
            THIS.Select()
            SEEK UPPER(M.CLASS + M.PROCEDURE + M.FILE)
            IF FOUND()
                REPLACE TOT_SECS WITH TOT_SECS + ROUNDOFF(LINES.TOT_SECS, 4)
            ELSE
                M.TOT_SECS = ROUNDOFF(M.TOT_SECS, 4)
                M.LINENUM = M.LINE
                INSERT INTO SUMMARY FROM MEMVAR
                nAdded = nAdded + 1
            ENDIF
            cMsg = '    Records Checked: ' + TRANSFORM(nChecked) + ;
              ', Added: ' + TRANSFORM(nAdded)
            oForm.ChgLastLine(cMsg)
            oLINES.Select()
        ENDSCAN

        * Set our record count
        THIS.Select()

        * Calculate the overall time
        SET ORDER TO STACK
        GO TOP
        nLvl = STACK_LVL
        nOATime = 0
        SCAN WHILE STACK_LVL = nLvl
            nOATime = nOATime + TOT_SECS
        ENDSCAN
        nOATime = ROUNDOFF(nOATime, 4)
        SET ORDER TO FILE
        THIS.nOATime = nOATime

        * Set our record count and return
        THIS.nRecCount = RECCOUNT()
        RETURN THIS.nRecCount
    ENDFUNC
ENDDEFINE

* CALLS Class Definition - CALLS.DBF Data File Class (base: Custom)
DEFINE CLASS CALLS AS TempTabl

    * This file extracts from LOG.DBF which routines call other routines. That
    *   can readily be determined when PROCEDURE+CLASS changes and the STACK_LVL
    *   is increased.

    * Standard Properties
    Name = 'CALLS'

    * Custom Properties:
    cDBFDir   = ''              && Directory for DBF
    cDBFName  = 'CALLS'       && The DBF name (no extension or period)
    cAlias    = ''
    nRecCount = 0
    bDeleteWhenClosed = .T.

    * Custom Method List:
    *- CreateTable() - Create our temporary table
    *- GetLinkName() - Return an appropriate procedure name
    *- GetLinkInfo() - Return the link name and any backlinks
    *- GetProcsCaps() - Return the proc/method name as capitalized in the code
    *- AddCodeLinks() - Insert links into the passed procedure's code
    *- HandleInitLinks() - Insert Init() links into the passed procedure's code
    *- AddLOGCalls() - Sum LOG' calling procs/functions to SUMMARY.DBF
    *- HandleFormInits() - Create call links, as needed, for a form's components
    *- AddLink() - Add a caller/target link if it doesn't already exist

    * Method Code:

    *- CreateTable() - Create our temporary table
    FUNCTION CreateTable(oLOG, oForm)
        LOCAL cFile

        * Create our table
        SELECT 0
        cFile = THIS.cDBFDir + THIS.cDBFName
        CREATE TABLE (cFile) (CALLER C(35), ;
          CALLERLINK C(40), ;
          TARGET C(35), ;
          TARGETLINK C(40))
        INDEX ON UPPER(CALLER + TARGET) TAG CALLER
        INDEX ON UPPER(TARGET + CALLER) TAG TARGET
        SET ORDER TO CALLER

        * Add all of LOG' calls into our fields
        THIS.AddLOGCalls(oLOG, oForm)

        * Return our record count
        RETURN THIS.nRecCount
    ENDFUNC

    *- GetLinkName() - Return an appropriate procedure name
    FUNCTION GetLinkName(cFile, cProc)
        LOCAL cRetName

        * Load variables from fields if they weren't passed
        IF PCOUNT() = 0
            cFile  = TRIM(FILE)
            cProc  = TRIM(PROCEDURE)
        ELSE
            cFile  = TRIM(cFile)
            cProc  = TRIM(cProc)
        ENDIF

        * We're to return an appropriate procedure name using the following:
        *   1. Bare PRG code not within a function or class: <prgStem>_Code using
        *       FILE name.
        *   2. Functions: <funcName> using PROCEDURE
        *   3. Methods (requires CLASS value): <class.methodName> using PROCEDURE
        DO CASE
        CASE '.' $ cProc                    && class.methodName
            cRetName = STRTRAN(cProc, '.', '_')
        CASE cProc == JUSTSTEM(cFile)       && Bare PRG code
            cRetName = cProc + '_Code'
        OTHERWISE                           && Function
            cRetName = cProc
        ENDCASE
        RETURN cRetName
    ENDFUNC

    *- GetLinkInfo() - Return the link name and any backlinks
    FUNCTION GetLinkInfo(cProc, cBkLinks)
        LOCAL cLookFor, cRetName

        * Select ourselves
        THIS.PushState()

        *   Find our link name as either a caller or a target
        SET ORDER TO CALLER     && Key: UPPER(CALLER + TARGET)
        cLookFor = UPPER(cProc)
        SEEK cLookFor
        IF FOUND()
            cRetName = TRIM(CALLERLINK)
        ELSE
            SET ORDER TO TARGET     && Key: UPPER(TARGET + CALLER)
            SEEK cLookFor
            cRetName = TRIM(TARGETLINK)
        ENDIF

        * Now, find all of the links that call this one
        cBkLinks = ''
        SET ORDER TO TARGET     && Key: UPPER(TARGET + CALLER)
        SEEK cLookFor
        SCAN WHILE UPPER(TARGET) = cLookFor
            cBkLinks = cBkLinks + TRIM(CALLERLINK)+ ','
        ENDSCAN

        * Done
        THIS.PopState()
        RETURN cRetName
    ENDFUNC

    *- GetProcsCaps() - Return the proc/method name as capitalized in the code
    FUNCTION GetProcsCaps(cProc, cCodeText)
        LOCAL cSeek, cRetValue, nPosn

        * Select ourselves
        THIS.PushState()

        * We're passed the full procedure that could be class.proc or just proc,
        *   we're to return just the proc part but capitalized the way it is in
        *   the code. That would only be in the code that calls this procedure,
        *   e.g. areas where we're the target.
        SET ORDER TO TARGET     && Key: UPPER(TARGET + CALLER)
        cRetValue = cProc
        IF '.' $ cProc          && Toss the class name; that's not in the code
            cSeek = '.' + UPPER(cRetValue)
            cRetValue = goStr.MakeProper( JUSTEXT(cProc) )
        ELSE
            cSeek = UPPER(cProc)
            cRetValue = goStr.MakeProper(cProc)
        ENDIF

        * Now, look thru all callers until we find it; first one will do.
        SEEK cSeek
        SCAN WHILE UPPER(TARGET) = cSeek
            nPosn = AT(cSeek, UPPER(cCodeText))
            IF nPosn > 0
                cRetValue = SUBSTR(cCodeText, nPosn, LEN(cSeek))
                IF cRetValue = '.'
                    cRetValue = SUBSTR(cRetValue, 2)
                ENDIF
                EXIT
            ENDIF
        ENDSCAN

        * Done
        THIS.PopState()
        RETURN cRetValue
    ENDFUNC

    *- AddCodeLinks() - Insert links into the passed procedure's code
    FUNCTION AddCodeLinks(cProcedure, cCodeText)
        LOCAL cRetText, cProc, bGotInits, bInClass, cLookFor, nFndStr, ;
          nPosn, cPreface, cTarget, cTargetLink, cLink

        * Select ourselves
        THIS.PushState()
        SET ORDER TO CALLER     && Key: UPPER(CALLER + TARGET)

        * The passed code MAY call other code chunks. Our goal is to find the
        *   call and make that a link
        cRetText = ''
        cProc = ALLTRIM(cProcedure)
        bGotInits = .F.
        bInClass = .F.
        cLookFor = UPPER(cProc)
        SEEK cLookFor
        IF FOUND()
            cRetText = cCodeText

            * If we're dealing with methods, extract up to and including the
            *   FUNC/PROC line
            bInClass = '.' $ CALLER
            IF bInClass
                nFndStr = ''
                nPosn = goStr.FirstAt('PROC,FUNC', cRetText, @nFndStr)
                cPreface = LEFT(cRetText, nPosn-1)
                cRetText = SUBSTR(cRetText, nPosn)
                nPosn = AT(LF, cRetText)
                cPreface = cPreface + LEFT(cRetText, nPosn)
                cRetText = SUBSTR(cRetText, nPosn+1)
            ENDIF
            SCAN WHILE UPPER(CALLER) = cLookFor
                cTarget = TRIM(TARGET)
                IF '.init' $ cTarget
                    bGotInits = .T.
                    LOOP
                ENDIF
                cTargetLink = TRIM(TARGETLINK)

                * What kind of chunk is calling cProc?
                IF '.' $ cTarget

                    * Keep the original capitalization
                    cTarget = JUSTEXT(cTarget)

                    * Find the target (could be DODEFAULT)
                    nPosn = AT(UPPER(cTarget), UPPER(cRetText))
                    IF nPosn = 0 AND JUSTEXT(CALLER) = JUSTEXT(TARGET)
                        cTarget = 'DODEFAULT'
                        nPosn = AT(cTarget, UPPER(cRetText))
                    ENDIF
                    IF nPosn > 0

                        * Capitalize cTarget as it is in the code text
                        cTarget = SUBSTR(cRetText, nPosn, LEN(cTarget))

                        * Our link will look like:
                        *   <a href="#[ccTargetLink]">[ccTarget]</a>
                        cLink = '<a href="#' + cTargetLink + '">' + cTarget + ;
                          '</a>'

                        * ...but doubling up on links never helps
                        IF cTarget = 'DODEFAULT' OR ;
                          NOT '_' + UPPER(cTarget) $ UPPER(cRetText)
                            cRetText = goStr.SwapPhrase(cRetText, cTarget, cLink)
                        ENDIF
                   ENDIF
                ELSE
                    nPosn = AT(UPPER(cTarget), UPPER(cRetText))
                    IF nPosn > 0 AND NOT cTarget $ cCodeText
                        cTarget = SUBSTR(cRetText, nPosn, LEN(cTarget))

                        * This is the same but without the period
                        cLink = '<a href="#' + cTargetLink + '">' + cTarget + '</a>'
                        cRetText = goStr.SwapPhrase(cRetText, cTarget, cLink)
                    ENDIF
                ENDIF

                * Next target
            ENDSCAN
        ENDIF

        * If we found any Init() calls, go deal with them
        IF bGotInits
            cRetText = THIS.HandleInitLinks(cLookfor, cRetText)
        ENDIF

        * Put the preface back in if needed and we're done
        IF bInClass
            cRetText = cPreface + cRetText
        ENDIF
        THIS.PopState()
        RETURN cRetText
    ENDFUNC

    *- HandleInitLinks() - Insert Init() links into the passed procedure's code
    FUNCTION HandleInitLinks(cCaller, cTextIn)
        LOCAL oInits, cTextOut, nRow, cTarget, cTargetLink, cClass, nPosn, ;
          cLink

        * Create an array object of all Init calls as:
        *   .aRA[x,1] - Target
        *   .aRA[x,2] - Target link
        oInits = CREATEOBJECT('ArrayObj', 2)

        * Load it only with Init calls
        SET FILTER TO '.init' $ TARGET
        SEEK cCaller
        SCAN WHILE UPPER(CALLER) = cCaller
            oInits.AddRow(TRIM(TARGET), TRIM(TARGETLINK))
        ENDSCAN
        SET FILTER TO

        * Now, going from bottom up (as we may delete rows), try to load links
        *   for each Init() called with CREATEOBJECT, NEWOBJECT or ADDOBJECT or
        *   their variants.
        cTextOut = cTextIn
        WITH oInits
            FOR nRow = .nRows TO 1 STEP -1
                cTarget = .aRA[nRow,1]
                cTargetLink = .aRA[nRow,2]
                cClass = JUSTSTEM(cTarget)

                * Is this class specifically in the code? It must be prefaced
                *   with a left parenthesis
                cFindExpr = [("] + UPPER(cClass) + [",] + ;
                  [('] + UPPER(cClass) + [']
                cFndStr = ''
                nPosn = goStr.FirstAt(cFindExpr, UPPER(cTextOut), @cFndStr)
                IF nPosn > 0

                    * Keep the original capitalization
                    cClass = SUBSTR(cTextOut, nPosn, LEN(cClass) + 3)

                    * Our link will look like:
                    *   <a href="#[ccTargetLink]">[ccTarget]</a>
                    cLink = '<a href="#' + cTargetLink + '">' + cClass + ;
                      '</a>'
                    cTextOut = goStr.SwapPhrase(cTextOut, cClass, cLink)

                    * Toss this row
                    .DeleteRow(nRow)
                ENDIF
            ENDFOR

            * Here, if we have anything left in oInits, it is either a
            *   DODEFAULT() or an indeterminate class.
            IF .nRows > 0 AND '.INIT' $ cCaller
                nPosn = AT('DODE', UPPER(cTextOut))
                IF nPosn > 0
                    cClass = goStr.GetNextWord(SUBSTR(cTextOut, nPosn))
                    cClass = SUBSTR(cTextOut, nPosn, LEN(cClass))
                    cLink = '<a href="#' + cTargetLink + '">' + cClass + ;
                      '</a>'
                    cTextOut = goStr.SwapPhrase(cTextOut, cClass, cLink)
                ENDIF
            ENDIF
        ENDWITH

        * Done
        RETURN cTextOut
    ENDFUNC

    *- AddLOGCalls() - Sum LOG' calling procs/functions to SUMMARY.DBF
    FUNCTION AddLOGCalls(oLOG, oForm)
        LOCAL cAlias, cTag, M.CALLER, cCallFile, nCallLvl, nChecked, nAdded, ;
          M.TARGET, cTargFile, M.CALLERLINK, M.TARGETLINK, cMsg

        * We want LOG.DBF to be in loading order
        cAlias = THIS.cAlias
        SET ORDER TO CALLER
        oLOG.Select()
        cTag = TAG()
        SET ORDER TO 0

        * Here we want to know who called whom; e.g. CALLER called TARGET. This
        *   is readily determined when PROCEDURE + CLASS changes in LOG.DBF and
        *   the STACK_LVL is increased. We'll ignore all stack level decreases
        *   and all instances where we've already recorded the call.
        cMsg = '    Records Checked: 0, Added: 0'
        oForm.DisplayMsg(cMsg, .T.)
        GO TOP
        M.CALLER = PROCEDURE
        cCallFile = FILE
        nCallLvl = STACK_LVL
        STORE 0 TO nChecked, nAdded
        SCAN
            nChecked = nChecked + 1
            IF PROCEDURE <> M.CALLER
                IF STACK_LVL > nCallLvl
                    M.TARGET = PROCEDURE
                    cTargFile = FILE
                    SELECT (cAlias)
                    SEEK UPPER(M.CALLER + M.TARGET)
                    IF NOT FOUND()
                        M.CALLERLINK = THIS.GetLinkName(cCallFile, TRIM(M.CALLER))
                        M.TARGETLINK = THIS.GetLinkName(cTargFile, TRIM(M.TARGET))
                        INSERT INTO (cAlias) FROM MEMVAR
                        nAdded = nAdded + 1

                        * If we just added a form's Load() method, there won't be
                        *   a call to the form's Init(). So, we'll add it
                        *   manually.
                        IF RIGHT(TRIM(M.TARGET), 4) = 'load'
                            nAdded = THIS.HandleFormInits(oLOG, TRIM(M.TARGET), ;
                              TRIM(M.TARGETLINK), nAdded)
                        ENDIF
                    ENDIF
                    M.TARGET = ''
                    oLOG.Select()
                ENDIF
                M.CALLER = PROCEDURE
                cCallFile = FILE
                nCallLvl = STACK_LVL
            ENDIF
            cMsg = '    Records Checked: ' + TRANSFORM(nChecked) + ;
              ', Added: ' + TRANSFORM(nAdded)
            oForm.ChgLastLine(cMsg)
        ENDSCAN

        * Set our record count and return
        THIS.Select()
        THIS.nRecCount = RECCOUNT()
        RETURN THIS.nRecCount
    ENDFUNC

    *- HandleFormInits() - Create call links, as needed, for a form's components
    FUNCTION HandleFormInits(oLOG, cLoadTarg, cLoadTargLink, nAddCnt)
        LOCAL cFile, nStartStack, nAdd, cCaller, cCallerLink, cTarget, nStack, ;
          cTargetLink, oInits, nX, nY, cCall, cCallLnk

        * First, we need the file name
        cFile = TRIM( EVALUATE(oLOG.cAlias + '.FILE'))
        nStartStack = EVALUATE(oLOG.cAlias + '.STACK_LVL')

        * We need a link to look like Load() called the form's Init()
        nAdd = nAddCnt
        cCaller = cLoadTarg
        cCallerLink = cLoadTargLink
        cTarget = STRTRAN(cLoadTarg, 'load', 'init')
        cTargetLink = STRTRAN(cLoadTargLink, 'load', 'init')
        IF THIS.AddLink(cCaller, cCallerLink, cTarget, cTargetLink)
            nAdd = nAdd + 1
        ENDIF

        * Now, get a unique list of Init()s from oLOG from appform.load to
        *   appform.init as:
        *   .aRA[x,1] - TRIM(PROCEDURE)
        *   .aRA[x,2] - STACK_LVL I(4)
        oInits = oLOG.GetLoadInits(TRIM(cCaller), TRIM(cTarget))
        WITH oInits
            FOR nX = 1 TO oInits.nRows
                cTarget = oInits.aRA[nX,1]
                nStack  = oInits.aRA[nX,2]
                cTargetLink = THIS.GetLinkName(cFile, cTarget)

                * These are also called from the form's Load() if we have the same
                *   stack. Otherwise, the caller is the next stack level up
                IF nStack = nStartStack
                    IF THIS.AddLink(cCaller, cCallerLink, cTarget, cTargetLink)
                        nAdd = nAdd + 1
                    ENDIF
                ELSE

                    * Find the caller
                    FOR nY = nX-1 TO 1 STEP -1
                        IF oInits.aRA[nY,2] = nStack -1
                            cCall = oInits.aRA[nY,1]
                            cCallLnk = THIS.GetLinkName(cFile, cCall)
                            EXIT
                        ENDIF
                    ENDFOR

                    * Now, add the link
                    IF THIS.AddLink(cCall, cCallLnk, cTarget, cTargetLink)
                        nAdd = nAdd + 1
                    ENDIF
                ENDIF   && nStack = nStartStack
            ENDFOR
        ENDWITH

        * Done
        RETURN nAdd
    ENDFUNC

    *- AddLink() - Add a caller/target link if it doesn't already exist
    FUNCTION AddLink(cCaller, cCallLink, cTarget, cTargLine)
        LOCAL cCaller, cTarget, bAdded

        * Save our state
        THIS.PushState()
        SET ORDER TO CALLER         && UPPER(CALLER+TARGET)

        * The desired link may already exist
        cCaller = goStr.MakeLen(cCaller, LEN(CALLER))
        cTarget = goStr.MakeLen(cTarget, LEN(TARGET))
        SEEK cCaller + cTarget
        bAdded = .F.
        IF NOT FOUND()
            INSERT INTO (THIS.cAlias) ;
              (CALLER, CALLERLINK, TARGET, TARGETLINK) ;
              VALUES (cCaller, cCallLink, cTarget, cTargLine)
                bAdded = .T.
        ENDIF

        * Clean up and we're done
        THIS.PopState()
        RETURN bAdded
    ENDFUNC
ENDDEFINE

* LINES Class Definition - LINES.DBF Data File Class (base: Custom)
DEFINE CLASS LINES AS TempTabl

    * This file summarizes unique lines from the LOG table

    * Standard Properties
    Name = 'LINES'

    * Custom Properties:
    cDBFDir   = ''              && Directory for DBF
    cDBFName  = 'LINES'           && The DBF name (no extension or period)
    cAlias    = ''
    nRecCount = 0
    bDeleteWhenClosed = .T.

    * Custom Method List:
    *- CreateTable() - Create our temporary table
    *- AddLogLines() - Add unique log lines to our file and sum quantities

    * Method Code:

    *- CreateTable() - Create our temporary table
    FUNCTION CreateTable(oLOG, oForm)
        LOCAL cFile, nDele

        * Create our table
        SELECT 0
        cFile = THIS.cDBFDir + THIS.cDBFName
        CREATE TABLE (cFile) (CLASS C(15), ;
          PROCEDURE C(35), ;
          FILE C(80), ;
          LINE I, ;
          USES I, ;
          TOT_SECS N(10,6), ;
          STACK_LVL I)
        INDEX ON UPPER(CLASS + PROCEDURE + FILE) + STR(LINE,5,0) TAG CLASS
        INDEX ON UPPER(FILE) + STR(LINE,5,0) TAG FILELINE
        SET ORDER TO CLASS
        THIS.cAlias = ALIAS()

        * Add the log lines to the file
        THIS.AddLogLines(oLOG, oForm)

        * Return our record count
        RETURN THIS.nRecCount
    ENDFUNC

    *- AddLogLines() - Add unique log lines to our file and sum quantities
    FUNCTION AddLogLines(oLOG, oForm)
        LOCAL nChecked, nAdded, M.EXEC_TIME, M.CLASS, M.PROCEDURE, M.LINE, ;
          M.FILE, M.STACK_LVL, M.USES, M.TOT_SECS,  cMsg

        * Get all LOG lines adding the unique ones and adding uses and times
        cMsg = '    Records Checked: 0, Added: 0'
        oForm.DisplayMsg(cMsg, .T.)
        oLOG.Select()
        STORE 0 TO nChecked, nAdded
        SCAN
            nChecked = nChecked + 1
            SCATTER MEMVAR
            THIS.Select()
            SEEK UPPER(M.CLASS + M.PROCEDURE + M.FILE) + STR(M.LINE,5,0)
            IF FOUND()
                IF M.STACK_LVL < STACK_LVL
                    REPLACE STACK_LVL WITH M.STACK_LVL
                ENDIF
                REPLACE USES WITH USES + 1,TOT_SECS WITH TOT_SECS + M.EXEC_TIME
            ELSE
                M.USES = 1
                M.TOT_SECS = M.EXEC_TIME
                INSERT INTO LINES FROM MEMVAR
                nAdded = nAdded + 1
            ENDIF
            cMsg = '    Records Checked: ' + TRANSFORM(nChecked) + ;
              ', Added: ' + TRANSFORM(nAdded)
            oForm.ChgLastLine(cMsg)
            oLOG.Select()
        ENDSCAN

        * Finally, we could be running an APP or EXE; we need to substitute that
        *   for the project's main file
        THIS.Select()
        SET ORDER TO 0          && APP or EXE will be near the top
        LOCATE FOR JUSTEXT( TRIM(FILE)) $ 'app,exe'
        IF FOUND()
            cMainPrg = LOWER( goProcess.oPROJECT.GetMainPrg() )
            cFile = TRIM(FILE)
            goProcess.oPROJECT.cAppType = UPPER(JUSTEXT(cFile))

            * Change from xyz.APP or .EXE to main.prg
            SET ORDER TO FILELINE       && UPPER(FILE) + STR(LINE,5,0)
            SEEK UPPER(cFile)
            DO WHILE FOUND()
                REPLACE FILE WITH cMainPrg FOR FILE = cFile
                SEEK UPPER(cFile)
            ENDDO
        ELSE
            IF NOT ISNULL(goProcess.oPROJECT)
                goProcess.oPROJECT.cAppType = 'PRG'
            ENDIF
        ENDIF
        SET ORDER TO CLASS

        * Set our record count
        THIS.nRecCount = RECCOUNT()
    ENDFUNC
ENDDEFINE

* LOG Class Definition - LOG.DBF Data File Class (base: Custom)
DEFINE CLASS LOG AS TempTabl

    * This file contains COVERAGE.LOG's text in DBF form

    * Standard Properties
    Name = 'LOG'

    * Custom Properties:
    cDBFDir   = ''              && Directory for DBF
    cDBFName  = 'LOG'           && The DBF name (no extension or period)
    cAlias    = ''
    nRecCount = 0
    bDeleteWhenClosed = .T.

    * First procedure line
    c1stProc = ''

    * Custom Method List:
    *- CreateTable() - Create our temporary table
    *- ImportLog() - Import the log file
    *- GetLoadInits() - Return an array of all Inits between Load and Init

    * Method Code:

    *- CreateTable() - Create our temporary table
    FUNCTION CreateTable(cLogFile)
        LOCAL cFile

        * Create our table
        SELECT 0
        cFile = THIS.cDBFDir + THIS.cDBFName
        CREATE TABLE (cFile) (EXEC_TIME N(10,6), ;
          CLASS C(15), ;
          PROCEDURE C(35), ;
          LINE I, ;
          FILE C(80), ;
          STACK_LVL I)
        THIS.cAlias = ALIAS()

        * Index it if needed
        INDEX ON UPPER(FILE) + STR(LINE,5,0) TAG FILELINE

        * Import the log file
        THIS.ImportLog()

        * Return our record count
        RETURN THIS.nRecCount
    ENDFUNC

    *- ImportLog() - Import the log file
    FUNCTION ImportLog()
        LOCAL cLogFile, nDele

        * Add our log file into it
        cLogFile = goApp.oAppEdit.cLogFile
        SET ORDER TO 0
        APPEND FROM (cLogFile) TYPE DELIMITED

        * Kill uneeded records: empty procs
        DELETE FOR EMPTY(PROCEDURE)
        nDele = _TALLY

        * VCX/SCX files can be put in as vct/sct
        REPLACE FILE WITH STRTRAN(FILE, '.sct', '.scx') FOR '.sct' $ FILE
        REPLACE FILE WITH STRTRAN(FILE, '.vct', '.vcx') FOR '.vct' $ FILE

        * Note the first procedure line
        GO TOP
        THIS.c1stProc = PROCEDURE
        SET ORDER TO FILELINE

        * Set our record count
        THIS.nRecCount = RECCOUNT() - nDele
    ENDFUNC

    *- GetLoadInits() - Return an array of all Inits between Load and Init
    FUNCTION GetLoadInits(cLoadProc, cInitProc)
        LOCAL oRet, cProcList, cProc

        * Save our state
        THIS.PushState()

        * We want this in the same order as the log
        SET ORDER TO 0

        * Create our return array as:
        *   .aRA[x,1] - TRIM(PROCEDURE)
        *   .aRA[x,2] - STACK_LVL I(4)
        oRet = CREATEOBJECT('ArrayObj', 2)

        * Look for the Load() proc
        LOCATE FOR PROCEDURE = cLoadProc + ' '
        IF FOUND()

            * Point past the load
            DO WHILE PROCEDURE = cLoadProc + ' '
                SKIP
            ENDDO

            * Go thru each record adding each Init() procedure until we get to
            *   cInitProc: the form.Init() proc.
            cProcList = ''
            SCAN WHILE PROCEDURE <> cInitProc
                IF '.init' $ PROCEDURE
                    cProc = TRIM(PROCEDURE)
                    IF NOT cProc $ cProcList
                        cProcList = cProcList + cProc + ','
                        oRet.AddRow(cProc, STACK_LVL)
                    ENDIF
                ENDIF
            ENDSCAN
        ENDIF

        * Clean up and we're done
        THIS.PopState()
        RETURN oRet
    ENDFUNC
ENDDEFINE

* PROJECT Class Definition - PROJECT.DBF Data File Class (base: Custom)
DEFINE CLASS PROJECT AS TempTabl

    * This file summarizes unique PROCEDUREs from the LINES table

    * Standard Properties
    Name = 'PROJECT'

    * Custom Properties:
    cDBFDir   = ''              && Directory for DBF
    cDBFName  = 'PROJECT'       && The DBF name (no extension or period)
    cAlias    = ''
    nRecCount = 0
    bDeleteWhenClosed = .F.

    * The first record has the full path to the project; later records have
    *   only relevant paths.
    oProjDir = ''

    * Custom Method List:
    *- Init() - Set ourselves up
    *- GetMainPrg() - Return the main prg for an application (APP or EXE)
    *- GetFullName() - Return the full name of a file

    * Method Code:

    *- Init() - Set ourselves up
    FUNCTION Init(cFileName)
        LOCAL cDir
        cDir = ADDBS( FULLPATH( JUSTPATH(cFileName)))
        IF NOT DODEFAULT(cDir)
            RETURN .F.
        ENDIF
        THIS.cDBFDir = cDir
        THIS.cDBFName = JUSTFNAME(cFileName)
        SELECT 0
        USE (cFileName) ALIAS PROJECT
        THIS.cAlias = ALIAS()
        THIS.nRecCount = RECCOUNT()
        GO TOP
        THIS.oProjDir = ADDBS( JUSTPATH(NAME) )
        RETURN .T.
    ENDFUNC

    *- GetMainPrg() - Return the main prg for an application (APP or EXE)
    FUNCTION GetMainPrg()
        LOCAL nRetName

        * Look in our file for this; only one file has MAINPROG = .T.
        THIS.PushState()
        nRetName = ''
        LOCATE FOR MAINPROG
        IF FOUND()
            nRetName = THIS.cDBFDir + ALLTRIM( STRTRAN(NAME, HEX_0, '') )
        ENDIF

        * Done
        THIS.PopState()
        RETURN nRetName
    ENDFUNC

    *- GetFullName() - Return the full name of a file
    FUNCTION GetFullName(cFile)
        LOCAL cRetName

        * Look for the key
        THIS.PushState()
        cRetName = ''
        LOCATE FOR KEY = UPPER( JUSTSTEM(cFile) )
        IF FOUND()
            cRetName = ALLTRIM( STRTRAN(NAME, HEX_0, '') )
        ELSE
            LOCATE FOR LOWER(cFile) $ NAME
            IF FOUND()
                cRetName = ALLTRIM( STRTRAN(NAME, HEX_0, '') )
            ELSE
                ERROR 'Filename not found: ' + cFile
            ENDIF
        ENDIF
        SELECT (nSeleIn)
        IF NOT ':' $ cRetName
            cRetName = THIS.cDBFDir + cRetName
        ENDIF
        THIS.PopState()
        RETURN LOWER(cRetName)
    ENDFUNC
ENDDEFINE

* TempTabl Class Definition - TEMPTABL.DBF Data File Class (base: Custom)
DEFINE CLASS TempTabl AS ArrayObj

    * Standard Properties
    Name = 'TempTabl'
    DIMENSION aRA[1]
    nRows = 0
    nCols = 1

    * Custom Properties:
    cDBFDir  = ''                   && Directory for DBF
    cDBFName = 'TempTabl'           && The DBF name (no extension or period)
    cAlias   = ''
    bDeleteWhenClosed = .T.
    cAppType = ''                   && PRG, APP, EXE

    * Custom Method List:
    *- Init() - Set ourselves up
    *- Select() - Select this DBF file
    *- CreateTable() - Create our temporary table
    *- Error() - Handle/pass up any errors
    *- PushState() - Push our state onto our stack
    *- PopState() - Pop the last state from our stack
    *- Destroy() - Close ourselves and optionally delete us

    * Method Code:

    *- Init() - Set ourselves up
    FUNCTION Init(cDir)
        IF NOT DODEFAULT(1)
            RETURN .F.
        ENDIF
        THIS.cDBFDir = ADDBS(cDir)
        THIS.cAlias = THIS.cDBFName
        THIS.bDeleteWhenClosed = (NOT goApp.oAppEdit.bKeepTbls)
        RETURN .T.
    ENDFUNC

    *- CreateTable() - Create our temporary table
    FUNCTION CreateTable()
        LOCAL cFile

        * Create our table
*       SELECT 0
*       cFile = THIS.cDBFDir + THIS.cDBFName
*       CREATE TABLE (cFile) (FldName1 Type1(nLen1[,nDec1]), ;
*         FldName2 Type2(nLen2[,nDec2], ...)
*
*       * Index it if needed
*       INDEX ON UPPER(FldName1 + FldName2) TAG Field
    ENDFUNC

    *- Select() - Select this DBF file
    FUNCTION Select()

        * If we're already opened, select ourselves and return quickly
        IF USED(THIS.cAlias)
            SELECT (THIS.cAlias)
        ENDIF
        RETURN
    ENDFUNC

    *- PushState() - Push our state onto our stack
    FUNCTION PushState()
        LOCAL oObj

        * Method Notes:
        *   This will save the state of whatever alias is currently SELECTed,
        *   then SELECT our alias and save its state. PopState() will do the
        *   reverse.
        oObj = goSETs.SaveState(THIS.cAlias)
        THIS.AddRow(oObj)
    ENDFUNC

    *- PopState() - Pop the last state from our stack
    FUNCTION PopState()
        LOCAL nRows, oObj

        * This gets the last row's stuff (last in, first out)
        nRows = THIS.nRows
        oObj = THIS.aRA[nRows]
        THIS.aRA[nRows] = NULL
        THIS.DeleteRow(nRows)
        oObj.Release()
    ENDFUNC

    *- Destroy() - Close ourselves and optionally delete us
    FUNCTION Destroy()
        LOCAL cAlias, cStem
        cAlias = THIS.cAlias
        DO CASE
        CASE (NOT EMPTY(cAlias)) AND USED(cAlias)
            USE IN (cAlias)
        CASE EMPTY(cAlias)
            cAlias = THIS.cDBFName
            USE IN (cAlias)
        ENDCASE

        * Delete our file if we're supposed to
        TRY
            IF THIS.bDeleteWhenClosed
                cStem = THIS.cDBFDir + THIS.cDBFName
                IF FILE(cStem + '.DBF')
                    goFiles.DeleteAllFiles(cStem + '.*')
                ENDIF
            ENDIF
        CATCH
        ENDTRY
    ENDFUNC
ENDDEFINE
