Import-Module PSSQLite;
$sqlitecon=New-SQLiteConnection -DataSource :MEMORY:

function create-SQLiteTable {
[CmdletBinding()] 
param( 
[string]$Name,
[string[]]$intFields,
[string[]]$chrFields,
[string[]]$nbrFields,
[string]$DBFile
)  
$SQLQuery="CREATE TABLE IF NOT EXISTS $name (";
$intFields | ?{$_ -ne $null} | %{$SQLQuery+="$($_) INTEGER,"};
$chrFields | ?{$_ -ne $null} | %{$SQLQuery+="$($_) TEXT,"};
$nbrFields | ?{$_ -ne $null} | %{$SQLQuery+="$($_) NUMERIC,"};
$SQLQuery=$SQLQuery.trim(',');
$SQLQuery+=");";
query-SQLiteTable -SQL $SQLQuery -DBFile $DBFile;
};

function insert-SQLiteTable {
[CmdletBinding()] 
param( 
[string]$Name,
[string[]]$chrFields,
[string[]]$nbrFields,
[string[]]$chrValues,
[string[]]$nbrValues,
[string]$DBFile
)  
$SQLQuery="INSERT INTO $Name (";
$chrFields | ?{$_ -ne $null} | %{$SQLQuery+="$($_),"};
$nbrFields | ?{$_ -ne $null} | %{$SQLQuery+="$($_),"};
$SQLQuery=$SQLQuery.trim(',');
$SQLQuery+=") ";
$SQLQuery+="VALUES (";
$chrValues | ?{$_ -ne $null} | %{$SQLQuery+="'$($_)',"};
$nbrValues | ?{$_ -ne $null} | %{$SQLQuery+="$($_),"};
$SQLQuery=$SQLQuery.trim(',');
$SQLQuery+=");";
query-SQLiteTable -SQL $SQLQuery -DBFile $DBFile;
};

function query-SQLiteTable {
[CmdletBinding()] 
param( 
[string]$SQL,
[string]$DBFile
)  
if($DBFile.length -gt 0){
Invoke-SqliteQuery -DataSource $DBFile -Query $SQL;
}else{
Invoke-SqliteQuery -SQLiteConnection $sqlitecon -Query $SQL;
}
};

Function InsertTo-SQLiteTable
{[CmdletBinding()]
    Param
    ( 
        [Parameter(ValueFromPipeline)] [PSObject] $linhas,
        [String]$Name,
        [string]$DBFile
    )
    BEGIN
    {
      $TableFields=query-SQLiteTable -SQL "pragma table_info($Name);";
    }
    PROCESS
    {
      $infields=($linhas | gm).name;
      $chrFields=($TableFields | ? type -eq 'TEXT' | ? {$infields -contains $_.name}).name;
      $nbrFields=($TableFields | ? type -ne 'TEXT' | ? {$infields -contains $_.name}).name;
      foreach($linha in $linhas){
        $chrValues=$chrFields | %{$linha.($_)};
        $nbrValues=$nbrFields | %{$linha.($_)};
        insert-SQLiteTable -DBFile $DBFile -Name $Name -chrFields $chrFields -chrValues $chrValues -nbrFields $nbrFields -nbrValues $nbrValues
      }
    }
}

function New-SQLiteTable {
[CmdletBinding()] 
param( 
[Parameter(ValueFromPipeline)] [PSObject] $linhas,
[string]$Name,
[string[]]$intFields,
[string[]]$nbrFields,
[string]$DBFile
)  
 PROCESS{
  $infields=($linhas | gm | ? MemberType -like '*Property*').name;
  $chrFields=$infields | ? {$intFields -notcontains $_} | ? {$nbrFields -notcontains $_};
  create-SQLiteTable  -Name $Name -intFields $intFields -chrFields $chrFields -nbrFields $nbrFields -DBFile $DBFile;
  foreach($linha in $linhas){InsertTo-SQLiteTable -linhas $linha -Name $Name -DBFile $DBFile};
 }
};

function Migrate-SQLiteTable {
[CmdletBinding()] 
param(
[switch]$Memory2File,
[switch]$File2Memory, 
[string]$DBFile
)  
  if($Memory2File){
    query-SQLiteTable -SQL "SELECT sql FROM sqlite_master;" | %{query-SQLiteTable -SQL "$($_.sql);" -DBFile $DBFile};
    query-SQLiteTable -SQL "SELECT name FROM sqlite_master;" | %{
      $name=$_.name; query-SQLiteTable -SQL "select * from $name;" | InsertTo-SQLiteTable -Name $Name -DBFile $DBfile;
    }
  }
  if($File2Memory){
    query-SQLiteTable -SQL "SELECT sql FROM sqlite_master;" -DBFile $DBFile | %{query-SQLiteTable -SQL "$($_.sql);"};
    query-SQLiteTable -SQL "SELECT name FROM sqlite_master;" -DBFile $DBfile | %{
      $name=$_.name; query-SQLiteTable -SQL "select * from $name;" -DBFile $DBfile | InsertTo-SQLiteTable -Name $Name;
    }
  }
};

function attach-SQLiteDB {
[CmdletBinding()] 
param(
[string]$Path
)  
  dir $Path | %{query-SQLiteTable -SQL "ATTACH DATABASE '$($_.fullname)' AS $($_.basename);"}
};

function list-SQLiteDB {
[CmdletBinding()] 
param(
[string]$Schema
)  
  if($Schema.length -gt 0){$Schema+='.'};
  query-SQLiteTable -SQL "SELECT * FROM ${Schema}sqlite_master;" | ? type -in ('table','view') | select Name,sql;
};
