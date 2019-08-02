Function transpose-array {
  Begin{$resultado=" "};
  Process {
    $_ | %{if($_.trim().length -gt 0){$resultado+=" "+$_.trim()}};
  };
  End{return($resultado.trim())};
};

]function transpose-clipboard
{
 Get-Clipboard | transpose-array | Set-Clipboard
};
function Get-ClipboardText()
{
    Add-Type -AssemblyName System.Windows.Forms;
    $tb = New-Object System.Windows.Forms.TextBox;
    $tb.Multiline = $true;
    $tb.Paste();
    $texto=$tb.Text;
    $texto -split '\n' | %{if ($_.trim().length -gt 0){$_.trim()}};
};
