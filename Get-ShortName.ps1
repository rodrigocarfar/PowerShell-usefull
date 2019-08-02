Function Get-ShortName { 
    <#  
        .Synopsis  
               Retrieves the short name (8.3) for a path or file. Since the file/path name lenght restriction 
            can cause some real grief when iterating through files and folders, especially if moving user  
            profiles, this function will allow you to explicitly get the short path or pass the target object 
            from the exception message in order to try again.  
           .Example  
            Get-ShortName -Path "C:\Windows" 
        .Notes  
            NAME: Get-ShortName 
            AUTHOR: Paul Brown 
            LASTEDIT: 03/31/2016 09:07:23  
            KEYWORDS:  
        .Link  
            https://gallery.technet.microsoft.com/scriptcenter/site/search?f%5B0%5D.Type=User&f%5B0%5D.Value=PaulBrown4  
    #Requires -Version 2.0  
    #> 
    [cmdletbinding()] 
    Param( 
        [Parameter( 
        Mandatory=$true, 
        Position=0, 
        ValueFromPipeline=$true, 
        ValueFromPipelineByPropertyName=$true)] 
        [array]$Path 
    ) 
    If ($(Get-Item $Path).PSIsContainer -eq $true) { 
        $SFSO = New-Object -ComObject Scripting.FileSystemObject 
        $short = $SFSO.GetFolder($($Path)).ShortPath 
    } Else { 
        $SFSO = New-Object -ComObject Scripting.FileSystemObject 
        $short = $SFSO.GetFile($($Path)).ShortPath 
    } 
     
    return $short 
}
