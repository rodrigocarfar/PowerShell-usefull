function read-excelSheets {
[CmdletBinding()] 
param([Parameter()]
[string]$ExcelPath, 
[string[]]$ExcelSheet,
[int]$StartColumn=1,
[int]$StartRow=1
)
  $excel=new-object -com excel.application
  $colunas=" ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  $wb=$excel.workbooks.open($ExcelPath)
  #$excel.visible=$true;
  $shts=$wb.sheets | %{$_.Name};
  if($ExcelSheet.length -gt 0){$shts=$shts | where {$ExcelSheet -contains $_}};
  foreach($sht in $shts){
    $WorkSheet = $wb.sheets.item($sht);
    $WorkSheet.activate();
    $lastRow=$WorkSheet.UsedRange.rows.count;
    $lastColumn=$WorkSheet.UsedRange.Columns.Count;
	"$sht";
    $csv=$StartRow..$lastRow | %{
      $r=[int]$_;  
	  $saida="";
      $StartColumn..$lastColumn | %{
        $c=[int]$_;
		if($c -le 26){$coluna=$colunas[$c]};
		if(($c -gt 26) -and ($c -le 52)) {$c=$c-26;$coluna="A"+$colunas[$c]};
		if(($c -gt 52) -and ($c -le 78)) {$c=$c-52;$coluna="B"+$colunas[$c]};
		if(($c -gt 78) -and ($c -le 104)){$c=$c-26;$coluna="C"+$colunas[$c]};
	    $cel=$worksheet.Range("$coluna$r").Text;
		$cel=$cel.tostring().replace("`r","").replace("`n","").replace(",","");
        $saida+="$cel,";
      };
	  $saida;
    };
  Invoke-Expression "`$global`:$sht=`$csv | ConvertFrom-Csv;";
  };
  $excel.Workbooks.Close()
};
