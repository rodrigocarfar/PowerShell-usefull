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
<#
        .SYNOPSIS
        Create an SQLite table based on the type fields parameters (integer real or string only).

        .DESCRIPTION
        Create tables on memory or file with only the tree basic types: Integer, Real or String (default).
        You can provide 3 arrays with the field names and a name for the table (required). If you provide  
        a path to a DBFile the table will be created on file, otherwise will be created on memory.

        .PARAMETER Name
        Table name.

        .PARAMETER intFields
        Array with integer type field names.

        .PARAMETER chrFields
        Array with character type field names.

        .PARAMETER nbrFields
        Array with real type field names.

        .PARAMETER DBFile
        Path to a file where the table will be crated.

        .EXAMPLE

        create-SQLiteTable -Name "test" -nbrFields "fieldName1","fieldName2" -intFields "fieldName3" -chrFields "fieldName4";
        Creates a table in memory test with the fields fieldName1,fieldName2,fieldName3 and fieldName4

        .EXAMPLE

        create-SQLiteTable -DBFile 'C:\test.db' -Name "test" -nbrFields "fieldName1","fieldName2" -intFields "fieldName3" -chrFields "fieldName4";
        Creates a table on file test.db with name test and fields fieldName1,fieldName2,fieldName3 and fieldName4

        .NOTES
		Author: Rodrigo Faria
		Github: https://github.com/rodrigocarfar

        .LINK
        https://github.com/rodrigocarfar/PowerShell-usefull/blob/master/sqlite-functions.ps1

#>
};

function insertRow-SQLiteTable {
[CmdletBinding()] 
param( 
[string]$Name,
[string[]]$chrFields,
[string[]]$nbrFields,
[string[]]$chrValues,
[string[]]$nbrValues,
[string]$DBFile
)  
$SQLQuery="INSERT OR REPLACE INTO $Name (";
if($chrFields -ne $null){$chrFields | %{$SQLQuery+="$($_),"}};
if($nbrFields -ne $null){$nbrFields | %{$SQLQuery+="$($_),"}};
$SQLQuery=$SQLQuery.trim(',');
$SQLQuery+=") ";
$SQLQuery+="VALUES (";
if($chrFields -ne $null){$chrValues | %{$SQLQuery+="'$($_)',"}};
if($nbrFields -ne $null){$nbrValues | %{if(([String]$_).replace(',','').replace('.','').trim()  -match "^\d+$"){$SQLQuery+="$($_),"}else{$SQLQuery+="NULL,"}}};
$SQLQuery=$SQLQuery.trim(',');
$SQLQuery+=");";
query-SQLiteTable -SQL $SQLQuery -DBFile $DBFile;
<#
        .SYNOPSIS
        Inserts one row on an existing SQLite table.

        .DESCRIPTION
        Insert records in tables on memory or file with only the two types: Number or String (default).
        You can provide 4 arrays with the field names numeric and character and the values separated 
        by type and the table name (required). If you provide a path to a DBFile the table will be 
        updated on file, otherwise will be updated on memory.

        .PARAMETER Name
        Table name.

        .PARAMETER nbrFields
        Array with numeric type field names.

        .PARAMETER chrFields
        Array with character type field names.

        .PARAMETER nbrValues
        Array with numeric type field values.

        .PARAMETER chrValues
        Array with character type field values.

        .PARAMETER DBFile
        Path to a file where the table will be updated.

        .EXAMPLE

        insertRow-SQLiteTable -Name "test" -nbrFields "fieldName1","fieldName2" -nbrValues 1,2 -chrFields "fieldName4" -chrValues "value for field 4";
        Inserts a row in a table that resides on memory

        .EXAMPLE

        insertRow-SQLiteTable -DBFile 'C:\test.db' -Name "test" -nbrFields "fieldName1","fieldName2" -nbrValues 1,2 -chrFields "fieldName4" -chrValues "value for field 4";
        Inserts a row in a table that resides on file.

        .NOTES
		Author: Rodrigo Faria
		Github: https://github.com/rodrigocarfar

        .LINK
        https://github.com/rodrigocarfar/PowerShell-usefull/blob/master/sqlite-functions.ps1

#>
};

function updateRow-SQLiteTable {
[CmdletBinding()] 
param( 
[string]$Name,
[string[]]$keyFields,
[string[]]$chrFields=$null,
[string[]]$nbrFields=$null,
[string[]]$chrValues=$null,
[string[]]$nbrValues=$null,
[string]$DBFile
)  
$SQLQuery="UPDATE $Name SET ";

if($chrFields -ne $null){
0..($chrFields.Length-1) | %{
 $f=$chrFields[$_];
 $v=$chrValues[$_];
 if($f -notin $keyFields){$SQLQuery+="$f = '$v',"};
};
};

if($nbrFields -ne $null){
0..($nbrFields.Length-1) | %{
 $f=$nbrFields[$_];
 $v=$nbrValues[$_];
 if($v -eq $null){$v='NULL'}
 if($f -notin $keyFields){$SQLQuery+="$f = $v,"};
};
};
$SQLQuery=$SQLQuery.trim(',');

$SQLQuery+=" WHERE ";

if($chrFields -ne $null){
0..($chrFields.Length-1) | %{
 $f=$chrFields[$_];
 $v=$chrValues[$_];
 if($f -in $keyFields){$SQLQuery+="$f = '$v' AND "};
};
};

if($nbrFields -ne $null){
0..($nbrFields.Length-1) | %{
 $f=$nbrFields[$_];
 $v=$nbrValues[$_];
 if($v -eq $null){$v='NULL'}
 if($f -in $keyFields){$SQLQuery+="$f = $v AND "};
};
};
$SQLQuery=$SQLQuery.substring(0,$SQLQuery.LastIndexOf(' AND '));
$SQLQuery+=';'
query-SQLiteTable -SQL $SQLQuery -DBFile $DBFile;
<#
        .SYNOPSIS
        Updates one row on SQLite table based on key variables.

        .DESCRIPTION
        Update an SQLite table based on all matching field names and searching by the key fields listed 

        .PARAMETER Name
        Table name.

        .PARAMETER keyFields
        Array with key field names (must be provided in nbrFields or chrFields).

        .PARAMETER nbrFields
        Array with numeric type field names.

        .PARAMETER chrFields
        Array with character type field names.

        .PARAMETER nbrValues
        Array with numeric type field values.

        .PARAMETER chrValues
        Array with character type field values.

        .PARAMETER DBFile
        Path to a file where the table will be updated.

        .EXAMPLE

        updateRow-SQLiteTable -Name "test" -keyFields "fieldName1" -nbrFields "fieldName1","fieldName2" -nbrValues 1,2 -chrFields "fieldName4" -chrValues "value for field 4";
        Updates a row in a table that resides on memory

        .EXAMPLE

        updateRow-SQLiteTable -DBFile 'C:\test.db' -Name "test" -keyFields "fieldName1" -nbrFileds "fieldName1","fieldName2" -nbrValues 1,2 -chrFields "fieldName4" -chrValues "value for field 4";
        Updates a row in a table that resides on file.

        .NOTES
		Author: Rodrigo Faria
		Github: https://github.com/rodrigocarfar

        .LINK
        https://github.com/rodrigocarfar/PowerShell-usefull/blob/master/sqlite-functions.ps1

#>
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
<#
        .SYNOPSIS
        Query an SQLite table on memory or file

        .DESCRIPTION
        Query SQLite table based on SQL parameter info 

        .PARAMETER Name
        Table name.

        .PARAMETER SQL
        SQLite query

        .PARAMETER DBFile
        Path to a file where the table will be updated.

        .EXAMPLE

        query-SQLiteTable -SQL "select * from test"
        Select all records from test table on memory

        .EXAMPLE

        query-SQLiteTable -DBFile 'C:\test.db' -SQL "select * from test"
        Select all records from test table that resides on file.

        .NOTES
		Author: Rodrigo Faria
		Github: https://github.com/rodrigocarfar

        .LINK
        https://github.com/rodrigocarfar/PowerShell-usefull/blob/master/sqlite-functions.ps1

#>
};

Function insert-SQLiteTable
{[CmdletBinding()]
    Param
    ( 
        [Parameter(ValueFromPipeline)] [PSObject] $linha,
        [String]$Name,
        [string]$DBFile
    )
    BEGIN
    {
      $TableFields=query-SQLiteTable -SQL "pragma table_info($Name);";
      $once=$true;
    }
    PROCESS
    { 
      if($once){
        $infields=($linha | gm | ? MemberType -like '*Property*').name | ? {$_ -ne $null} | ? {$_.length -gt 0};
        $chrFields=($TableFields | ? type -eq 'TEXT' | ? {$infields -contains $_.name}).name;
        $nbrFields=($TableFields | ? type -ne 'TEXT' | ? {$infields -contains $_.name}).name;
        $once=$false;
      }
      $chrValues=$chrFields | %{$linha.($_)};
      $nbrValues=$nbrFields | %{$linha.($_)};
      insertRow-SQLiteTable -DBFile $DBFile -Name $Name -chrFields $chrFields -chrValues $chrValues -nbrFields $nbrFields -nbrValues $nbrValues
    }
<#
        .SYNOPSIS
        Inserts records from pipeline on an existing SQLite table based on matching field names.

        .DESCRIPTION
        Insert records in a table based on a pipeline PSObject, matching property names with fields on SQLite table.

        .PARAMETER Name
        Table name.

        .PARAMETER linha
        Pipeline Object with matching properties on SQLite table columns.

        .PARAMETER DBFile
        Path to a file where the table will be updated.

        .EXAMPLE

        ps | select id,ProcessName | insert-SQLiteTable -Name "t_ps"
        Insert process information into existing t_ps table

        .EXAMPLE

        ps | select id,ProcessName | insert-SQLiteTable -Name "t_ps" -DBFile 'C:\test.db'
        Insert process information into existing t_ps table that resides on file

        .NOTES
		Author: Rodrigo Faria
		Github: https://github.com/rodrigocarfar

        .LINK
        https://github.com/rodrigocarfar/PowerShell-usefull/blob/master/sqlite-functions.ps1

#>
}

Function update-SQLiteTable
{[CmdletBinding()]
    Param
    ( 
        [Parameter(ValueFromPipeline)] [PSObject] $linha,
        [String]$Name,
        [String]$keyFields,
        [string]$DBFile
    )
    BEGIN
    {
      $TableFields=query-SQLiteTable -SQL "pragma table_info($Name);";
      $once=$true;
    }
    PROCESS
    { 
      if($once){
        $infields=($linha | gm | ? MemberType -like '*Property*').name;
        $chrFields=($TableFields | ? type -eq 'TEXT' | ? {$infields -contains $_.name}).name;
        $nbrFields=($TableFields | ? type -ne 'TEXT' | ? {$infields -contains $_.name}).name;
        $once=$false;
      }
      $chrValues=$chrFields | %{$linha.($_)};
      $nbrValues=$nbrFields | %{$linha.($_)};
      updateRow-SQLiteTable -DBFile $DBFile -Name $Name -chrFields $chrFields -chrValues $chrValues -nbrFields $nbrFields -nbrValues $nbrValues -keyFields $keyFields;
    }
<#
        .SYNOPSIS
        Updates records from pipeline on an existing SQLite table based on matching field names with key searching.

        .DESCRIPTION
        The updates are received from pipeline and the key fields information is used to select records.
        All fields from PSObject with the same name are updated in the respective table columns.

        .PARAMETER Name
        Table name.

        .PARAMETER KeyFields
        Array with the key fields names used in the where clause.

        .PARAMETER DBFile
        Path to a file where the table will be updated.

        .EXAMPLE

        ps | select id,ProcessName | update-SQLiteTable -Name "t_ps" -keyFields id
        Update ProcessName by the id information 

        .EXAMPLE

        ps | select id,ProcessName | update-SQLiteTable -Name "t_ps" -keyFields id -DBFile 'C:\test.db'
        Update ProcessName by the id information of existing t_ps table that resides on file

        .NOTES
		Author: Rodrigo Faria
		Github: https://github.com/rodrigocarfar

        .LINK
        https://github.com/rodrigocarfar/PowerShell-usefull/blob/master/sqlite-functions.ps1

#>
}

function New-SQLiteTable {
[CmdletBinding()] 
param( 
[Parameter(ValueFromPipeline)] [PSObject] $linha,
[string]$Name,
[string[]]$intFields=$null,
[string[]]$nbrFields=$null,
[string]$DBFile
)  
 BEGIN
 {
   $once=$true;
 }
 PROCESS{
  if($once){
    $infields=($linha | gm | ? MemberType -like '*Property*').name | sort -unique;
    $chrFields=$infields | ? {$intFields -notcontains $_} | ? {$nbrFields -notcontains $_};
    create-SQLiteTable -Name $Name -intFields $intFields -chrFields $chrFields -nbrFields $nbrFields -DBFile $DBFile;
    $once=$false;
  }
  $linha | insert-SQLiteTable -Name $Name -DBFile $DBFile;
 }
<#
        .SYNOPSIS
        Creates and insert records on SQLite table (creates if not exists).

        .DESCRIPTION
        The updates are received from pipeline and, if no integer or number fields are listed, all columns
        are created as text

        .PARAMETER Name
        Table name.

        .PARAMETER intFields
        Array with the fields names that should be defined as integer

        .PARAMETER nbrFields
        Array with the fields names that should be defined as real numbers

        .PARAMETER DBFile
        Path to a file where the table will be updated.

        .EXAMPLE

        ps | select id,ProcessName | New-SQLiteTable -Name "t_ps" -intFields id
        Create an SQLite table t_ps with 2 columns: ProcessName (String) and id (integer) and
        inserts records listed from ps command.

        .EXAMPLE

        ps | select id,ProcessName | New-SQLiteTable -Name "t_ps" -intFields id -DBFile 'C:\test.db'
        Create an SQLite table t_ps (that resides on file) with 2 columns: ProcessName (String) and id (integer) and
        inserts records listed from ps command.

        .NOTES
		Author: Rodrigo Faria
		Github: https://github.com/rodrigocarfar

        .LINK
        https://github.com/rodrigocarfar/PowerShell-usefull/blob/master/sqlite-functions.ps1

#>
};

function Migrate-SQLiteDB {
[CmdletBinding()] 
param(
[switch]$Memory2File,
[switch]$File2Memory, 
[string]$DBFile
)  
  if($Memory2File){
    query-SQLiteTable -SQL "SELECT sql FROM sqlite_master;" | %{query-SQLiteTable -SQL "$($_.sql);" -DBFile $DBFile};
    query-SQLiteTable -SQL "SELECT name FROM sqlite_master;" | %{
      $name=$_.name; query-SQLiteTable -SQL "select * from $name;" | insert-SQLiteTable -Name $Name -DBFile $DBfile;
    }
  }
  if($File2Memory){
    query-SQLiteTable -SQL "SELECT sql FROM sqlite_master;" -DBFile $DBFile | %{query-SQLiteTable -SQL "$($_.sql);"};
    query-SQLiteTable -SQL "SELECT name FROM sqlite_master;" -DBFile $DBfile | %{
      $name=$_.name; query-SQLiteTable -SQL "select * from $name;" -DBFile $DBfile | insert-SQLiteTable -Name $Name;
    }
  }
<#
        .SYNOPSIS
        Copy tables from memory to DB File or from DB File to memory.

        .DESCRIPTION
        This command persists memory tables to a file and can recover it backy to memory.

        .PARAMETER Memory2File
        Copy all tables from memory to a file.

        .PARAMETER File2Memory
        Copy all tables from file to memory.

        .PARAMETER DBFile
        Path to a file where the table will be updated.

        .EXAMPLE

        Migrate-SQLiteDB -Memory2File -DBFile 'C:\test.db';
        Persist all tables in memory to a DB File

        .EXAMPLE

        Migrate-SQLiteDB -File2Memory -DBFile 'C:\test.db';
        Recover all tables from file to memory.

        .NOTES
		Author: Rodrigo Faria
		Github: https://github.com/rodrigocarfar

        .LINK
        https://github.com/rodrigocarfar/PowerShell-usefull/blob/master/sqlite-functions.ps1

#>
};

function attach-SQLiteDB {
[CmdletBinding()] 
param(
[string]$Path
)  
  dir $Path | %{query-SQLiteTable -SQL "ATTACH DATABASE '$($_.fullname)' AS $($_.basename);"}
<#
        .SYNOPSIS
        Attach a dbfile using the file base name as schema

        .DESCRIPTION
        You can use a wildcard to attach many databases as you need and all should be referenced 
        as the file basename.

        .PARAMETER Path
        Path or wildcard of the file databases to be attached.

        .EXAMPLE

        attach-SQLiteDB -Path 'C:\test.db';
        Attach test.db as test

        .EXAMPLE

        attach-SQLiteDB -Path 'C:\*.db';
        Attach all files .db from C:\

        .NOTES
		Author: Rodrigo Faria
		Github: https://github.com/rodrigocarfar

        .LINK
        https://github.com/rodrigocarfar/PowerShell-usefull/blob/master/sqlite-functions.ps1

#>
};

function list-SQLiteDB {
[CmdletBinding()] 
param(
[string]$Schema
)  
  if($Schema.length -gt 0){$Schema+='.'};
  query-SQLiteTable -SQL "SELECT * FROM ${Schema}sqlite_master;" | ? type -in ('table','view') | select Name,sql;
<#
        .SYNOPSIS
        List memory or attached database tales

        .DESCRIPTION
        List table names and the sql of existing tables in memory or attached

        .PARAMETER Schema
        Schema of attached database.

        .EXAMPLE

        list-SQLiteDB;
        List tables in memory

        .EXAMPLE

        list-SQLiteDB -Schema teste;
        List tables from test schema

        .NOTES
		Author: Rodrigo Faria
		Github: https://github.com/rodrigocarfar

        .NOTES
		Author: Rodrigo Faria
		Github: https://github.com/rodrigocarfar

        .LINK
        https://github.com/rodrigocarfar/PowerShell-usefull/blob/master/sqlite-functions.ps1

#>
};
