' The following function was developed by a colleague of mine: Sam Adams.
' This was used by our site to scrape data from the Word documents by cycling through each one via hyperlinks.

Sub TP_Rev_Build()
Dim TMP_folder As String
' Filter P01A Links and move to new sheet
Sheets("Links").Select
ActiveSheet.ListObjects("Table_Query_from_MS_Access_Database").Range. _
    AutoFilter Field:=2, Criteria1:="P01A"
Range("Table_Query_from_MS_Access_Database[[#Headers],[Testpack]]").Select
Range(Selection, ActiveCell.SpecialCells(xlLastCell)).Select
Selection.Copy
Sheets.Add(After:=Sheets(Sheets.Count)).Name = "P01A_Links"
Selection.PasteSpecial Paste:=xlPasteValues, Operation:=xlNone, SkipBlanks _
    :=False, Transpose:=False
' End L01A links filter & move
TMP_folder = Environ("USERPROFILE") & "\Desktop\TMP\"
                If Dir(TMP_folder, vbDirectory) = "" Then
                    MkDir TMP_folder
                End If
' Create TP_Revion_List sheet and format
Sheets.Add(After:=Sheets(Sheets.Count)).Name = "TP_Revision_List"
Sheets("TP_Revision_List").Select
Range("A1").Value = "Test Pack"
Range("B1").Value = "Type"
Range("C1").Value = "Drawing"
Range("D1").Value = "Revision"
' End Create TP_Revion_List sheet and format
' Get data from files by links
Dim rng As Range, cell As Range
Dim lastRow As Long
Dim docLink As String
Dim wdDoc As Object
Dim wdFileName As Variant
Dim TableNo As Integer 'table number in Word
Dim iRow As Long 'row index in Excel
Dim iCol As Integer 'column index in Excel
Dim isheetRow As Long
Dim isheetCol As Long
Dim rCount As Long
Dim i As Long
isheetRow = 1
isheetCol = 1
lastRow = Worksheets("P01A_Links").UsedRange.Rows.Count
Set rng = Worksheets("P01A_Links").Range("F2:F" & lastRow)
i = 1
rCount = 0
For Each cell In rng
docLink = cell.Value
docLink = Replace(docLink, "?spec=0,2,", "?spec=0,1,")
Dim WinHttpReq As Object
        Set WinHttpReq = CreateObject("Microsoft.XMLHTTP")
        WinHttpReq.Open "GET", docLink, False, "username", "password"
        WinHttpReq.send
        
        If WinHttpReq.Status = 200 Then
            Set oStream = CreateObject("ADODB.Stream")
            oStream.Open
            oStream.Type = 1
            oStream.Write WinHttpReq.responseBody
            oStream.SaveToFile TMP_folder & "temp" & i & ".docx", 2 ' 1 = no overwrite, 2 = overwrite
            oStream.Close
        End If
Set wdDoc = GetObject(TMP_folder & "temp" & i & ".docx") 'open Word file
With wdDoc
With .tables(1)
'copy cell contents from Word table cells to Excel cells
For iRow = 11 To .Rows.Count
For iCol = 2 To .Columns.Count
If i > 1 Then
isheetRow = iRow - 10 + rCount
Else
isheetRow = iRow - 9
End If
isheetCol = iCol
Cells(isheetRow, isheetCol) = WorksheetFunction.Clean(.cell(iRow, iCol).Range.Text)
Cells(isheetRow, 1) = Worksheets("P01A_Links").Range("A" & cell.Row)
Next iCol
Next iRow
End With
End With
rCount = isheetRow
wdDoc.Close
Set wdDoc = Nothing
Kill TMP_folder & "temp" & i & ".docx"
i = i + 1
Next cell
Sheets("TP_Revision_List").Move
ChDir "\\pappfs01\public\TPTracker\backend\data_sources"
Application.DisplayAlerts = False
ActiveWorkbook.SaveAs Filename:= _
"\\pappfs01\public\TPTracker\backend\data_sources\TP_Revision_List.xlsx", FileFormat _
:=xlOpenXMLWorkbook, CreateBackup:=False
Application.DisplayAlerts = True
Workbooks("TP_Revision_List.xlsx").Close SaveChanges:=False
Workbooks("191058E-CT-LG-000005.XLSB").Activate
For Each aSheet In Worksheets

    Select Case aSheet.Name

        Case "P01A_Links", "TP_Revision_List"
            Application.DisplayAlerts = False
            aSheet.Delete
            Application.DisplayAlerts = True

    End Select

Next aSheet
    On Error Resume Next
    Kill TMP_folder & "*.*"    ' delete all files in the folder
    RmDir TMP_folder  ' delete folder
    On Error GoTo 0
Workbooks("191058E-CT-LG-000005.XLSB").Close SaveChanges:=False
End Sub
