function Read-FolderBrowserDialog([string]$Message, [string]$InitialDirectory, [switch]$NoNewFolderButton)
{
    $browseForFolderOptions = 0
    if ($NoNewFolderButton) { $browseForFolderOptions += 512 }
 
    $app = New-Object -ComObject Shell.Application
    $folder = $app.BrowseForFolder(0, $Message, $browseForFolderOptions, $InitialDirectory)
    if ($folder) { $selectedDirectory = $folder.Self.Path } else { $selectedDirectory = '' }
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($app) > $null
    return $selectedDirectory
}

function Read-OpenFileDialog([string]$WindowTitle, [string]$InitialDirectory, [string]$Filter = "All files (*.*)|*.*", [switch]$AllowMultiSelect)
{  
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $WindowTitle
    $openFileDialog.InitialDirectory = $InitialDirectory
    $openFileDialog.Filter = $Filter
    if ($AllowMultiSelect) { $openFileDialog.MultiSelect = $true }
    $openFileDialog.ShowHelp = $true    # Without this line the ShowDialog() function may hang depending on system configuration and running from console vs. ISE.
    $openFileDialog.ShowDialog() > $null
    if ($AllowMultiSelect) { return $openFileDialog.Filenames } else { return $openFileDialog.Filename }
}
$pastaEnt=Read-FolderBrowserDialog -Message "Selecione o caminho da pasta com os arquivos de entrada" -InitialDirectory "\\WSASPRD01V" -NoNewFolderButton;
$pastaSai=Read-FolderBrowserDialog -Message "Selecione o caminho da pasta com os arquivos de saida" -InitialDirectory "\\WSASPRD01V" -NoNewFolderButton;
$arqDePara=Read-OpenFileDialog -WindowTitle "Selecione o caminho para o arquivo De/Para" -InitialDirectory "\\WSASPRD01V" -Filter "csv files (*.csv)|*.csv";
$depara=Get-Content -Path $arqDePara | ConvertFrom-Csv -header "de","para";
$total=(dir $pastaEnt | measure-object).count;
$d = 0 ;
dir $pastaEnt | %{
  $d++;
  Write-Progress -Activity "Processando arquivos" -Status "Processados: $d de $total " -PercentComplete (($d / $total)*100) 
  $nome=$_.name;
  Get-Content -Path $_.fullname | %{
    $linha=[String]$_;
    $depara | %{
      $linha=$linha.replace($_.de,$_.para);
    }; 
    $linha;
  } | Out-File -Encoding ASCII "$pastaSai\$nome";
}
