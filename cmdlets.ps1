function valida-cpf {
[CmdletBinding()] 
param( 
[Parameter()][string]$CPF, 
[Switch]$CalculaVerificador
)
  $valido=$false;
  if ($CPF.length -eq 11){$DV=$CPF.substring(9,2)}else{if(-not $CalculaVerificador){RETURN($valido)}};
  $CPF=$CPF.substring(0,9);
  $soma=0;
  0..8 | %{$n=10-$_;$soma+=[convert]::ToInt32($CPF[$_], 10)*$n};
  $verificador1=11-($soma%11);
  if($verificador1 -gt 9){$verificador1=0};
  $CPF=$CPF+"$verificador1";
  $soma=0;
  0..9 | %{$n=11-$_;$soma+=[convert]::ToInt32($CPF[$_], 10)*$n};
  $verificador2=11-($soma%11);
  if($verificador2 -gt 9){$verificador2=0};
  $verificador="$verificador1$verificador2";
  if($CalculaVerificador){return($verificador)}
  else{
    if($DV -eq $verificador){$valido=$True};
	RETURN($valido)
  }
};

function separa-nome {
[CmdletBinding()] 
param( 
[Parameter()]  
[string]
$Nome, 
[Switch]$First,  
[Switch]$Last,  
[Switch]$FullLast,
[Switch]$FullName
)
$n=0;
$Sobrenome="";
if($First){(Get-Culture).textinfo.totitlecase($Nome.ToLower()).split()[0]};
if($Last){(Get-Culture).textinfo.totitlecase($Nome.ToLower()).split()[-1]};
if($FullName){(Get-Culture).textinfo.totitlecase($Nome.ToLower()).replace(" De "," de ").replace(" Do "," do ").replace(" Dos "," dos ").replace(" Da "," da ").replace(" Das "," das ").replace(" Di "," di ")};
if($FullLast){(Get-Culture).textinfo.totitlecase($Nome.ToLower()).split() | %{$n++; if($n -gt 1){$Sobrenome=$Sobrenome+" "+$_}};$Sobrenome.Trim()};
};

function format-CEP {
[CmdletBinding()] 
param( 
[Parameter()]  
[string]
$Valor
)
$valor=$valor.tostring().Replace(".","").Replace("-","");
$valor.tostring().substring(0,5)+"-"+$valor.tostring().substring(5,3);
};

function envia-htmlEmail {
[CmdletBinding()] 
param( 
[Parameter()][string]$From, 
[Parameter(Position=0, Mandatory=$true)][string[]][ValidateNotNullOrEmpty()]$To, 
[Parameter(Position=1, Mandatory=$true)][string][ValidateNotNullOrEmpty()]$Subject, 
[Parameter(Position=2, Mandatory=$true)][string[]][ValidateNotNullOrEmpty()]$Body, 
[Parameter()][string[]]$attachment,  
[Parameter()][string]$smtpserver  
)
  $BodyStr=$Body | out-string;
  if($attachment.length -gt 0){
    if(test-path $attachment){
      Send-MailMessage -From $From -To $To -Subject $Subject -BodyAsHtml $BodyStr -SmtpServer $smtpserver -Attachments $attachment
    }else{Send-MailMessage -From $From -To $To -Subject $Subject -BodyAsHtml $BodyStr -SmtpServer $smtpserver};
  }else{Send-MailMessage -From $From -To $To -Subject $Subject -BodyAsHtml $BodyStr -SmtpServer $smtpserver}
};

function Run-OracleQuery
{
[CmdletBinding()] 
param( 
[Parameter()]  
[string]
$UserID, 
[Parameter()]  
[string]
$Password, 
[Parameter()]  
[string]
$DataSource, 
[Parameter()]  
[string]
$SQL 
)
 [System.Reflection.Assembly]::LoadWithPartialName("Oracle.DataAccess") | out-null
 [System.Reflection.Assembly]::LoadWithPartialName("System.Data.OracleClient") | out-null
 $connectstring="password=$Password;User ID=$UserID;Data Source=$DataSource;Provider=OraOLEDB.Oracle"; 
 $OLEDBConn = New-Object System.Data.OleDb.OleDbConnection($connectstring);
 $OLEDBConn.open();
 $readcmd = New-Object system.Data.OleDb.OleDbCommand($sql,$OLEDBConn);
 $readcmd.CommandTimeout = '300';
 $da = New-Object system.Data.OleDb.OleDbDataAdapter($readcmd);
 $dt = New-Object system.Data.datatable;
 [void]$da.fill($dt);
 $OLEDBConn.close();
  return $dt;
};  

function converter-senhas {
[CmdletBinding()] 
param( 
[Switch]$Text2Enc,  
[Switch]$Enc2Text,
[Parameter()]  
[string]
$Valor 
)  
if($Text2Enc){$valor | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString};
if($Enc2Text){
$pwsec=$Valor | ConvertTo-SecureString;
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwsec)
[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR);
};
};

function Servico-Remoto {
[CmdletBinding()] 
param( 
[Parameter()] [string] $Servidor, 
[Parameter()] [string] $Servico,
[Switch]$Start,  
[Switch]$Exists,
[Switch]$Stop,  
[Switch]$Status,  
[Switch]$Restart
)
  if ($Status){
    $(Invoke-Command -ComputerName $Servidor -ArgumentList $Servico -ScriptBlock {
      param($Servico)
        Get-Service $Servico;
      });
  };
  if ($Restart){
    $(Invoke-Command -ComputerName $Servidor -ArgumentList $Servico -ScriptBlock {
      param($Servico)
        Get-Service $Servico | Restart-Service;
      });
  };
  if ($Start){
    $(Invoke-Command -ComputerName $Servidor -ArgumentList $Servico -ScriptBlock {
      param($Servico)
        Get-Service $Servico | Start-Service;
      });
  };
  if ($Stop){
    $(Invoke-Command -ComputerName $Servidor -ArgumentList $Servico -ScriptBlock {
      param($Servico)
        Get-Service $Servico | Stop-Service;
      });
  };
  if ($Exists){
    $(Invoke-Command -ComputerName $Servidor -ArgumentList $Servico -ScriptBlock {
      param($Servico)
        if((Get-Service | where{$_.name -eq $Servico} | Measure-Object).Count -eq 0){$False}else{$True};
      });
  };
};

function executa-remoto {
[CmdletBinding()] 
param( 
[Parameter()][string]$Comando,
[Parameter()][string]$Servidor
)
  escreve-log -Texto $Comando -Tipo "COMANDO"; 
  Invoke-command -computername $Servidor {
    param($comando);
    Invoke-Expression $comando;
  } -ArgumentList $comando;
};

function grant-remoto {
[CmdletBinding()] 
param( 
[Parameter()][string]$Servidor,
[Parameter()][string]$User,
[Parameter()][string]$Dir,
[Switch]$Remove,  
[Switch]$L,  
[Switch]$LE,  
[Switch]$LEM  
)
if($L){executa-remoto -Servidor $Servidor -Comando "icacls $Dir /grant`:r `"$User`:(OI)(CI)rx`""};
if($LE){executa-remoto -Servidor $Servidor -Comando "icacls $Dir /grant`:r `"$User`:(OI)(CI)wrx`""};
if($LEM){executa-remoto -Servidor $Servidor -Comando "icacls $Dir /grant`:r `"$User`:(OI)(CI)M`""};   
if($Remove){executa-remoto -Servidor $Servidor -Comando "icacls $Dir /remove`:g $User /T"};
};

function share-remoto {
[CmdletBinding()] 
param( 
[Parameter()][string]$Servidor,
[Parameter()][string]$Compart,
[Parameter()][string]$Dir,
[Parameter()][string]$Cota,
[Parameter()][string]$L,
[Parameter()][string]$LE,
[Parameter()][string]$LEM,
[Switch]$AccessBased,
[Switch]$Remove
)
if($Remove){
  executa-remoto -Servidor $Servidor -Comando "Remove-SmbShare -Name $Compart -Force";
}else{
  $CMD="New-SmbShare -Name $Compart -Path $Dir";
  if($L.length -gt 0){$CMD+=" -ReadAccess $L"};
  if($LE.length -gt 0){$CMD+=" -ChangeAccess $LE"};
  if($LEM.length -gt 0){$CMD+=" -FullAccess $LEM"};
  if($AccessBased){$CMD+=" -FolderEnumerationMode AccessBased"};
  executa-remoto -Servidor $Servidor -Comando $CMD;
  if($Cota.length -gt 0){executa-remoto -Servidor $Servidor -Comando "New-FsrmQuota -Path $Dir -Template `"$Cota`""};
};
};

function Get-ODBC-Data{
   param([string]$query=$(throw 'query is required.'),[string]$DSN)
   $conn = New-Object System.Data.Odbc.OdbcConnection
   $conn.ConnectionString = "DSN=$DSN;"
   $conn.open()
   $cmd = New-object System.Data.Odbc.OdbcCommand($query,$conn)
   $ds = New-Object system.Data.DataSet
   (New-Object system.Data.odbc.odbcDataAdapter($cmd)).fill($ds) | out-null
   $conn.close()
   $ds.Tables[0]
}


function Compare-PSObj {
[CmdletBinding()] 
param(
[Parameter()][PSObject]$Obj1,
[Parameter()][PSObject]$Obj2,
[Parameter()][string]$Campos,
[Switch]$ne
)

$Campos1=($Obj1 | gm | ?{$_.MemberType -match 'Property'}).name;
$Campos2=($Obj2 | gm | ?{$_.MemberType -match 'Property'}).name;
$camposJoin=$Campos1 | ?{$Campos2 -contains $_};
if($Campos.length -eq 0){
  $Campos=([String]($camposJoin | sort)).replace(" ",",")
}
Invoke-Expression "`$Obj1=`$Obj1 | select $Campos";
Invoke-Expression "`$Obj2=`$Obj2 | select $Campos";
if($ne){
  $result=$($Obj1 | Out-String) -ne $($Obj2 | Out-String)
}else{
  $result=$($Obj1 | Out-String) -eq $($Obj2 | Out-String)
}
return($result);
};

function Test-FileLock {
  param ([parameter(Mandatory=$true)][string]$Path)
  $oFile = New-Object System.IO.FileInfo $Path
  if ((Test-Path -Path $Path) -eq $false) {return $false}
  try {
    $oStream=$oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    if ($oStream) {$oStream.Close()}
    $false
  } catch {
    return $true
  }
}

function Test-SqlConnection {
    param(
        [Parameter(Mandatory)]
        [string]$SQLServer,
        [Parameter(Mandatory)]
        [string]$SQLDBName
    )
    $ErrorActionPreference = 'Stop'
    try {
        $connectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True";
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
        $sqlConnection.Open()
        $true
    } catch {
        $false
    } finally {
        $sqlConnection.Close()
    }
}
